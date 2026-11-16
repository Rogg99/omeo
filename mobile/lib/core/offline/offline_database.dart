import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:omeo/core/offline/offline_store.dart';

part 'offline_database.g.dart';

/// Écritures en attente d'envoi.
@DataClassName('PendingWriteRow')
class PendingWrites extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get idempotencyKey => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Base locale de l'app (cache et file d'attente hors connexion).
@DriftDatabase(tables: [PendingWrites])
class OfflineDatabase extends _$OfflineDatabase {
  OfflineDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'omeo_offline'));

  @override
  int get schemaVersion => 1;
}

/// File d'attente persistée dans SQLite (drift).
final class DriftOfflineStore implements OfflineStore {
  DriftOfflineStore(this._db);

  final OfflineDatabase _db;

  SimpleSelectStatement<$PendingWritesTable, PendingWriteRow> get _ordered =>
      _db.select(_db.pendingWrites)
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);

  static PendingWrite _fromRow(PendingWriteRow r) => PendingWrite(
    id: r.id,
    kind: r.kind,
    idempotencyKey: r.idempotencyKey,
    payload: (jsonDecode(r.payload) as Map).cast<String, Object?>(),
    createdAt: r.createdAt,
    attempts: r.attempts,
  );

  @override
  Stream<List<PendingWrite>> watch() =>
      _ordered.watch().map((rows) => rows.map(_fromRow).toList());

  @override
  Future<List<PendingWrite>> all() async =>
      (await _ordered.get()).map(_fromRow).toList();

  @override
  Future<void> put(PendingWrite write) => _db
      .into(_db.pendingWrites)
      .insertOnConflictUpdate(
        PendingWritesCompanion.insert(
          id: write.id,
          kind: write.kind,
          idempotencyKey: write.idempotencyKey,
          payload: jsonEncode(write.payload),
          createdAt: write.createdAt,
          attempts: Value(write.attempts),
        ),
      );

  @override
  Future<void> remove(String id) =>
      (_db.delete(_db.pendingWrites)..where((t) => t.id.equals(id))).go();
}
