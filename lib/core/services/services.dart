import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide services that need async setup before `runApp`.
class MyServices extends GetxService {
  late SharedPreferences sharedPreferences;

  Future<MyServices> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
    return this;
  }
}

Future<void> initialServices() async {
  // The design is for phones held upright; font sizes scale with the screen
  // width, so a landscape layout would blow the text up.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  await Get.putAsync<MyServices>(() => MyServices().init(), permanent: true);
}
