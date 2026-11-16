import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/offline/offline_queue.dart';
import 'package:omeo/core/offline/offline_store.dart';
import 'package:omeo/features/auth/application/session.dart';
import 'package:omeo/features/tracking/application/home_controller.dart';
import 'package:omeo/features/tracking/data/health.dart';
import 'package:omeo/features/tracking/data/tracking_repository.dart';
import 'package:omeo_api/omeo_api.dart';
import 'package:uuid/uuid.dart';

/// Types d'écriture du suivi dans la file hors connexion.
const waterAddKind = 'water.add';
const weightAddKind = 'weight.add';

DateTime _today() => DateUtils.dateOnly(DateTime.now());

// ───────────────────────────── Journal ─────────────────────────────

/// Jour affiché dans le journal (aujourd'hui par défaut).
class JournalDay extends Notifier<DateTime> {
  @override
  DateTime build() => _today();

  void select(DateTime date) => state = DateUtils.dateOnly(date);
}

final NotifierProvider<JournalDay, DateTime> journalDayProvider =
    NotifierProvider(JournalDay.new);

/// Journal d'un jour (HIS-01, HIS-04).
final FutureProviderFamily<DayDetail, DateTime> dayDetailProvider =
    FutureProvider.family(
      (ref, date) => ref.watch(trackingRepositoryProvider).getDay(date),
    );

/// État des jours d'un mois (HIS-02). Clé : premier jour du mois.
final FutureProviderFamily<List<GetCalendar200ResponseInner>, DateTime>
calendarProvider = FutureProvider.autoDispose.family(
  (ref, month) => ref.watch(trackingRepositoryProvider).getCalendar(month),
);

/// Issue d'une écriture du suivi : réponse de l'API, ou mise en attente du
/// réseau (les totaux ne changent qu'à la réponse).
sealed class TrackingWriteOutcome<T> {
  const TrackingWriteOutcome();
}

final class TrackingSaved<T> extends TrackingWriteOutcome<T> {
  const TrackingSaved(this.result);
  final T result;
}

final class TrackingQueued<T> extends TrackingWriteOutcome<T> {
  const TrackingQueued(this.pending);
  final PendingWrite pending;
}

/// Envoie une écriture, ou la met en file d'attente sans réseau avec la
/// même clé d'idempotence.
Future<TrackingWriteOutcome<T>> _sendOrQueue<T>({
  required OfflineQueue queue,
  required String kind,
  required Map<String, Object?> payload,
  required Future<T> Function(String key) send,
}) async {
  final key = const Uuid().v4();
  try {
    return TrackingSaved(await send(key));
  } on NetworkFailure {
    return TrackingQueued(
      await queue.enqueue(kind: kind, payload: payload, idempotencyKey: key),
    );
  } on TimeoutFailure {
    return TrackingQueued(
      await queue.enqueue(kind: kind, payload: payload, idempotencyKey: key),
    );
  }
}

String _date(DateTime d) => d.toIso8601String().substring(0, 10);

/// Hydratation (HIS-03) : verre, bouteille ou quantité libre.
class WaterWriter {
  WaterWriter(this._ref);

  final Ref _ref;

  TrackingRepository get _repo => _ref.read(trackingRepositoryProvider);

  Future<void> replay(PendingWrite write) => _repo.addWater(
    amountMl: write.payload['amount_ml']! as int,
    date: DateTime.parse(write.payload['date']! as String),
    idempotencyKey: write.idempotencyKey,
  );

  Future<TrackingWriteOutcome<AddWater201Response>> add({
    required int amountMl,
    required DateTime date,
  }) async {
    final outcome = await _sendOrQueue(
      queue: _ref.read(offlineQueueProvider),
      kind: waterAddKind,
      payload: {'amount_ml': amountMl, 'date': _date(date)},
      send: (key) =>
          _repo.addWater(amountMl: amountMl, date: date, idempotencyKey: key),
    );
    if (outcome is TrackingSaved) {
      _ref
        ..invalidate(dayDetailProvider(DateUtils.dateOnly(date)))
        ..invalidate(homeProvider);
    }
    return outcome;
  }
}

final Provider<WaterWriter> waterWriterProvider = Provider((ref) {
  final writer = WaterWriter(ref);
  ref.watch(offlineQueueProvider).register(waterAddKind, writer.replay);
  return writer;
});

// ───────────────────────────── Progression ─────────────────────────────

/// Onglet et période choisis (PRO-01 à PRO-03).
typedef ProgressSelection = ({ProgressMetric metric, ProgressRange range});

