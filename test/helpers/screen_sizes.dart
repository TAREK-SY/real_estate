import 'package:flutter/widgets.dart';

/// Size matrix for screen tests, in logical pixels at density 1.
const Map<String, Size> screenSizes = <String, Size>{
  'phone-320': Size(320, 568),
  'phone-360': Size(360, 640),
  'phone-393': Size(393, 852),
  'design-430': Size(430, 932),
  'landscape-932': Size(932, 430),
  'tablet-800': Size(800, 1280),
};

const List<String> testLocales = <String>['en', 'ar'];
