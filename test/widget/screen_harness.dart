import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:real_estate/controller/favorites/favorites_controller.dart';
import 'package:real_estate/controller/settings/settings_controller.dart';
import 'package:real_estate/core/class/crud.dart';
import 'package:real_estate/core/services/services.dart';
import 'package:real_estate/data/datasource/remote/products_remote_data.dart';
import 'package:real_estate/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/disk_asset_loader.dart';
import '../helpers/test_doubles.dart';

/// One-time setup per test file. Call from `setUpAll`, not `setUp`:
/// `EasyLocalization.ensureInitialized` is meant to run once per process.
Future<void> initScreenTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();
  CachedNetworkImageProvider.defaultCacheManager = OfflineCacheManager();
  await _loadFont('Rubik', 'assets/fonts/Rubik.ttf');
  await _loadFont('Outfit', 'assets/fonts/Outfit.ttf');
  await _loadFont('Inter', 'assets/fonts/Inter.ttf');
}

/// Real fonts, so text widths (and any overflow) match the device instead
/// of the square test font.
Future<void> _loadFont(String family, String path) async {
  final Uint8List bytes = File(path).readAsBytesSync();
  final FontLoader loader = FontLoader(family)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
}

/// Registers the app dependencies before each test (`setUp`).
///
/// Everything is `permanent: true`: GetX's smart management ties
/// non-permanent instances to the active route and drops them between tests.
Future<void> setUpScreenDependencies({
  MockClientHandler? handler,
  Map<String, Object> prefs = const <String, Object>{},
}) async {
  Get.reset();
  SharedPreferences.setMockInitialValues(prefs);
  await Get.putAsync<MyServices>(() => MyServices().init(), permanent: true);
  final Crud crud = Crud(
    client: MockClient(
      handler ?? (http.Request request) async => jsonResponse('{}'),
    ),
    connectivityCheck: () async => true,
  );
  Get.put<Crud>(crud, permanent: true);
  Get.put<ProductsRemoteData>(ProductsRemoteData(crud), permanent: true);
  Get.put<SettingsController>(SettingsController(), permanent: true);
  Get.put<FavoritesController>(FavoritesController(), permanent: true);
}

/// Sets the test surface to a logical size at density 1.
void useSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// The production widget tree (EasyLocalization > MyApp) with translations
/// read from disk.
Widget appHarness({
  String locale = 'en',
  List<GetPage<dynamic>>? pages,
  String initialRoute = '/',
}) {
  return EasyLocalization(
    path: 'assets/l10n',
    supportedLocales: supportedLocales,
    startLocale: Locale(locale),
    fallbackLocale: const Locale('en'),
    ignorePluralRules: false,
    saveLocale: false,
    assetLoader: const DiskAssetLoader(),
    child: MyApp(initialRoute: initialRoute, pages: pages),
  );
}

/// Pumps one screen through the production tree and settles.
Future<void> pumpScreen(
  WidgetTester tester, {
  required Widget Function() page,
  Bindings? binding,
  String locale = 'en',
  Size size = const Size(430, 932),
}) async {
  useSurface(tester, size);
  await tester.pumpWidget(
    appHarness(
      locale: locale,
      pages: <GetPage<dynamic>>[
        GetPage<dynamic>(name: '/', page: page, binding: binding),
      ],
    ),
  );
  await settleFrames(tester);
}

/// Pumps a fixed number of frames. `pumpAndSettle` hangs on screens with
/// endless animations (spinners).
Future<void> settleFrames(WidgetTester tester, {int frames = 8}) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
