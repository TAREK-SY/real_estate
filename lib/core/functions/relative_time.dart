import '../localization/app_strings.dart';

/// "6 days ago" for [date], measured against [now]. Future dates (clock
/// skew) read as just now.
String relativeTime(DateTime date, DateTime now) {
  final Duration age = now.difference(date);
  final (String key, int count) = switch (age) {
    Duration(inMinutes: < 1) => (AppStrings.timeJustNow, 0),
    Duration(inHours: < 1) => (AppStrings.timeMinutes, age.inMinutes),
    Duration(inDays: < 1) => (AppStrings.timeHours, age.inHours),
    Duration(inDays: < 30) => (AppStrings.timeDays, age.inDays),
    Duration(inDays: < 365) => (AppStrings.timeMonths, age.inDays ~/ 30),
    _ => (AppStrings.timeYears, age.inDays ~/ 365),
  };
  return key == AppStrings.timeJustNow
      ? AppStrings.t(key)
      : AppStrings.plural(key, count);
}
