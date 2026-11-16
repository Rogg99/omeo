import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo_api/omeo_api.dart';

/// Courbes disponibles (onglets de PRO-01).
enum ProgressMetric { kcal, carbs, fat, protein, fiber, salt }

/// Périodes : 7 jours en Free, les autres avec Omeo Plus.
enum ProgressRange {
  week('7d'),
  month('30d'),
  quarter('90d'),
  year('1y')
  ;

  const ProgressRange(this.value);
  final String value;
}

/// Périodes de la courbe du poids (PRO-06).
enum WeightRange {
  month('30d'),
  quarter('90d'),
  year('1y')
  ;

  const WeightRange(this.value);
  final String value;
}

/// Journal, hydratation, progression et poids.
abstract interface class TrackingRepository {
  Future<DayDetail> getDay(DateTime date);

  /// État de chaque jour du mois de [month] (seuls l'année et le mois
  /// comptent).
  Future<List<GetCalendar200ResponseInner>> getCalendar(DateTime month);

  /// [amountMl] négatif : annulation. Rejoué avec la même clé hors connexion.
  Future<AddWater201Response> addWater({
    required int amountMl,
    required DateTime date,
    required String idempotencyKey,
  });

  Future<Progress> getProgress(ProgressMetric metric, ProgressRange range);

  Future<WeightOverview> getWeights(WeightRange range);

  Future<AddWeight201Response> addWeight({
    required double weightKg,
    required DateTime date,
    required String idempotencyKey,
  });

  Future<WeightOverview> deleteWeight(String id);
}

final class TrackingApiRepository implements TrackingRepository {
  const TrackingApiRepository(this._home, this._tracking);

  final HomeApi _home;
  final TrackingApi _tracking;

  static String _month(DateTime m) {
    final month = m.month.toString().padLeft(2, '0');
    return '${m.year.toString().padLeft(4, '0')}-$month';
  }

  @override
  Future<DayDetail> getDay(DateTime date) =>
      guardApi(() => _home.getDay(date: date));

  @override
  Future<List<GetCalendar200ResponseInner>> getCalendar(DateTime month) =>
      guardApi(() => _home.getCalendar(month: _month(month)));

  @override
  Future<AddWater201Response> addWater({
    required int amountMl,
    required DateTime date,
    required String idempotencyKey,
  }) => guardApi(
    () => _tracking.addWater(
      idempotencyKey: idempotencyKey,
      addWaterRequest: AddWaterRequest(amountMl: amountMl, date: date),
    ),
  );

  @override
  Future<Progress> getProgress(ProgressMetric metric, ProgressRange range) =>
      guardApi(
        () => _tracking.getProgress(metric: metric.name, range: range.value),
      );

  @override
  Future<WeightOverview> getWeights(WeightRange range) =>
      guardApi(() => _tracking.getWeights(range: range.value));

  @override
  Future<AddWeight201Response> addWeight({
    required double weightKg,
    required DateTime date,
    required String idempotencyKey,
  }) => guardApi(
    () => _tracking.addWeight(
      idempotencyKey: idempotencyKey,
      addWeightRequest: AddWeightRequest(weightKg: weightKg, date: date),
    ),
  );

  @override
  Future<WeightOverview> deleteWeight(String id) =>
      guardApi(() => _tracking.deleteWeight(id: id));
}

final Provider<TrackingRepository> trackingRepositoryProvider = Provider((
  ref,
) {
  final api = ref.watch(omeoApiProvider);
  return TrackingApiRepository(api.getHomeApi(), api.getTrackingApi());
});
