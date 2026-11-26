import 'dart:async';
import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:real_estate/bindings/app_bindings.dart';
import 'package:real_estate/controller/details/details_controller.dart';
import 'package:real_estate/controller/favorites/favorites_controller.dart';
import 'package:real_estate/controller/settings/settings_controller.dart';
import 'package:real_estate/core/class/route_arguments.dart';
import 'package:real_estate/core/class/status_request.dart';
import 'package:real_estate/core/constant/app_keys.dart';
import 'package:real_estate/core/shared/app_asset_image.dart';
import 'package:real_estate/core/shared/ltr_text.dart';
import 'package:real_estate/core/theme/app_palette.dart';
import 'package:real_estate/data/model/review.dart';
import 'package:real_estate/routes.dart';
import 'package:real_estate/view/screen/details_screen.dart';
import 'package:real_estate/view/widget/details/gallery_row.dart';
import 'package:real_estate/view/widget/details/review_tile.dart';

import '../helpers/details_screens.dart';
import '../helpers/home_api.dart';
import '../helpers/test_doubles.dart';
import '../widget/screen_harness.dart';

Future<void> _pumpDetails(
  WidgetTester tester,
  FakeHomeApi api, {
  bool preview = true,
  String locale = 'en',
  Size size = const Size(430, 932),
}) async {
  await setUpScreenDependencies(handler: api.handle);
  await pumpScreen(
    tester,
    page: () => const DetailsScreen(),
    binding: DetailsTestBinding(preview: preview),
    locale: locale,
    size: size,
  );
}

int _requestsTo(FakeHomeApi api, String path) =>
    api.requests.where((Uri u) => u.path == path).length;

/// Scrolls the page (not the photo pager inside it) until [finder] shows.
Future<void> _scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find
          .descendant(
            of: find.byKey(AppKeys.detailsScroll),
            matching: find.byType(Scrollable),
          )
          .first,
    );

