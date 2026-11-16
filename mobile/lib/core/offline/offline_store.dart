import 'dart:async';

import 'package:flutter/foundation.dart';

/// Écriture mise en attente : rejouée au retour du réseau avec la même clé
/// d'idempotence, pour que l'API ne l'applique qu'une fois.
@immutable
final class PendingWrite {
  const PendingWrite({
    required this.id,
    required this.kind,
    required this.idempotencyKey,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
  });

  final String id;

  /// Type d'écriture (`meal.create`…), associé au module qui sait la rejouer.
  final String kind;
  final String idempotencyKey;

  /// Corps JSON de la requête, tel qu'envoyé à l'API.
  final Map<String, Object?> payload;
  final DateTime createdAt;
  final int attempts;

  PendingWrite retried() => PendingWrite(
    id: id,
    kind: kind,
    idempotencyKey: idempotencyKey,
    payload: payload,
    createdAt: createdAt,
    attempts: attempts + 1,
  );
}

/// Stockage persistant de la file d'attente.
abstract interface class OfflineStore {
  /// Écritures en attente, dans l'ordre de création, à chaque changement.
  Stream<List<PendingWrite>> watch();

  Future<List<PendingWrite>> all();

  Future<void> put(PendingWrite write);

  Future<void> remove(String id);
}

/// Stockage en mémoire (tests et flavor mock).
final class MemoryOfflineStore implements OfflineStore {
  final _items = <String, PendingWrite>{};
  late final _controller = StreamController<List<PendingWrite>>.broadcast(
    onListen: _emit,
  );

  List<PendingWrite> get _sorted =>
      _items.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  void _emit() => _controller.add(_sorted);

  @override
  Stream<List<PendingWrite>> watch() async* {
    yield _sorted;
    yield* _controller.stream;
  }

  @override
  Future<List<PendingWrite>> all() async => _sorted;

  @override
  Future<void> put(PendingWrite write) async {
    _items[write.id] = write;
    _emit();
  }

  @override
  Future<void> remove(String id) async {
    _items.remove(id);
    _emit();
  }
}
