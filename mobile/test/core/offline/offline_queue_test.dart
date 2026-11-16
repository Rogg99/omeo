import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/offline/offline_queue.dart';
import 'package:omeo/core/offline/offline_store.dart';

void main() {
  late MemoryOfflineStore store;
  late List<ApiFailure> rejected;
  late OfflineQueue queue;

  setUp(() {
    store = MemoryOfflineStore();
    rejected = [];
    queue = OfflineQueue(store: store, onRejected: rejected.add);
  });

  test("rejoue dans l'ordre avec la même clé d'idempotence", () async {
    final keys = <String>[];
    queue.register('meal.create', (w) async => keys.add(w.idempotencyKey));
    final a = await queue.enqueue(kind: 'meal.create', payload: {'n': 1});
    final b = await queue.enqueue(kind: 'meal.create', payload: {'n': 2});
    await queue.replay();
    expect(keys, [a.idempotencyKey, b.idempotencyKey]);
    expect(await store.all(), isEmpty);
  });

  test(
    'toujours hors connexion : tout reste en attente, dans l’ordre',
    () async {
      var calls = 0;
      queue.register('meal.create', (_) async {
        calls++;
        throw const NetworkFailure();
      });
      await queue.enqueue(kind: 'meal.create', payload: {});
      await queue.enqueue(kind: 'meal.create', payload: {});
      await queue.replay();
      // On s'arrête au premier échec réseau pour garder l'ordre.
      expect(calls, 1);
      final pending = await store.all();
      expect(pending, hasLength(2));
      expect(pending.first.attempts, 1);
    },
  );

  test("refus de l'API : l'écriture est retirée et signalée", () async {
    queue.register('meal.create', (_) async {
      throw const ProblemFailure(status: 422, code: 'validation_error');
    });
    await queue.enqueue(kind: 'meal.create', payload: {});
    await queue.replay();
    expect(await store.all(), isEmpty);
    expect(rejected.single.code, 'validation_error');
  });

  test('erreur serveur : gardée pour un prochain essai', () async {
    queue.register('meal.create', (_) async {
      throw const ProblemFailure(status: 503, code: 'server_error');
    });
    await queue.enqueue(kind: 'meal.create', payload: {});
    await queue.replay();
    expect(await store.all(), hasLength(1));
    expect(rejected, isEmpty);
  });

  test('après le nombre maximal d’essais, plus de rejeu', () async {
    var calls = 0;
    queue.register('meal.create', (_) async {
      calls++;
      throw const NetworkFailure();
    });
    await queue.enqueue(kind: 'meal.create', payload: {});
    for (var i = 0; i < maxReplayAttempts + 2; i++) {
      await queue.replay();
    }
    expect(calls, maxReplayAttempts);
  });

  test('la file notifie les changements', () async {
    final seen = <int>[];
    final sub = queue.watch().listen((l) => seen.add(l.length));
    await queue.enqueue(kind: 'meal.create', payload: {});
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(seen, containsAllInOrder([0, 1]));
  });
}
