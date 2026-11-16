import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/core/offline/offline_database.dart';
import 'package:omeo/core/offline/offline_store.dart';
import 'package:uuid/uuid.dart';

/// Rejoue une écriture en attente auprès de l'API. Fourni par le module qui
/// possède ce type d'écriture.
typedef PendingWriteHandler = Future<void> Function(PendingWrite write);

/// Après ce nombre d'échecs réseau, l'écriture reste en attente mais n'est
/// plus rejouée qu'au prochain retour du réseau.
const maxReplayAttempts = 5;

/// File d'attente hors connexion : les écritures (repas, eau, poids,
/// activités) sont persistées avec leur clé d'idempotence, puis rejouées
/// dans l'ordre au retour du réseau. Une erreur problem+json (refus de
/// l'API) retire l'écriture et la signale ; une erreur réseau la garde.
class OfflineQueue {
  OfflineQueue({
    required OfflineStore store,
    required void Function(ApiFailure failure) onRejected,
  }) : _store = store,
       _onRejected = onRejected;

  final OfflineStore _store;
  final void Function(ApiFailure failure) _onRejected;
  final _handlers = <String, PendingWriteHandler>{};
  static const _uuid = Uuid();
  Future<void>? _replaying;

  /// Écritures en attente, pour la bannière et les éléments « en cours de
  /// calcul ».
  Stream<List<PendingWrite>> watch() => _store.watch();

  /// Enregistre la façon de rejouer un type d'écriture.
  void register(String kind, PendingWriteHandler handler) =>
      _handlers[kind] = handler;

  /// Met une écriture en attente et renvoie l'élément créé.
  Future<PendingWrite> enqueue({
    required String kind,
    required Map<String, Object?> payload,
    String? idempotencyKey,
  }) async {
    final write = PendingWrite(
      id: _uuid.v4(),
      kind: kind,
      idempotencyKey: idempotencyKey ?? _uuid.v4(),
      payload: payload,
      createdAt: DateTime.now(),
    );
    await _store.put(write);
    return write;
  }

  /// Rejoue les écritures en attente. Un seul rejeu à la fois.
  Future<void> replay() => _replaying ??= _replay().whenComplete(
    () => _replaying = null,
  );

  Future<void> _replay() async {
    for (final write in await _store.all()) {
      final handler = _handlers[write.kind];
      if (handler == null || write.attempts >= maxReplayAttempts) continue;
      try {
        await handler(write);
        await _store.remove(write.id);
      } on ProblemFailure catch (e) {
        // 5xx : l'API n'a pas traité la demande, on réessaiera.
        if (e.status >= 500) {
          await _store.put(write.retried());
          return;
        }
        await _store.remove(write.id);
        _onRejected(e);
      } on ApiFailure {
        // Toujours hors connexion : on garde l'ordre et on attend le réseau.
        await _store.put(write.retried());
        return;
      }
    }
  }
}

/// Base locale, ouverte une fois pour toute l'app.
final offlineDatabaseProvider = Provider<OfflineDatabase>((ref) {
  final db = OfflineDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Stockage de la file (SQLite ; remplacé en mémoire dans les tests).
final offlineStoreProvider = Provider<OfflineStore>(
  (ref) => DriftOfflineStore(ref.watch(offlineDatabaseProvider)),
);

/// État du réseau de l'appareil : `true` s'il y a une connexion.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool online(List<ConnectivityResult> r) =>
      r.any((c) => c != ConnectivityResult.none);
  yield online(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(online);
});

/// File d'attente de l'app ; rejouée à chaque retour du réseau.
final offlineQueueProvider = Provider<OfflineQueue>((ref) {
  final bus = ref.watch(globalErrorBusProvider);
  final queue = OfflineQueue(
    store: ref.watch(offlineStoreProvider),
    onRejected: bus.report,
  );
  ref.listen(connectivityProvider, (previous, next) {
    if (next.value ?? false) unawaited(queue.replay());
  });
  return queue;
});

/// Écritures en attente, pour l'affichage.
final pendingWritesProvider = StreamProvider<List<PendingWrite>>(
  (ref) => ref.watch(offlineQueueProvider).watch(),
);
