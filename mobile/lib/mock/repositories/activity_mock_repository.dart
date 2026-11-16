import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/features/activity/data/activity_repository.dart';
import 'package:omeo/mock/fixtures/activity_fixtures.dart';
import 'package:omeo/mock/fixtures/meals_fixtures.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo_api/omeo_api.dart';
import 'package:uuid/uuid.dart';

/// État de session de l'activité simulée.
final class _ActivityState {
  bool connected = false;
  DateTime? lastSyncAt;
  List<Map<String, Object?>>? activities;
  final Map<String, ActivityWriteResult> writes = {};
}

/// Activité simulée. La lecture de Health Connect et HealthKit reste réelle :
/// seul l'envoi des totaux (POST /me/health/sync) est simulé, et renvoie des
/// jours recalculés d'exemple, avec la fusion proposée (SPO-03).
final class ActivityMockRepository implements ActivityRepository {
  ActivityMockRepository(this._backend);

  final MockBackend _backend;
  static const _uuid = Uuid();

  _ActivityState get _s =>
      (_backend.state['activity'] ??= _ActivityState()) as _ActivityState;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get _plus => _backend.scenario == MockScenario.plus;

  List<Map<String, Object?>> get _activities =>
      _s.activities ??= todayActivitiesJson(_today);

  DaySummary _day() => mealWriteFixture(
    mealId: 'day',
    title: '',
    now: DateTime.now(),
    input: MealInput(
      source_: MealInputSource_Enum.foods,
      mealType: MealType.lunch,
    ),
  ).day;

  @override
  Future<ActivityOverview> getOverview({DateTime? date}) => _backend.call(
    () => activityOverviewFixture(
      today: _today,
      connected: _s.connected,
      plus: _plus,
      empty:
          _backend.scenario == MockScenario.emptyDay ||
          _backend.scenario == MockScenario.firstLaunch,
      activities: _activities,
      lastSyncAt: _s.lastSyncAt,
    ),
  );

  /// Estimation simulée des calories (calcul toléré dans lib/mock/).
  static int _estimate(ActivityInput input) {
    final perMinute = switch (input.intensity) {
      ActivityInputIntensityEnum.light => 4,
      ActivityInputIntensityEnum.moderate => 9,
      ActivityInputIntensityEnum.vigorous => 12,
    };
    return perMinute * input.durationS ~/ 60;
  }

  @override
  Future<ActivityWriteResult> createActivity(
    ActivityInput input, {
    required String idempotencyKey,
  }) => _backend.call(() {
    final existing = _s.writes[idempotencyKey];
    if (existing != null) return existing;
    final started = input.startedAt ?? DateTime.now();
    final json = <String, Object?>{
      'id': _uuid.v4(),
      'date': started.toIso8601String().substring(0, 10),
      'type': input.type.value,
      'label': ?input.label,
      'started_at': started.toUtc().toIso8601String(),
      'duration_s': input.durationS,
      'intensity': input.intensity.value,
      'kcal': _estimate(input),
      'source': 'manual',
      'editable': true,
    };
    _activities.add(json);
    return _s.writes[idempotencyKey] = ActivityWriteResult.fromJson({
      'activity': json,
      'day': _day().toJson(),
      'rewards': {'points': 5},
    });
  });

  @override
  Future<ActivityWriteResult> mergeActivity(
    String manualId, {
    required String intoId,
  }) => _backend.call(() {
    _activities.removeWhere((a) => a['id'] == manualId);
    final kept = _activities.firstWhere(
      (a) => a['id'] == intoId,
      orElse: () => throw const ProblemFailure(status: 404, code: 'not_found'),
    );
    return ActivityWriteResult.fromJson({
      'activity': kept,
      'day': _day().toJson(),
      'rewards': {'points': 0},
    });
  });

  @override
  Future<void> deleteActivity(String id) =>
      _backend.call(() => _activities.removeWhere((a) => a['id'] == id));

  @override
  Future<HealthConnection> setHealthConnection(
    SetHealthConnectionRequest request,
  ) => _backend.call(() {
    _s.connected = request.grantedTypes.isNotEmpty;
    return HealthConnection.fromJson({
      'connected': _s.connected,
      'source': request.source_.value,
      'granted_types': [for (final t in request.grantedTypes) t.value],
    });
  });

  @override
  Future<SyncHealth200Response> syncHealth(
    HealthSyncInput input, {
    required String idempotencyKey,
  }) => _backend.call(() {
    _s
      ..connected = true
      ..lastSyncAt = DateTime.now();
    // Une séance importée chevauche le football saisi : fusion proposée.
    final manual = _activities.where(
      (a) => a['id'] == footballId && a['source'] == 'manual',
    );
    final hasImported = _activities.any((a) => a['id'] == importedFootballId);
    final suggest = manual.isNotEmpty && !hasImported;
    if (suggest) _activities.add(importedFootballJson(_today));
    return SyncHealth200Response.fromJson({
      'days': [_day().toJson()],
      'merge_suggestions': [
        if (suggest)
          {
            'manual_id': footballId,
            'imported_id': importedFootballId,
            'message':
                'Health Connect a importé une séance qui chevauche celle que '
                'tu as saisie.',
          },
      ],
      'rewards': {'points': 0},
      'last_sync_at': _s.lastSyncAt!.toUtc().toIso8601String(),
    });
  });

  @override
  Future<List<Insight>> listInsights() => _backend.call(() {
    if (!_plus) {
      throw const ProblemFailure(
        status: 403,
        code: ProblemCodes.planRequired,
        meta: {'feature': 'insights'},
      );
    }
    return insightsFixture(_today);
  });
}
