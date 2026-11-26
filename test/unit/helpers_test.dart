import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:real_estate/core/class/status_request.dart';
import 'package:real_estate/core/config/app_config.dart';
import 'package:real_estate/core/functions/json_parsers.dart';
import 'package:real_estate/core/functions/price_formatter.dart';
import 'package:real_estate/core/functions/status_message.dart';
import 'package:real_estate/core/localization/app_strings.dart';
import 'package:real_estate/core/theme/app_palette.dart';

void main() {
  group('json parsers', () {
    test('jsonInt', () {
      expect(jsonInt(3), 3);
      expect(jsonInt(3.9), 3);
      expect(jsonInt('4'), 4);
      expect(jsonInt(' 5.7 '), 5);
      expect(jsonInt('x'), isNull);
      expect(jsonInt(null), isNull);
    });

    test('jsonInt returns null for non-finite values instead of throwing', () {
      expect(jsonInt('NaN'), isNull);
      expect(jsonInt('Infinity'), isNull);
      expect(jsonInt('1e400'), isNull);
      expect(jsonInt(double.nan), isNull);
      expect(jsonInt(double.infinity), isNull);
    });

    test('jsonDouble', () {
      expect(jsonDouble(2), 2.0);
      expect(jsonDouble('2.5'), 2.5);
      expect(jsonDouble(true), isNull);
    });

    test('jsonDouble returns null for non-finite values', () {
      expect(jsonDouble('NaN'), isNull);
      expect(jsonDouble('-Infinity'), isNull);
      expect(jsonDouble(double.infinity), isNull);
    });

    test('jsonString', () {
      expect(jsonString('a'), 'a');
      expect(jsonString(1), '1');
      expect(jsonString(<int>[]), isNull);
    });

    test('jsonMap and jsonList', () {
      expect(jsonMap(<String, dynamic>{'a': 1}), isNotNull);
      expect(jsonMap(<dynamic>[]), isNull);
      expect(
        jsonList(<dynamic>[
          <String, dynamic>{'a': 1},
          2,
        ], (Map<String, dynamic> m) => m['a']),
        <dynamic>[1],
      );
      expect(jsonList('x', (Map<String, dynamic> m) => m), isEmpty);
    });

    test('jsonStringList trims and drops blanks', () {
      expect(jsonStringList(<dynamic>[' a ', '', null, 3]), <String>['a', '3']);
      expect(jsonStringList('x'), isEmpty);
    });

    test('jsonFlag', () {
      expect(jsonFlag(true), isTrue);
      expect(jsonFlag(1), isTrue);
      expect(jsonFlag('1'), isTrue);
      expect(jsonFlag('true'), isTrue);
      expect(jsonFlag(0), isFalse);
      expect(jsonFlag(null), isFalse);
    });
  });

  group('formatPrice', () {
    test('whole prices have no cents', () {
      expect(formatPrice(12219), r'$12,219');
    });

    test('fractional prices keep two decimals', () {
      expect(formatPrice(1899.99), r'$1,899.99');
      expect(formatPrice(9.5), r'$9.50');
    });

    test('uses Western digits and no bidi marks', () {
      final String text = formatPrice(1234567.8);
      expect(text, r'$1,234,567.80');
      expect(
        RegExp(r'[\u0660-\u0669\u200E\u200F\u2066-\u2069]').hasMatch(text),
        isFalse,
      );
    });
  });

  test('formatRating rounds to one decimal and clamps', () {
    expect(formatRating(4.94), '4.9');
    expect(formatRating(3), '3.0');
    expect(formatRating(7), '5.0');
  });

  group('status messages', () {
    test('every failure has its own translated message', () {
      expect(
        statusMessageKey(StatusRequest.offlineFailure),
        AppStrings.stateOffline,
      );
      expect(
        statusMessageKey(StatusRequest.timeoutFailure),
        AppStrings.stateTimeout,
      );
      expect(
        statusMessageKey(StatusRequest.serverFailure),
        AppStrings.stateServer,
      );
      expect(
        statusMessageKey(StatusRequest.notFoundFailure),
        AppStrings.stateNotFound,
      );
      expect(
        statusMessageKey(StatusRequest.unexpectedResponse),
        AppStrings.stateUnexpected,
      );
      expect(statusMessageKey(StatusRequest.failure), AppStrings.stateFailure);
      expect(statusMessageKey(StatusRequest.empty), AppStrings.stateEmpty);
      expect(statusMessageKey(StatusRequest.loading), AppStrings.stateLoading);
      expect(statusMessageKey(StatusRequest.none), AppStrings.stateFailure);
      expect(statusMessageKey(StatusRequest.success), AppStrings.stateFailure);
    });

    test('retry is offered except for not found and non-failures', () {
      expect(canRetry(StatusRequest.offlineFailure), isTrue);
      expect(canRetry(StatusRequest.timeoutFailure), isTrue);
      expect(canRetry(StatusRequest.serverFailure), isTrue);
      expect(canRetry(StatusRequest.unexpectedResponse), isTrue);
      expect(canRetry(StatusRequest.failure), isTrue);
      expect(canRetry(StatusRequest.notFoundFailure), isFalse);
      expect(canRetry(StatusRequest.success), isFalse);
      expect(canRetry(StatusRequest.empty), isFalse);
    });
  });

  group('AppConfig', () {
    test('defaults to DummyJSON', () {
      expect(AppConfig.baseUrl, 'https://dummyjson.com');
      expect(AppConfig.isConfigured, isTrue);
    });

    test('normalize strips a trailing slash and spaces', () {
      expect(
        AppConfig.normalize(' https://a.test/api/ '),
        'https://a.test/api',
      );
    });

    test('only absolute http(s) URLs are valid', () {
      expect(AppConfig.isValidBaseUrl('https://dummyjson.com'), isTrue);
      expect(AppConfig.isValidBaseUrl('http://10.0.2.2:8080'), isTrue);
      expect(AppConfig.isValidBaseUrl('dummyjson.com'), isFalse);
      expect(AppConfig.isValidBaseUrl('ftp://x.test'), isFalse);
      expect(AppConfig.isValidBaseUrl(''), isFalse);
      expect(AppConfig.misconfigurationMessage, contains('API_BASE_URL'));
    });
  });

  group('AppPalette', () {
    test('the three palettes differ only in primary', () {
      expect(AppPalette.of(PaletteId.original).primary.toARGB32(), 0xFF0061FF);
      expect(AppPalette.of(PaletteId.purple).primary.toARGB32(), 0xFF8B5DFF);
      expect(AppPalette.of(PaletteId.orange).primary.toARGB32(), 0xFFFF8000);
      expect(AppPalette.purple.black1, AppPalette.original.black1);
    });

    test('soft and faint tints are 10% and 4% of primary', () {
      final AppPalette palette = AppPalette.orange;
      expect(palette.primarySoft.a, closeTo(0.10, 0.01));
      expect(palette.primaryFaint.a, closeTo(0.04, 0.01));
      expect(palette.primarySoft.r, palette.primary.r);
    });

    test('unknown stored names fall back to the original palette', () {
      expect(PaletteId.fromName('purple'), PaletteId.purple);
      expect(PaletteId.fromName('neon'), PaletteId.original);
      expect(PaletteId.fromName(null), PaletteId.original);
    });

    test('lerp and copyWith', () {
      final AppPalette mid = AppPalette.original.lerp(AppPalette.orange, 0.8);
      expect(mid.id, PaletteId.orange);
      expect(AppPalette.original.lerp(null, 0.5), AppPalette.original);
      expect(
        AppPalette.original.copyWith(id: PaletteId.purple).id,
        PaletteId.purple,
      );
    });

    test('copyWith and lerp keep every color', () {
      const AppPalette custom = AppPalette(
        id: PaletteId.purple,
        primary: Color(0xFF112233),
        black1: Color(0xFF445566),
      );
      expect(custom.copyWith(id: PaletteId.orange).black1, custom.black1);
      final AppPalette recolored = custom.copyWith(
        primary: AppPalette.orange.primary,
      );
      expect(recolored.id, PaletteId.purple);
      expect(recolored.primary, AppPalette.orange.primary);
      expect(recolored.black1, custom.black1);
      expect(custom.lerp(custom, 0.5).black1, custom.black1);
    });

    test('shadows use the design values', () {
      expect(AppPalette.original.cardShadow.single.blurRadius, 30);
      expect(AppPalette.original.pillShadow.single.offset.dy, 20);
      expect(AppPalette.original.buttonShadow.single.offset.dx, 4);
      expect(AppPalette.original.overlay.a, closeTo(0.30, 0.01));
    });
  });
}
