import 'dart:ui' show PlatformDispatcher;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'bindings/initial_bindings.dart';
import 'controller/settings/settings_controller.dart';
import 'core/config/app_config.dart';
import 'core/localization/app_strings.dart';
import 'core/services/services.dart';
import 'core/theme/app_palette.dart';
import 'core/theme/app_theme.dart';
import 'core/util/app_dimensions.dart';
import 'routes.dart';

const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('ar')];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  assert(AppConfig.isConfigured, AppConfig.misconfigurationMessage);

  await EasyLocalization.ensureInitialized();
  await initialServices();
  InitialBindings().dependencies();

  final Locale startLocale = SettingsController.startLocale(
    Get.find<MyServices>().sharedPreferences,
    PlatformDispatcher.instance.locale,
  );
  Get.locale = startLocale;

  runApp(
    EasyLocalization(
      supportedLocales: supportedLocales,
      path: 'assets/l10n',
      fallbackLocale: const Locale(SettingsController.fallbackLanguageCode),
      startLocale: startLocale,
      // SettingsController owns persistence, so there is one stored value.
      saveLocale: false,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialRoute = AppRoute.splash, this.pages});

  final String initialRoute;

  /// Route table; defaults to [routes]. Tests pass a single page.
  final List<GetPage<dynamic>>? pages;

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = Get.find<SettingsController>();
    // GetMaterialApp prefers Get.locale over its locale argument, so keep it
    // in step with easy_localization, which owns the language.
    Get.locale = context.locale;
    return ScreenUtilInit(
      designSize: const Size(designWidth, designHeight),
      splitScreenMode: true,
      builder: (_, _) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (_) => AppStrings.t(AppStrings.appName),
        locale: context.locale,
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          ...context.localizationDelegates,
          // GetMaterialApp is built on package:flutter/material, while the
          // screens use package:material_ui, whose widgets look up their own
          // localizations and Theme. Both are provided here and in builder.
          // The list includes the Cupertino delegate that material_ui's
          // iOS text selection toolbar needs.
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: context.supportedLocales,
        initialRoute: initialRoute,
        getPages: pages ?? routes,
        builder: (_, Widget? child) => Obx(() {
          final AppPalette palette = settings.currentPalette;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: appSystemUiStyle(palette),
            child: Theme(
              data: buildAppTheme(palette),
              child: ScaffoldMessenger(child: child ?? const SizedBox.shrink()),
            ),
          );
        }),
      ),
    );
  }
}
