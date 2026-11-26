import 'dart:async';
import 'dart:convert';

import 'package:either_dart/either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:real_estate/controller/details/details_controller.dart';
import 'package:real_estate/core/class/crud.dart';
import 'package:real_estate/core/class/route_arguments.dart';
import 'package:real_estate/core/class/status_request.dart';
import 'package:real_estate/core/shared/initials_avatar.dart';
import 'package:real_estate/core/functions/price_formatter.dart';
import 'package:real_estate/data/datasource/remote/booking_remote_data.dart';
import 'package:real_estate/data/model/product.dart';

import '../helpers/details_screens.dart';
import '../helpers/home_api.dart';
import '../helpers/test_doubles.dart';
import '../widget/screen_harness.dart';

Future<DetailsController> _controller(
  FakeHomeApi api, {
  ProductArgs? args,
}) async {
  await setUpScreenDependencies(handler: api.handle);
  return Get.put<DetailsController>(
    DetailsController(args: args ?? const ProductArgs(id: 14)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  group('DetailsController', () {
    test(
      'without valid arguments it reports not found and asks nothing',
      () async {
        await setUpScreenDependencies(handler: detailsApi().handle);
        final DetailsController c = Get.put<DetailsController>(
          DetailsController(),
        );
        expect(c.status.value, StatusRequest.notFoundFailure);
        expect(c.product.value, isNull);
        expect(await c.book(), StatusRequest.none);
        await c.load();
        expect(c.status.value, StatusRequest.notFoundFailure);
      },
    );

    test('shows the preview, then replaces it with the full record', () async {
      final FakeHomeApi api = detailsApi();
      api.holds['/products/14'] = Completer<void>();
      const Product preview = Product(id: 14, title: 'Card copy', price: 1);
      final DetailsController c = await _controller(
        api,
        args: const ProductArgs(id: 14, preview: preview),
      );
      expect(c.product.value, same(preview));
      expect(c.status.value, StatusRequest.loading);
      api.holds['/products/14']!.complete();
      await pumpEventQueue();
      expect(c.status.value, StatusRequest.success);
      expect(
        c.product.value?.title,
        'Knoll Saarinen Executive Conference Chair',
      );
      expect(c.product.value?.reviews, hasLength(3));
    });

    test('a failure keeps the preview and a retry recovers', () async {
      final FakeHomeApi api = detailsApi()
        ..responses['/products/14'] = jsonResponse('{}', status: 500);
      const Product preview = Product(id: 14, title: 'Card copy', price: 1);
      final DetailsController c = await _controller(
        api,
        args: const ProductArgs(id: 14, preview: preview),
      );
      await pumpEventQueue();
      expect(c.status.value, StatusRequest.serverFailure);
      expect(c.product.value, same(preview));

      api.responses['/products/14'] = jsonResponse(fixtureText('product'));
      await c.load();
      expect(c.status.value, StatusRequest.success);
      expect(c.product.value?.stock, 26);
    });

    test(
      'a page index beyond the new photo list goes back to the first',
      () async {
        final FakeHomeApi api = detailsApi();
        api.holds['/products/14'] = Completer<void>();
        final DetailsController c = await _controller(api);
        c.showPhoto(5);
        api.holds['/products/14']!.complete();
        await pumpEventQueue();
        expect(c.photoIndex.value, 0);
        c.showPhoto(2);
        expect(c.photoIndex.value, 2);
      },
    );

    test('booking succeeds once and ignores a second tap meanwhile', () async {
      final FakeHomeApi api = detailsApi();
      api.holds['/carts/add'] = Completer<void>();
      final DetailsController c = await _controller(api);
      await pumpEventQueue();
      final Future<StatusRequest> first = c.book();
      expect(c.isBooking.value, isTrue);
      expect(await c.book(), StatusRequest.none);
      api.holds['/carts/add']!.complete();
      expect(await first, StatusRequest.success);
      expect(c.isBooking.value, isFalse);
      expect(
        api.requests.where((Uri u) => u.path == '/carts/add'),
        hasLength(1),
      );
    });

    test('a booking that throws still frees the button', () async {
      final DetailsController c = await _controller(detailsApi());
      Get
        ..delete<BookingRemoteData>(force: true)
        ..put<BookingRemoteData>(_ThrowingBooking());
      await expectLater(c.book(), throwsStateError);
      expect(c.isBooking.value, isFalse);
    });

    test('a failed booking returns the reason', () async {
      final FakeHomeApi api = detailsApi()
        ..responses['/carts/add'] = jsonResponse('{}', status: 503);
      final DetailsController c = await _controller(api);
      expect(await c.book(), StatusRequest.serverFailure);
      expect(c.isBooking.value, isFalse);
    });

    test('photos: the gallery, else the card image, else one empty slot', () {
      expect(DetailsController.photosOf(fixtureProduct()), hasLength(3));
      expect(
        DetailsController.photosOf(
          const Product(id: 1, title: 't', price: 1, thumbnail: 'x.png'),
        ),
        <String?>['x.png'],
      );
      expect(
        DetailsController.photosOf(const Product(id: 1, title: 't', price: 1)),
        <String?>[null],
      );
    });
  });

  group('BookingRemoteData', () {
    Crud crud(MockClientHandler handler) =>
        Crud(client: MockClient(handler), connectivityCheck: () async => true);

    test('posts one item for the demo user and returns the cart id', () async {
      late http.Request sent;
      final BookingRemoteData data = BookingRemoteData(
        crud((http.Request request) async {
          sent = request;
          return jsonResponse(jsonEncode(<String, Object>{'id': 51}));
        }),
      );
      final Either<StatusRequest, int> result = await data.book(14);
      expect(result.right, 51);
      expect(sent.method, 'POST');
      expect(sent.url.path, '/carts/add');
      expect(sent.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(sent.body), <String, Object>{
        'userId': BookingRemoteData.demoUserId,
        'products': <Object>[
          <String, Object>{'id': 14, 'quantity': 1},
        ],
      });
    });

    test('an answer without an id is unexpected', () async {
      final BookingRemoteData data = BookingRemoteData(
        crud((_) async => jsonResponse('{"total": 1}')),
      );
      expect((await data.book(14)).left, StatusRequest.unexpectedResponse);
    });

    test('offline is reported without a request', () async {
      int calls = 0;
      final BookingRemoteData data = BookingRemoteData(
        Crud(
          client: MockClient((_) async {
            calls++;
            return jsonResponse('{}');
          }),
          connectivityCheck: () async => false,
        ),
      );
      expect((await data.book(14)).left, StatusRequest.offlineFailure);
      expect(calls, 0);
    });
  });

  group('ProductArgs', () {
    test('round-trips through the route map', () {
      final Product product = fixtureProduct();
      final ProductArgs? args = ProductArgs.tryParse(
        ProductArgs(id: 14, preview: product).toMap(),
      );
      expect(args?.id, 14);
      expect(args?.preview, same(product));
    });

    test('rejects anything without a positive integer id', () {
      expect(ProductArgs.tryParse(null), isNull);
      expect(ProductArgs.tryParse('14'), isNull);
      expect(ProductArgs.tryParse(<String, Object>{'id': '14'}), isNull);
      expect(ProductArgs.tryParse(<String, Object>{'id': 0}), isNull);
    });

    test('drops a preview of another listing', () {
      final ProductArgs? args = ProductArgs.tryParse(<String, Object>{
        'id': 7,
        'preview': fixtureProduct(),
      });
      expect(args?.id, 7);
      expect(args?.preview, isNull);
    });
  });

  group('formatters', () {
    test('measures keep at most one decimal', () {
      expect(formatMeasure(10), '10');
      expect(formatMeasure(13.81), '13.8');
      expect(formatMeasure(7.5), '7.5');
      expect(formatMeasure(5.96), '6');
      expect(formatMeasure(double.nan), '');
      expect(formatMeasure(double.infinity), '');
    });

    test('initials take the first letter of up to two words', () {
      expect(InitialsAvatar.initialsOf('John Doe'), 'JD');
      expect(InitialsAvatar.initialsOf('  ava  maria  lee '), 'AM');
      expect(InitialsAvatar.initialsOf('Cher'), 'C');
      expect(InitialsAvatar.initialsOf(''), '');
    });
  });
}

class _ThrowingBooking extends BookingRemoteData {
  _ThrowingBooking() : super(Crud());

  @override
  Future<Either<StatusRequest, int>> book(int productId) async =>
      throw StateError('broken');
}
