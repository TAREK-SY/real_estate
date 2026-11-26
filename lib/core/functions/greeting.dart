import '../localization/app_strings.dart';

/// Greeting for the time of day: morning before noon, afternoon until 6 pm.
String greetingKey(DateTime now) {
  if (now.hour < 12) return AppStrings.homeGreetingMorning;
  if (now.hour < 18) return AppStrings.homeGreetingAfternoon;
  return AppStrings.homeGreetingEvening;
}