class ProgressSelectionController extends Notifier<ProgressSelection> {
  @override
  ProgressSelection build() =>
      (metric: ProgressMetric.kcal, range: ProgressRange.week);

  void metric(ProgressMetric m) => state = (metric: m, range: state.range);
  void range(ProgressRange r) => state = (metric: state.metric, range: r);
}

final NotifierProvider<ProgressSelectionController, ProgressSelection>
progressSelectionProvider = NotifierProvider(ProgressSelectionController.new);

/// Vrai si l'offre courante ouvre les périodes longues (calculé par l'API).
final Provider<bool> longRangeAllowedProvider = Provider(
  (ref) =>
      ref
          .watch(meProvider)
          .value
          ?.entitlements
          .features['progress_long_range'] ??
      false,
);

/// Courbe d'un nutriment sur une période.
final FutureProviderFamily<Progress, ProgressSelection> progressProvider =
    FutureProvider.family(
      (ref, s) =>
          ref.watch(trackingRepositoryProvider).getProgress(s.metric, s.range),
    );

// ───────────────────────────── Poids ─────────────────────────────

class WeightRangeController extends Notifier<WeightRange> {
  @override
  WeightRange build() => WeightRange.quarter;

  // Choix d'une période : un setter suffit.
  // ignore: avoid_setters_without_getters
  set range(WeightRange r) => state = r;
}

final NotifierProvider<WeightRangeController, WeightRange> weightRangeProvider =
    NotifierProvider(WeightRangeController.new);

final FutureProviderFamily<WeightOverview, WeightRange> weightsProvider =
    FutureProvider.family(
      (ref, range) => ref.watch(trackingRepositoryProvider).getWeights(range),
    );

/// Pesées (PRO-07) : l'API recalcule les objectifs à chaque mesure.
class WeightWriter {
  WeightWriter(this._ref);

  final Ref _ref;

  TrackingRepository get _repo => _ref.read(trackingRepositoryProvider);

  Future<void> replay(PendingWrite write) => _repo.addWeight(
    weightKg: (write.payload['weight_kg']! as num).toDouble(),
    date: DateTime.parse(write.payload['date']! as String),
    idempotencyKey: write.idempotencyKey,
  );

  Future<TrackingWriteOutcome<AddWeight201Response>> add({
    required double weightKg,
    required DateTime date,
  }) async {
    final outcome = await _sendOrQueue(
      queue: _ref.read(offlineQueueProvider),
      kind: weightAddKind,
      payload: {'weight_kg': weightKg, 'date': _date(date)},
      send: (key) =>
          _repo.addWeight(weightKg: weightKg, date: date, idempotencyKey: key),
    );
    if (outcome is TrackingSaved) _refresh();
    return outcome;
  }

  Future<void> delete(String id) async {
    await _repo.deleteWeight(id);
    _refresh();
  }

  void _refresh() {
    _ref
      ..invalidate(weightsProvider)
      ..invalidate(meProvider)
      ..invalidate(homeProvider);
  }
}

final Provider<WeightWriter> weightWriterProvider = Provider((ref) {
  final writer = WeightWriter(ref);
  ref.watch(offlineQueueProvider).register(weightAddKind, writer.replay);
  return writer;
});

// ───────────────────────────── Santé ─────────────────────────────

/// Types demandés : pas, distance, calories dépensées, séances, poids.
const Set<HealthType> requestedHealthTypes = {
  HealthType.steps,
  HealthType.distance,
  HealthType.activeCalories,
  HealthType.workouts,
  HealthType.weight,
};

/// Connexion santé (PRO-05, PRF-05). Un refus n'a aucune conséquence
/// bloquante.
class HealthController extends AsyncNotifier<void> {
  @override
  void build() {}

  /// Vrai si au moins un type a été accordé.
  Future<bool> connect([Set<HealthType> types = requestedHealthTypes]) async {
    final access = ref.read(healthAccessProvider);
    if (access == null) return false;
    var connected = false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final granted = await access.requestRead(types);
      if (granted.isEmpty) return;
      await ref
          .read(healthRepositoryProvider)
          .connect(source: access.source, granted: granted);
      connected = true;
      ref.invalidate(progressProvider);
    });
    return connected;
  }

  Future<bool> disconnect() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(healthRepositoryProvider).disconnect();
      ref.invalidate(progressProvider);
    });
    return !state.hasError;
  }
}

final AsyncNotifierProvider<HealthController, void> healthProvider =
    AsyncNotifierProvider(HealthController.new);
