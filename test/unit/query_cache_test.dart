import 'dart:async';

import 'package:either_dart/either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate/core/class/query_cache.dart';
import 'package:real_estate/core/class/status_request.dart';

void main() {
  late DateTime now;
  late QueryCache cache;

  setUp(() {
    now = DateTime(2026, 1, 1, 12);
    cache = QueryCache(now: () => now);
  });

  test('a hit within the TTL does not call the loader again', () async {
    int calls = 0;
    Future<Either<StatusRequest, String>> load() async {
      calls++;
      return const Right('v');
    }

    expect((await cache.fetch('k', load)).right, 'v');
    now = now.add(const Duration(minutes: 4));
    expect((await cache.fetch('k', load)).right, 'v');
    expect(calls, 1);
  });

  test('an expired entry is loaded again', () async {
    int calls = 0;
    Future<Either<StatusRequest, String>> load() async {
      calls++;
      return Right('v$calls');
    }

    await cache.fetch('k', load);
    now = now.add(const Duration(minutes: 5, seconds: 1));
    expect((await cache.fetch('k', load)).right, 'v2');
    expect(calls, 2);
  });

  test('failures are not cached, so a retry goes out', () async {
    int calls = 0;
    Future<Either<StatusRequest, String>> load() async {
      calls++;
      return calls == 1
          ? const Left(StatusRequest.serverFailure)
          : const Right('ok');
    }

    expect((await cache.fetch('k', load)).left, StatusRequest.serverFailure);
    expect((await cache.fetch('k', load)).right, 'ok');
    expect(calls, 2);
  });

  test('concurrent identical requests share one load', () async {
    int calls = 0;
    final Completer<Either<StatusRequest, String>> gate =
        Completer<Either<StatusRequest, String>>();
    Future<Either<StatusRequest, String>> load() {
      calls++;
      return gate.future;
    }

    final Future<Either<StatusRequest, String>> a = cache.fetch('k', load);
    final Future<Either<StatusRequest, String>> b = cache.fetch('k', load);
    gate.complete(const Right('v'));
    expect((await a).right, 'v');
    expect((await b).right, 'v');
    expect(calls, 1);
  });

  test('different keys are cached separately', () async {
    await cache.fetch('a', () async => const Right('1'));
    await cache.fetch('b', () async => const Right('2'));
    expect(cache.length, 2);
    expect((await cache.fetch('a', () async => const Right('x'))).right, '1');
  });

  test('evicts the oldest entry beyond maxEntries', () async {
    final QueryCache small = QueryCache(maxEntries: 2, now: () => now);
    await small.fetch('a', () async => const Right('1'));
    await small.fetch('b', () async => const Right('2'));
    await small.fetch('c', () async => const Right('3'));
    expect(small.length, 2);
    expect(
      (await small.fetch('a', () async => const Right('new'))).right,
      'new',
    );
  });

  test('a throwing loader does not leave a stuck in-flight entry', () async {
    await expectLater(
      cache.fetch<String>('k', () async => throw StateError('boom')),
      throwsStateError,
    );
    expect((await cache.fetch('k', () async => const Right('ok'))).right, 'ok');
  });

  test('a loader that throws synchronously does not block retries', () async {
    await expectLater(
      cache.fetch<String>('k', () => throw StateError('sync boom')),
      throwsStateError,
    );
    expect((await cache.fetch('k', () async => const Right('ok'))).right, 'ok');
  });

  test(
    'a load started before clear is not stored or joined after it',
    () async {
      final Completer<Either<StatusRequest, String>> old =
          Completer<Either<StatusRequest, String>>();
      final Future<Either<StatusRequest, String>> first = cache.fetch(
        'k',
        () => old.future,
      );
      cache.clear();
      int calls = 0;
      final Future<Either<StatusRequest, String>> second = cache.fetch('k', () {
        calls++;
        return Future<Either<StatusRequest, String>>.value(const Right('new'));
      });
      old.complete(const Right('stale'));
      expect((await first).right, 'stale');
      expect((await second).right, 'new');
      expect(calls, 1);
      expect(
        (await cache.fetch('k', () async => const Right('x'))).right,
        'new',
      );
    },
  );

  test('maxEntries must be positive', () {
    expect(() => QueryCache(maxEntries: 0), throwsAssertionError);
  });

  test('clear empties the cache', () async {
    await cache.fetch('a', () async => const Right('1'));
    cache.clear();
    expect(cache.length, 0);
  });
}
