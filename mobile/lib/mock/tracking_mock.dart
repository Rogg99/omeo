import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_riverpod/misc.dart';
import 'package:omeo/features/tracking/data/health.dart';
import 'package:omeo/features/tracking/data/home_repository.dart';
import 'package:omeo/features/tracking/data/tracking_repository.dart';
import 'package:omeo/mock/fixtures/tracking_fixtures.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/mock_backend_provider.dart';
import 'package:omeo/mock/repositories/home_mock_repository.dart';
import 'package:omeo_api/omeo_api.dart';

DateTime _today() => DateUtils.dateOnly(DateTime.now());

/// Clé de la connexion santé dans l'état du faux serveur.
const healthConnectedKey = 'tracking.health';

/// Journal, progression et poids simulés. Les écritures (eau, pesées) sont
/// gardées en mémoire pendant la session.
final class TrackingMockRepository implements TrackingRepository {
  TrackingMockRepository(this._backend);

  final MockBackend _backend;

  static const _waterKey = 'tracking.water';
  static const _weightsKey = 'tracking.weights';

  bool get _emptyScenario =>
      _backend.scenario == MockScenario.emptyDay ||
      _backend.scenario == MockScenario.firstLaunch;

  Map<DateTime, int> get _water =>
      (_backend.state[_waterKey] ??= <DateTime, int>{}) as Map<DateTime, int>;

  List<Map<String, Object?>> get _weights =>
      (_backend.state[_weightsKey] ??= _emptyScenario
              ? <Map<String, Object?>>[]
              : weightSeriesFixture(_today()))
          as List<Map<String, Object?>>;

  @override
  Future<DayDetail> getDay(DateTime date) => _backend.call(() {
    final day = DateUtils.dateOnly(date);
    final today = _today();
    // Hier reste vide pour montrer la journée sans saisie (HIS-04).
    final empty =
        _emptyScenario || day == today.subtract(const Duration(days: 1));
    return dayDetailFixture(
      day,
      today: today,
      empty: empty,
      waterMl: _water[day] ?? (empty ? 0 : defaultWaterMl),
    );
  });

  @override
  Future<List<GetCalendar200ResponseInner>> getCalendar(DateTime month) =>
      _backend.call(() => calendarFixture(month, today: _today()));

  @override
  Future<AddWater201Response> addWater({
    required int amountMl,
    required DateTime date,
    required String idempotencyKey,
  }) => _backend.call(() {
    final day = DateUtils.dateOnly(date);
    final current = _water[day] ?? (_emptyScenario ? 0 : defaultWaterMl);
    final next = (current + amountMl).clamp(0, 10000);
    _water[day] = next;
    return addWaterFixture(day, next);
  });

  @override
  Future<Progress> getProgress(ProgressMetric metric, ProgressRange range) =>
      _backend.call(
        () => progressFixture(
          metric.name,
          range.value,
          today: _today(),
          empty: _emptyScenario,
          healthConnected: _backend.state[healthConnectedKey] == true,
        ),
      );

  @override
  Future<WeightOverview> getWeights(WeightRange range) =>
      _backend.call(() => weightOverviewFixture(_weights));

  @override
  Future<AddWeight201Response> addWeight({
    required double weightKg,
    required DateTime date,
    required String idempotencyKey,
  }) => _backend.call(() {
    final day = date.toIso8601String().substring(0, 10);
    // Même jour : la saisie manuelle remplace la mesure existante.
    _weights
      ..removeWhere((w) => w['date'] == day)
      ..add({
        'id': 'b0c0d0e0-1111-4000-8000-${idempotencyKey.substring(24)}',
        'date': day,
        'weight_kg': (weightKg * 10).round() / 10,
        'source': 'manual',
      })
      ..sort((a, b) => (a['date']! as String).compareTo(b['date']! as String));
    return addWeightFixture(weightOverviewFixture(_weights));
  });

  @override
  Future<WeightOverview> deleteWeight(String id) => _backend.call(() {
    _weights.removeWhere((w) => w['id'] == id);
    return weightOverviewFixture(_weights);
  });
}

/// Connexion santé déclarée au faux serveur.
final class HealthMockRepository implements HealthRepository {
  const HealthMockRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<HealthConnection> connect({
    required SetHealthConnectionRequestSource_Enum source,
    required Set<HealthType> granted,
  }) => _backend.call(() {
    _backend.state[healthConnectedKey] = true;
    return HealthConnection(
      connected: true,
      source_: HealthConnectionSource_Enum.healthConnect,
      grantedTypes: [for (final g in granted) g.value],
      lastSyncAt: DateTime.now().toUtc(),
    );
  });

  @override
  Future<void> disconnect() =>
      _backend.call(() => _backend.state.remove(healthConnectedKey));
}

/// Fausse autorisation santé : accorde tout ce qui est demandé.
final class FakeHealthAccess implements HealthAccess {
  const FakeHealthAccess();

  @override
  SetHealthConnectionRequestSource_Enum get source =>
      SetHealthConnectionRequestSource_Enum.healthConnect;

  @override
  Future<Set<HealthType>> requestRead(Set<HealthType> types) async => types;
}

/// Dépôts simulés du module de suivi.
List<Override> trackingMockOverrides() => [
  homeRepositoryProvider.overrideWith(
    (ref) => HomeMockRepository(ref.watch(mockBackendProvider)),
  ),
  trackingRepositoryProvider.overrideWith(
    (ref) => TrackingMockRepository(ref.watch(mockBackendProvider)),
  ),
  healthRepositoryProvider.overrideWith(
    (ref) => HealthMockRepository(ref.watch(mockBackendProvider)),
  ),
  healthAccessProvider.overrideWithValue(const FakeHealthAccess()),
];
