import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:real_estate/core/shared/app_asset_image.dart';
import 'package:real_estate/core/theme/app_palette.dart';

import 'screen_harness.dart';

void main() {
  setUpAll(initScreenTestEnvironment);
  setUp(setUpScreenDependencies);

  testWidgets('an .svg path renders with SvgPicture', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      page: () => const Scaffold(
        body: AppAssetImage('assets/images/logo.svg', width: 40, height: 40),
      ),
    );
    final SvgPicture svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(svg.colorFilter, isNull);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('a color tints an svg with srcIn', (WidgetTester tester) async {
    await pumpScreen(
      tester,
      page: () => Scaffold(
        body: AppAssetImage(
          'assets/images/logo.svg',
          color: AppPalette.original.primary,
          semanticLabel: 'logo',
        ),
      ),
    );
    final SvgPicture svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(
      svg.colorFilter,
      ColorFilter.mode(AppPalette.original.primary, BlendMode.srcIn),
    );
    expect(find.bySemanticsLabel('logo'), findsOneWidget);
  });

  testWidgets('other extensions render with Image.asset', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      page: () => const Scaffold(
        body: AppAssetImage(
          'assets/images/missing.png',
          width: 10,
          height: 10,
          matchTextDirection: true,
        ),
      ),
    );
    final Image image = tester.widget<Image>(find.byType(Image));
    expect(image.matchTextDirection, isTrue);
    expect(find.byType(SvgPicture), findsNothing);
    // The missing file is expected here; only the renderer choice matters.
    tester.takeException();
  });
}
