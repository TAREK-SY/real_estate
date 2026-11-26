/// Lenient readers for JSON values.
///
/// API fields are read through these instead of casting `json['x']`, so a
/// number sent as a string (or the reverse) does not throw a TypeError inside
/// `fromJson` and leave a screen stuck on its loading state.
library;

/// An int from a number or a numeric string; `null` otherwise.
int? jsonInt(Object? value) {
  if (value is int) return value;
  if (value is String) {
    final int? parsed = int.tryParse(value.trim());
    if (parsed != null) return parsed;
  }
  // toInt() throws on NaN and Infinity, which "NaN" or "1e400" parse to.
  return jsonDouble(value)?.toInt();
}

/// A finite double from a number or a numeric string; `null` otherwise.
double? jsonDouble(Object? value) {
  final double? parsed = switch (value) {
    num() => value.toDouble(),
    String() => double.tryParse(value.trim()),
    _ => null,
  };
  return (parsed != null && parsed.isFinite) ? parsed : null;
}

/// A string from a string or a number; `null` otherwise.
String? jsonString(Object? value) {
  if (value is String) return value;
  if (value is num) return value.toString();
  return null;
}

/// A JSON object or `null`.
Map<String, dynamic>? jsonMap(Object? value) =>
    value is Map<String, dynamic> ? value : null;

// The lists below are unmodifiable: parsed models are shared through the
// query cache, so a caller editing its copy would change everyone's.

/// A list of parsed objects; non-object items are skipped.
List<T> jsonList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (value is! List) return List<T>.unmodifiable(const <Never>[]);
  return List<T>.unmodifiable(
    value.whereType<Map<String, dynamic>>().map(fromJson),
  );
}

/// A list of non-empty strings; other items are skipped.
List<String> jsonStringList(Object? value) {
  if (value is! List) return const <String>[];
  return List<String>.unmodifiable(
    value
        .map(jsonString)
        .whereType<String>()
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty),
  );
}

/// A boolean from `true`, `1`, `"1"` or `"true"`.
bool jsonFlag(Object? value) =>
    value == true || value == 1 || value == '1' || value == 'true';
