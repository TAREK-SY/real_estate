import 'package:either_dart/either.dart';

import 'status_request.dart';

/// In-memory cache for GET results, keyed by the full request URL.
///
/// - A hit within [ttl] returns the stored value without a request.
/// - Identical requests in flight share one Future, so two widgets asking
///   for the same page at once cause a single call.
/// - Failures are never stored: the next attempt (a retry) goes out.
class QueryCache {
  QueryCache({
    this.ttl = const Duration(minutes: 5),
    DateTime Function()? now,
    this.maxEntries = 100,
  }) : assert(maxEntries > 0, 'maxEntries must be positive'),
       _now = now ?? DateTime.now;

  final Duration ttl;
  final int maxEntries;
  final DateTime Function() _now;

  final Map<String, _Entry> _entries = <String, _Entry>{};
  final Map<String, Future<Either<StatusRequest, Object>>> _inFlight =
      <String, Future<Either<StatusRequest, Object>>>{};

  /// Bumped by [clear], so a load that started before it neither stores its
  /// result nor gets joined by requests made after it.
  int _generation = 0;

  Future<Either<StatusRequest, T>> fetch<T extends Object>(
    String key,
    Future<Either<StatusRequest, T>> Function() load,
  ) async {
    final _Entry? entry = _entries[key];
    if (entry != null && _now().isBefore(entry.expiresAt)) {
      return Right(entry.value as T);
    }

    final Future<Either<StatusRequest, Object>> pending = _inFlight[key] ??=
        _load(key, load);
    final Either<StatusRequest, Object> result = await pending;
    return result.isRight
        ? Right(result.right as T)
        : Left<StatusRequest, T>(result.left);
  }

  Future<Either<StatusRequest, Object>> _load<T extends Object>(
    String key,
    Future<Either<StatusRequest, T>> Function() load,
  ) async {
    final int generation = _generation;
    // Yield first so this future is registered in _inFlight before the
    // finally below can run, even when [load] throws synchronously.
    await null;
    try {
      final Either<StatusRequest, T> result = await load();
      if (result.isLeft) return Left(result.left);
      if (generation == _generation) {
        if (_entries.length >= maxEntries) {
          _entries.remove(_entries.keys.first);
        }
        _entries[key] = _Entry(result.right, _now().add(ttl));
      }
      return Right(result.right);
    } finally {
      // After a clear, the entry under this key belongs to a newer load.
      if (generation == _generation) _inFlight.remove(key);
    }
  }

  /// Drops every stored result. Loads already running finish for their own
  /// callers but are not stored, and new requests start fresh.
  void clear() {
    _entries.clear();
    _inFlight.clear();
    _generation++;
  }

  int get length => _entries.length;
}

class _Entry {
  const _Entry(this.value, this.expiresAt);

  final Object value;
  final DateTime expiresAt;
}