Color? _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  setUpAll(initScreenTestEnvironment);
  tearDown(() => Get.reset());

  group('Details content', () {
    testWidgets('shows the facts, tags, gallery and first review', (
      WidgetTester tester,
    ) async {
      await _pumpDetails(tester, detailsApi());
      expect(tester.takeException(), isNull);
      expect(
        find.text('Knoll Saarinen Executive Conference Chair'),
        findsOneWidget,
      );
      expect(find.text('FURNITURE'), findsOneWidget);
      expect(find.text('4.9 (3 reviews)'), findsOneWidget);
      expect(find.text('26 in stock'), findsOneWidget);
      expect(find.text('Weight 10'), findsOneWidget);
      expect(find.text('13.8 × 7.5 × 5.6'), findsOneWidget);
      await _scrollTo(tester, find.text('office chairs'));
      expect(find.text('furniture'), findsOneWidget);
      expect(find.text('office chairs'), findsOneWidget);
      // The first of three photos is the header; two remain for the gallery.
      await _scrollTo(tester, find.byType(GalleryRow));
      expect(
        find.descendant(
          of: find.byType(GalleryRow),
          matching: find.byType(ClipRRect),
        ),
        findsNWidgets(2),
      );
      expect(find.textContaining('+'), findsNothing);
      await _scrollTo(tester, find.byType(ReviewTile));
      expect(find.byType(ReviewTile), findsOneWidget);
      // The reviews header repeats the rating summary.
      expect(find.text('4.9 (3 reviews)'), findsWidgets);
      // No agent or map: the API has neither.
      expect(find.text('Agent'), findsNothing);
      expect(find.text('Location'), findsNothing);
    });

    testWidgets('shows the card copy at once, then the full record', (
      WidgetTester tester,
    ) async {
      final FakeHomeApi api = detailsApi();
      api.holds['/products/14'] = Completer<void>();
      await _pumpDetails(tester, api);
      expect(
        find.text('Knoll Saarinen Executive Conference Chair'),
        findsOneWidget,
      );
      final DetailsController c = Get.find<DetailsController>();
      expect(c.status.value, StatusRequest.loading);
      await _scrollTo(tester, find.byKey(AppKeys.loadingView));
      api.holds['/products/14']!.complete();
      await settleFrames(tester);
      expect(find.byKey(AppKeys.loadingView), findsNothing);
      expect(c.status.value, StatusRequest.success);
      expect(_requestsTo(api, '/products/14'), 1);
    });

    testWidgets('without a preview: spinner, then the listing', (
      WidgetTester tester,
    ) async {
      final FakeHomeApi api = detailsApi();
      api.holds['/products/14'] = Completer<void>();
      await _pumpDetails(tester, api, preview: false);
      expect(find.byKey(AppKeys.loadingView), findsOneWidget);
      expect(find.byKey(AppKeys.detailsBack), findsOneWidget);
      expect(find.byKey(AppKeys.detailsBook), findsNothing);
      api.holds['/products/14']!.complete();
      await settleFrames(tester);
      expect(find.byKey(AppKeys.detailsBook), findsOneWidget);
    });

    testWidgets('a failure without a preview offers a retry', (
      WidgetTester tester,
    ) async {
      final FakeHomeApi api = detailsApi()
        ..responses['/products/14'] = jsonResponse('{}', status: 500);
      await _pumpDetails(tester, api, preview: false);
      expect(
        find.text(
          'Something went wrong on the server. Please try again later.',
        ),
        findsOneWidget,
      );
      api.responses['/products/14'] = jsonResponse(fixtureText('product'));
      await tester.tap(find.byKey(AppKeys.retryButton));
      await settleFrames(tester);
      expect(find.byKey(AppKeys.detailsBook), findsOneWidget);
    });

    testWidgets('a failure with a preview keeps it and offers a retry', (
      WidgetTester tester,
    ) async {
      final FakeHomeApi api = detailsApi()
        ..responses['/products/14'] = jsonResponse('{}', status: 500);
      await _pumpDetails(tester, api);
      expect(find.byKey(AppKeys.detailsBook), findsOneWidget);
      await _scrollTo(tester, find.byKey(AppKeys.retryButton));
      expect(find.text("Some details couldn't be loaded."), findsOneWidget);
    });

    testWidgets('a bare listing hides its empty sections and a broken photo '
        'leaves the placeholder', (WidgetTester tester) async {
      final FakeHomeApi api = detailsApi()
        ..responses['/products/14'] = jsonResponse(
          jsonEncode(<String, Object>{
            'id': 14,
            'title': 'Bare listing',
            'price': 10,
            'thumbnail': 'https://example.test/broken.png',
          }),
        );
      await _pumpDetails(tester, api, preview: false);

      expect(find.text('Bare listing'), findsOneWidget);
      expect(find.byKey(AppKeys.detailsBook), findsOneWidget);
      for (final String header in <String>[
        'Overview',
        'Facilities',
        'Gallery',
      ]) {
        expect(find.text(header), findsNothing);
      }
      expect(find.byType(GalleryRow), findsNothing);
      expect(find.byType(ReviewTile), findsNothing);
      expect(find.byKey(AppKeys.reviewsSeeAll), findsNothing);
      // One photo slot, so no page dots.
      expect(find.byType(AnimatedContainer), findsNothing);
      expect(find.text('0.0 (0 reviews)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opened without valid arguments it says so', (
      WidgetTester tester,
    ) async {
      await setUpScreenDependencies(handler: detailsApi().handle);
      await pumpScreen(
        tester,
        page: () => const DetailsScreen(),
        binding: DetailsBinding(),
      );
      expect(
        find.text("We couldn't find what you're looking for."),
        findsOneWidget,
      );
      expect(find.byKey(AppKeys.retryButton), findsNothing);
    });

    for (final String locale in <String>['en', 'ar']) {
      testWidgets('a long title, many tags and photos fit a small phone '
          '($locale)', (WidgetTester tester) async {
        final FakeHomeApi api = detailsApi()
          ..responses['/products/14'] = jsonResponse(
            jsonEncode(longProductJson()),
          );
        await _pumpDetails(
          tester,
          api,
          locale: locale,
          size: const Size(320, 568),
        );
        expect(tester.takeException(), isNull);
        expect(find.byKey(AppKeys.detailsPager), findsOneWidget);
        // Six photos: one in the header, three shown, two more counted.
        await _scrollTo(tester, find.text('2+'));
        expect(find.text('2+'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Details interactions', () {
    testWidgets('swiping the header moves the active page dot', (
      WidgetTester tester,
    ) async {
      await _pumpDetails(tester, detailsApi());
      final DetailsController c = Get.find<DetailsController>();
      expect(c.photoIndex.value, 0);
      await tester.fling(
        find.byKey(AppKeys.detailsPager),
        const Offset(-400, 0),
        1000,
      );
      await settleFrames(tester);
      expect(c.photoIndex.value, 1);
    });

    testWidgets('a white band covers the status bar once the photo is gone', (
      WidgetTester tester,
    ) async {
      tester.view.padding = const FakeViewPadding(top: 44);
      addTearDown(tester.view.resetPadding);
      await _pumpDetails(tester, detailsApi());
      double opacity() => tester
          .widget<AnimatedOpacity>(find.byKey(AppKeys.detailsStatusBackdrop))
          .opacity;
      expect(opacity(), 0);
      expect(
        tester.getSize(find.byKey(AppKeys.detailsStatusBackdrop)).height,
        44,
      );
      await tester.drag(
        find.byKey(AppKeys.detailsScroll),
        const Offset(0, -700),
      );
      await settleFrames(tester);
      expect(opacity(), 1);
      await tester.drag(
        find.byKey(AppKeys.detailsScroll),
        const Offset(0, 700),
      );
      await settleFrames(tester);
      expect(opacity(), 0);
    });

    testWidgets('empty page dots carry a ring to show on white photos', (
      WidgetTester tester,
    ) async {
      await _pumpDetails(tester, detailsApi());
      final Iterable<BoxDecoration> dots = tester
          .widgetList<AnimatedContainer>(
            find.descendant(
              of: find.byType(DetailsScreen),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .map((AnimatedContainer c) => c.decoration! as BoxDecoration);
      expect(dots, hasLength(3));
      expect(dots.where((BoxDecoration d) => d.border == null), hasLength(1));
      expect(
        dots.first.color,
        AppPalette.original.primary,
        reason: 'the first photo is active',
      );
    });

    testWidgets('See All lists every review in a sheet', (
      WidgetTester tester,
    ) async {
      await _pumpDetails(tester, detailsApi());
      await _scrollTo(tester, find.byKey(AppKeys.reviewsSeeAll));
      await tester.tap(find.byKey(AppKeys.reviewsSeeAll));
      await settleFrames(tester);
      expect(find.byKey(AppKeys.reviewsSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(AppKeys.reviewsSheet),
          matching: find.byType(ReviewTile),
        ),
        findsNWidgets(3),
      );
      await tester.tap(find.byKey(AppKeys.reviewsClose));
      await settleFrames(tester);
      expect(find.byKey(AppKeys.reviewsSheet), findsNothing);
    });

    testWidgets('booking posts a one-item cart and says nothing is saved', (
      WidgetTester tester,
    ) async {
      final FakeHomeApi api = detailsApi();
      Map<String, dynamic>? body;
      api.holds['/carts/add'] = Completer<void>();
      await setUpScreenDependencies(
        handler: (http.Request request) {
          if (request.url.path == '/carts/add') {
            body = jsonDecode(request.body) as Map<String, dynamic>;
          }
          return api.handle(request);
        },
      );
      await pumpScreen(
        tester,
        page: () => const DetailsScreen(),
        binding: DetailsTestBinding(),
      );
      await tester.tap(find.byKey(AppKeys.detailsBook));
      await tester.pump();
      // A second tap while the first is running sends nothing more.
      await tester.tap(find.byKey(AppKeys.detailsBook));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      api.holds['/carts/add']!.complete();
      await settleFrames(tester);
      expect(_requestsTo(api, '/carts/add'), 1);
      expect(body, <String, Object>{
        'userId': 1,
        'products': <Object>[
          <String, Object>{'id': 14, 'quantity': 1},
        ],
      });
      expect(
        find.text(
          'Booking request sent. This is a demo API, so nothing is saved.',
        ),
        findsOneWidget,
      );
      expect(Get.find<DetailsController>().isBooking.value, isFalse);
    });

    testWidgets('a failed booking shows the translated reason', (
      WidgetTester tester,
    ) async {
      final FakeHomeApi api = detailsApi()
        ..responses['/carts/add'] = jsonResponse('{}', status: 503);
      await _pumpDetails(tester, api, locale: 'ar');
      await tester.tap(find.byKey(AppKeys.detailsBook));
      await settleFrames(tester);
      expect(
        find.text('حدث خطأ في الخادم. حاول مرة أخرى لاحقاً.'),
        findsOneWidget,
      );
    });

    testWidgets('the heart saves the listing; share is visibly disabled', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpDetails(tester, detailsApi());
      await tester.tap(find.byKey(AppKeys.favorite(14)));
      await tester.pump();
      expect(Get.find<FavoritesController>().isFavorite(14), isTrue);
      expect(
        tester.getSemantics(find.byKey(AppKeys.detailsShare)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          label: 'Share (not available yet)',
        ),
      );
      handle.dispose();
    });

    testWidgets('back returns to the previous screen', (
      WidgetTester tester,
    ) async {
      await setUpScreenDependencies(handler: detailsApi().handle);
      useSurface(tester, const Size(430, 932));
      await tester.pumpWidget(
        appHarness(
          pages: <GetPage<dynamic>>[
            GetPage<dynamic>(
              name: AppRoute.splash,
              page: () => const Scaffold(body: Text('start')),
            ),
            GetPage<dynamic>(
              name: AppRoute.details,
              page: () => const DetailsScreen(),
              binding: DetailsBinding(),
            ),
          ],
        ),
      );
      await settleFrames(tester);
      Get.toNamed<void>(
        AppRoute.details,
        arguments: ProductArgs(id: 14, preview: fixtureProduct()).toMap(),
      );
      await settleFrames(tester, frames: 12);
      expect(find.byType(DetailsScreen), findsOneWidget);
      await tester.tap(find.byKey(AppKeys.detailsBack));
      await settleFrames(tester, frames: 12);
      expect(find.text('start'), findsOneWidget);
      expect(Get.isRegistered<DetailsController>(), isFalse);
    });
  });

  group('Details in Arabic and other palettes', () {
    testWidgets('mirrors, translates and keeps numbers left to right', (
      WidgetTester tester,
    ) async {
      await _pumpDetails(tester, detailsApi(), locale: 'ar');
      final BuildContext context = tester.element(find.byType(DetailsScreen));
      expect(Directionality.of(context), TextDirection.rtl);
      expect(find.text('متوفر 26'), findsOneWidget);
      expect(find.text('الوزن 10'), findsOneWidget);
      expect(find.text('احجز الآن'), findsOneWidget);
      expect(find.text('السعر'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('13.8 × 7.5 × 5.6'),
          matching: find.byType(LtrText),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.text(r'$499.99'),
          matching: find.byType(LtrText),
        ),
        findsOneWidget,
      );
      final AppAssetImage back = tester.widget<AppAssetImage>(
        find.descendant(
          of: find.byKey(AppKeys.detailsBack),
          matching: find.byType(AppAssetImage),
        ),
      );
      expect(back.matchTextDirection, isTrue);
      // The back button sits at the right edge in Arabic.
      expect(
        tester.getCenter(find.byKey(AppKeys.detailsBack)).dx,
        greaterThan(215),
      );
    });

    for (final PaletteId id in PaletteId.values) {
      testWidgets('renders with the ${id.name} palette', (
        WidgetTester tester,
      ) async {
        await setUpScreenDependencies(handler: detailsApi().handle);
        await Get.find<SettingsController>().changePalette(id);
        await pumpScreen(
          tester,
          page: () => const DetailsScreen(),
          binding: DetailsTestBinding(),
        );
        expect(tester.takeException(), isNull);
        final AppPalette palette = AppPalette.of(id);
        expect(_textColor(tester, r'$499.99'), palette.primaryText);
        expect(_textColor(tester, 'FURNITURE'), palette.primaryText);
      });
    }
  });

  group('ReviewTile dates', () {
    final DateTime now = DateTime(2026, 11, 26, 12);
    final Map<Duration, (String, String)> cases = <Duration, (String, String)>{
      const Duration(seconds: 20): ('Just now', 'الآن'),
      const Duration(minutes: 5): ('5 minutes ago', 'منذ 5 دقائق'),
      const Duration(hours: 2): ('2 hours ago', 'منذ ساعتين'),
      const Duration(days: 6): ('6 days ago', 'منذ 6 أيام'),
      const Duration(days: 1): ('1 day ago', 'منذ يوم'),
      const Duration(days: 75): ('2 months ago', 'منذ شهرين'),
      const Duration(days: 400): ('1 year ago', 'منذ سنة'),
      const Duration(days: -3): ('Just now', 'الآن'),
    };
    for (final String locale in <String>['en', 'ar']) {
      testWidgets('relative dates read naturally ($locale)', (
        WidgetTester tester,
      ) async {
        await setUpScreenDependencies();
        await pumpScreen(
          tester,
          locale: locale,
          page: () => Scaffold(
            body: ListView(
              children: <Widget>[
                for (final Duration age in cases.keys)
                  ReviewTile(
                    now: now,
                    review: Review(
                      rating: 5,
                      comment: '',
                      reviewerName: 'Ann Lee',
                      date: now.subtract(age),
                    ),
                  ),
              ],
            ),
          ),
        );
        for (final (String en, String ar) expected in cases.values) {
          expect(
            find.text(locale == 'en' ? expected.$1 : expected.$2),
            findsWidgets,
          );
        }
        expect(find.text('AL'), findsWidgets);
      });
    }
  });
}
