import 'dart:convert';

import 'package:get/get.dart';
import 'package:real_estate/bindings/app_bindings.dart';
import 'package:real_estate/controller/details/details_controller.dart';
import 'package:real_estate/controller/main/main_controller.dart';
import 'package:real_estate/core/class/route_arguments.dart';
import 'package:real_estate/data/model/product.dart';

import 'home_api.dart';
import 'test_doubles.dart';

/// The product fixture (id 14: three photos, three reviews, two tags).
Product fixtureProduct() =>
    Product.tryParse(fixture('product') as Map<String, dynamic>)!;

/// The fixture with a very long title, a long tag and six photos.
Map<String, Object?> longProductJson() {
  final Map<String, dynamic> json = Map<String, dynamic>.of(
    fixture('product') as Map<String, dynamic>,
  );
  json['title'] =
      'Extraordinarily Long Executive Conference Chair With Adjustable '
      'Lumbar Support And Extra Wide Armrests';
  json['tags'] = <String>[
    'furniture',
    'office chairs',
    'an unusually long tag name',
    'ergonomic',
    'premium',
  ];
  json['images'] = <String>[
    for (int i = 1; i <= 6; i++) 'https://example.test/14/$i.png',
  ];
  return json;
}

/// [FakeHomeApi.explore] plus the product and the booking endpoint.
FakeHomeApi detailsApi() => FakeHomeApi.explore()
  ..responses['/products/14'] = jsonResponse(fixtureText('product'))
  ..responses['/carts/add'] = jsonResponse(
    jsonEncode(<String, Object>{'id': 51, 'userId': 1}),
  );

/// Details for listing 14, as if opened from a card.
class DetailsTestBinding extends Bindings {
  DetailsTestBinding({this.preview = true});

  final bool preview;

  @override
  void dependencies() => Get.put<DetailsController>(
    DetailsController(
      args: ProductArgs(id: 14, preview: preview ? fixtureProduct() : null),
    ),
  );
}

/// The main shell opened on the Profile tab.
class ProfileTabBinding extends Bindings {
  @override
  void dependencies() {
    MainBinding().dependencies();
    Get.find<MainController>().select(MainTab.profile);
  }
}
