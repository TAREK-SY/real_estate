import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:real_estate/core/class/handling_data_view.dart';
import 'package:real_estate/core/class/status_request.dart';
import 'package:real_estate/core/constant/app_keys.dart';
import 'package:real_estate/core/shared/app_divider.dart';
import 'package:real_estate/core/shared/app_network_image.dart';
import 'package:real_estate/core/shared/ltr_text.dart';
import 'package:real_estate/core/shared/primary_button.dart';
import 'package:real_estate/core/theme/app_palette.dart';

import 'screen_harness.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget Function() body, {
  String locale = 'en',
}) => pumpScreen(
  tester,
  locale: locale,
  page: () => Scaffold(body: body()),
);

void main() {
  setUpAll(initScreenTestEnvironment);
  setUp(setUpScreenDependencies);

  group('HandlingDataView', () {
    testWidgets('shows the child on success', (WidgetTester tester) async {
      await _pump(
        tester,
        () => const HandlingDataView(
          status: StatusRequest.success,
          child: Text('content'),
        ),
      );
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('shows a spinner while loading', (WidgetTester tester) async {
      await _pump(
        tester,
        () => const HandlingDataView(
          status: StatusRequest.loading,
          child: Text('content'),
        ),
      );
      expect(find.byKey(AppKeys.loadingView), findsOneWidget);
      expect(find.text('content'), findsNothing);
    });

    testWidgets('shows the empty message without retry', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        () => HandlingDataView(
          status: StatusRequest.empty,
          onRetry: () {},
          child: const Text('content'),
        ),
      );
      expect(find.text('Nothing to show here yet.'), findsOneWidget);
      expect(find.byKey(AppKeys.retryButton), findsNothing);
    });

    final Map<StatusRequest, String> messages = <StatusRequest, String>{
      StatusRequest.offlineFailure:
          'No internet connection. Check your connection and try again.',
      StatusRequest.timeoutFailure:
          'The server is taking too long to respond. Please try again.',
      StatusRequest.serverFailure:
          'Something went wrong on the server. Please try again later.',
      StatusRequest.unexpectedResponse:
          'We received an unexpected response. Please try again.',
      StatusRequest.failure:
          'The request could not be completed. Please try again.',
    };
    for (final MapEntry<StatusRequest, String>(key: status, value: message)
        in messages.entries) {
      testWidgets('${status.name}: readable message and a working retry', (
        WidgetTester tester,
      ) async {
        int retries = 0;
        await _pump(
          tester,
          () => HandlingDataView(
            status: status,
            onRetry: () => retries++,
            child: const Text('content'),
          ),
        );
        expect(find.text(message), findsOneWidget);
        await tester.tap(find.byKey(AppKeys.retryButton));
        expect(retries, 1);
      });
    }

    testWidgets('not found: message without retry', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        () => HandlingDataView(
          status: StatusRequest.notFoundFailure,
          onRetry: () {},
          child: const Text('content'),
        ),
      );
      expect(
        find.text("We couldn't find what you're looking for."),
        findsOneWidget,
      );
      expect(find.byKey(AppKeys.retryButton), findsNothing);
    });

    testWidgets('messages are translated in Arabic', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        locale: 'ar',
        () => HandlingDataView(
          status: StatusRequest.offlineFailure,
          onRetry: () {},
          child: const Text('content'),
        ),
      );
      expect(
        find.text('لا يوجد اتصال بالإنترنت. تحقّق من الاتصال وحاول مجدداً.'),
        findsOneWidget,
      );
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });
  });

  group('AppNetworkImage', () {
    testWidgets('a failing URL keeps the box size and shows the fallback', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        () => const Center(
          child: AppNetworkImage(
            url: 'https://cdn.test/broken.png',
            width: 159,
            height: 154,
          ),
        ),
      );
      await settleFrames(tester, frames: 12);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(AppNetworkImage)),
        const Size(159, 154),
      );
      expect(find.bySemanticsLabel('Image unavailable'), findsOneWidget);
    });

    testWidgets('a missing URL shows the fallback without a request', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        () => const Center(
          child: AppNetworkImage(url: '  ', width: 100, height: 100),
        ),
      );
      expect(find.bySemanticsLabel('Image unavailable'), findsOneWidget);
      expect(
        tester.getSize(find.byType(AppNetworkImage)),
        const Size(100, 100),
      );
    });
  });

  group('PrimaryButton', () {
    testWidgets('calls back when enabled', (WidgetTester tester) async {
      int taps = 0;
      await _pump(
        tester,
        () => Center(
          child: PrimaryButton(label: 'Set Filter', onPressed: () => taps++),
        ),
      );
      await tester.tap(find.text('Set Filter'));
      expect(taps, 1);
      expect(
        tester.getSize(find.byType(PrimaryButton)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('keeps its own height when the parent allows more', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        () => Center(
          child: PrimaryButton(label: 'Set Filter', onPressed: () {}),
        ),
      );
      expect(
        tester.getSize(find.byType(PrimaryButton)).height,
        lessThan(100),
        reason: 'A loose parent must not stretch the button to its height.',
      );
    });

    testWidgets('announces its label while loading', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        () => const Center(
          child: PrimaryButton(label: 'Book', isLoading: true, onPressed: null),
        ),
      );
      expect(find.bySemanticsLabel('Book'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('looks and acts disabled without a callback', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        () =>
            const Center(child: PrimaryButton(label: 'Book', onPressed: null)),
      );
      final Material material = tester.widget<Material>(
        find.descendant(
          of: find.byType(PrimaryButton),
          matching: find.byType(Material),
        ),
      );
      expect(material.color!.a, lessThan(1));
    });

    testWidgets('shows a spinner and ignores taps while loading', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await _pump(
        tester,
        () => Center(
          child: PrimaryButton(
            label: 'Book',
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(PrimaryButton));
      expect(taps, 0);
    });
  });

  testWidgets('LtrText keeps a price left-to-right inside Arabic', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      locale: 'ar',
      () => const Center(child: LtrText(r'$1,899.99')),
    );
    final BuildContext context = tester.element(find.text(r'$1,899.99'));
    expect(Directionality.of(context), TextDirection.ltr);
  });

  testWidgets('LtrText in a wide Arabic box sits at the start (right) edge', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      locale: 'ar',
      () => const Center(
        child: SizedBox(width: 300, child: LtrText(r'$1,899.99')),
      ),
    );
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.text(r'$1,899.99'),
    );
    final List<TextBox> boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 9),
    );
    expect(
      boxes.first.left,
      greaterThan(150),
      reason: 'In a right-to-left layout the price belongs on the right.',
    );
  });

  testWidgets('LtrText maps an explicit start to the layout start in Arabic', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      locale: 'ar',
      () => const Center(
        child: SizedBox(
          width: 300,
          child: LtrText(r'$1,899.99', textAlign: TextAlign.start),
        ),
      ),
    );
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.text(r'$1,899.99'),
    );
    final List<TextBox> boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 9),
    );
    expect(boxes.first.left, greaterThan(150));
  });

  testWidgets('LtrText keeps a centered alignment in Arabic', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      locale: 'ar',
      () => const Center(
        child: SizedBox(
          width: 300,
          child: LtrText(r'$9', textAlign: TextAlign.center),
        ),
      ),
    );
    expect(
      tester.renderObject<RenderParagraph>(find.text(r'$9')).textAlign,
      TextAlign.center,
    );
  });

  testWidgets('LtrText in a wide English box stays on the left', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      () => const Center(
        child: SizedBox(width: 300, child: LtrText(r'$1,899.99')),
      ),
    );
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.text(r'$1,899.99'),
    );
    final List<TextBox> boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 9),
    );
    expect(boxes.first.left, lessThan(1));
  });

  testWidgets('AppDivider is 1 px in primary at 10%', (
    WidgetTester tester,
  ) async {
    await _pump(tester, () => const Column(children: <Widget>[AppDivider()]));
    final Container line = tester.widget<Container>(
      find.descendant(
        of: find.byType(AppDivider),
        matching: find.byType(Container),
      ),
    );
    expect(line.color, AppPalette.original.primarySoft);
    expect(tester.getSize(find.byType(AppDivider)).height, 1);
  });
}
