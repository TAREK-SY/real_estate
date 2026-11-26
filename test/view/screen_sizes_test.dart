import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:real_estate/core/constant/app_keys.dart';
import 'package:real_estate/core/middleware/unknown_route_middleware.dart';
import 'package:real_estate/routes.dart';
import 'package:real_estate/view/screen/not_found_screen.dart';
import 'package:real_estate/view/screen/splash_screen.dart';
import 'package:real_estate/view/screen/auth_screen.dart';
import 'package:real_estate/view/screen/details_screen.dart';
import 'package:real_estate/view/screen/main/main_screen.dart';
import 'package:real_estate/bindings/app_bindings.dart';

import '../helpers/details_screens.dart';
import '../helpers/explore_screens.dart';

import '../helpers/screen_sizes.dart';
import '../widget/screen_harness.dart';

/// Every screen of the stage, at every size, in both languages, with the
/// real translated text: no exception and no overflow.
final Map<String, Widget Function()> _screens = <String, Widget Function()>{
  'SplashScreen': () => const SplashScreen(),
  'NotFoundScreen': () => const NotFoundScreen(),
  'AuthScreen': () => const AuthScreen(),
  'MainScreen': () => const MainScreen(),
  for (final String name in exploreScreens.keys) name: () => const MainScreen(),
  'DetailsScreen': () => const DetailsScreen(),
  'ProfileTab': () => const MainScreen(),
};

final Map<String, Bindings> _bindings = <String, Bindings>{
  'AuthScreen': AuthBinding(),
  'MainScreen': MainBinding(),
  for (final MapEntry<String, Bindings Function()>(
        :String key,
        :Bindings Function() value,
      )
      in exploreScreens.entries)
    key: value(),
  'DetailsScreen': DetailsTestBinding(),
  'ProfileTab': ProfileTabBinding(),
};

void main() {
  setUpAll(initScreenTestEnvironment);
  setUp(() => setUpScreenDependencies(handler: detailsApi().handle));

  for (final MapEntry<String, Widget Function()>(key: name, value: page)
      in _screens.entries) {
    for (final MapEntry<String, Size>(key: sizeName, value: size)
        in screenSizes.entries) {
      for (final String locale in testLocales) {
        testWidgets('$name renders on $sizeName ($locale)', (
          WidgetTester tester,
        ) async {
          await pumpScreen(
            tester,
            page: page,
            binding: _bindings[name],
            locale: locale,
            size: size,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  group('NotFoundScreen', () {
    testWidgets('mirrors in Arabic and shows translated text', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        page: () => const NotFoundScreen(),
        locale: 'ar',
      );
      expect(find.text('الصفحة غير موجودة'), findsOneWidget);
      final BuildContext context = tester.element(find.byType(NotFoundScreen));
      expect(Directionality.of(context), TextDirection.rtl);
    });

    testWidgets('the action returns to the start route', (
      WidgetTester tester,
    ) async {
      useSurface(tester, const Size(430, 932));
      await tester.pumpWidget(
        appHarness(
          initialRoute: AppRoute.notFound,
          pages: <GetPage<dynamic>>[
            GetPage<dynamic>(
              name: AppRoute.splash,
              page: () => const Scaffold(body: Text('start')),
            ),
            GetPage<dynamic>(
              name: AppRoute.notFound,
              page: () => const NotFoundScreen(),
            ),
          ],
        ),
      );
      await settleFrames(tester);
      await tester.tap(find.byKey(AppKeys.notFoundAction));
      await settleFrames(tester);
      expect(find.text('start'), findsOneWidget);
      expect(Get.currentRoute, AppRoute.splash);
    });

    testWidgets('an unknown route name lands on the not-found screen', (
      WidgetTester tester,
    ) async {
      useSurface(tester, const Size(430, 932));
      await tester.pumpWidget(
        appHarness(
          pages: <GetPage<dynamic>>[
            GetPage<dynamic>(
              name: AppRoute.splash,
              page: () => const Scaffold(body: Text('start')),
              middlewares: <GetMiddleware>[UnknownRouteMiddleware()],
            ),
            GetPage<dynamic>(
              name: AppRoute.notFound,
              page: () => const NotFoundScreen(),
            ),
          ],
        ),
      );
      await settleFrames(tester);
      Get.toNamed<void>('/does-not-exist');
      await settleFrames(tester);
      expect(find.byType(NotFoundScreen), findsOneWidget);
    });
  });
}
