import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/testing.dart';
import 'package:real_estate/bindings/initial_bindings.dart';
import 'package:real_estate/controller/settings/settings_controller.dart';
import 'package:real_estate/core/class/crud.dart';
import 'package:real_estate/core/functions/check_internet.dart';
import 'package:real_estate/core/services/services.dart';
import 'package:real_estate/data/datasource/remote/products_remote_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  group('initialServices and InitialBindings', () {
    test('register the app-lifetime dependencies as permanent', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await initialServices();
      final Crud crud = Crud(
        client: MockClient((_) async => jsonResponse('{}')),
        connectivityCheck: () async => true,
      );
      InitialBindings(crud: crud).dependencies();

      expect(Get.find<MyServices>().sharedPreferences, isNotNull);
      expect(Get.find<Crud>(), same(crud));
      expect(Get.isRegistered<ProductsRemoteData>(), isTrue);
      expect(Get.isRegistered<SettingsController>(), isTrue);
      expect(Get.isPrepared<Crud>(), isFalse);
    });

    test('lock the app to portrait before anything else starts', () async {
      final List<MethodCall> calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (
            MethodCall call,
          ) async {
            calls.add(call);
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await initialServices();
      final MethodCall orientation = calls.singleWhere(
        (MethodCall c) => c.method == 'SystemChrome.setPreferredOrientations',
      );
      expect(orientation.arguments, <String>['DeviceOrientation.portraitUp']);
    });

    test('build a real client when none is injected', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await initialServices();
      InitialBindings().dependencies();
      expect(Get.isRegistered<Crud>(), isTrue);
    });
  });

  group('checkInternet', () {
    test('true when the host resolves', () async {
      final bool online = await checkInternet(
        lookup: (_) async => <InternetAddress>[InternetAddress('1.1.1.1')],
      );
      expect(online, isTrue);
    });

    test('looks up the API host', () async {
      late String asked;
      await checkInternet(
        lookup: (String host) async {
          asked = host;
          return <InternetAddress>[];
        },
      );
      expect(asked, 'dummyjson.com');
    });

    test('false on an empty answer', () async {
      expect(
        await checkInternet(lookup: (_) async => <InternetAddress>[]),
        isFalse,
      );
    });

    test('false when the lookup fails', () async {
      expect(
        await checkInternet(
          lookup: (_) async => throw const SocketException('no network'),
        ),
        isFalse,
      );
    });

    test('false when the lookup hangs', () async {
      final Completer<List<InternetAddress>> never =
          Completer<List<InternetAddress>>();
      expect(
        await checkInternet(
          lookup: (_) => never.future,
          timeout: const Duration(milliseconds: 20),
        ),
        isFalse,
      );
    });
  });
}
