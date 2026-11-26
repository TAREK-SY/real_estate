import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:real_estate/core/localization/category_names.dart';
import 'package:real_estate/data/model/category.dart';

import 'screen_harness.dart';

class _Names extends StatelessWidget {
  const _Names();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Text(
            categoryDisplayName(
              const Category(slug: 'home-decoration', name: 'Home Decoration'),
            ),
          ),
          Text(
            categoryDisplayName(
              const Category(slug: 'garden-tools', name: 'Garden Tools'),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  setUpAll(initScreenTestEnvironment);
  setUp(setUpScreenDependencies);

  testWidgets('known slugs are translated', (WidgetTester tester) async {
    await pumpScreen(tester, page: () => const _Names(), locale: 'ar');
    expect(find.text('ديكور المنزل'), findsOneWidget);
  });

  testWidgets('unknown slugs fall back to the API name', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, page: () => const _Names(), locale: 'ar');
    expect(find.text('Garden Tools'), findsOneWidget);
  });

  testWidgets('English uses the curated names', (WidgetTester tester) async {
    await pumpScreen(tester, page: () => const _Names());
    expect(find.text('Home Decoration'), findsOneWidget);
  });
}
