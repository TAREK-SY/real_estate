import 'package:get/get.dart';

import '../controller/settings/settings_controller.dart';
import '../core/class/crud.dart';
import '../data/datasource/remote/products_remote_data.dart';

/// App-lifetime dependencies, registered before `runApp`.
class InitialBindings extends Bindings {
  InitialBindings({this.crud});

  /// Injectable so tests can build the app with a mocked HTTP client.
  final Crud? crud;

  @override
  void dependencies() {
    final Crud client = crud ?? Crud();
    Get.put<Crud>(client, permanent: true);
    Get.put<ProductsRemoteData>(ProductsRemoteData(client), permanent: true);
    Get.put<SettingsController>(SettingsController(), permanent: true);
  }
}
