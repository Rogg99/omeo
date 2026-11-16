import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/mock/fixtures/activity_fixtures.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/activity_mock_repository.dart';
import 'package:omeo_api/omeo_api.dart';

void main() {
  late MockBackend backend;
  late ActivityMockRepository repo;

  setUp(() {
    backend = MockBackend(latency: Duration.zero);
    repo = ActivityMockRepository(backend);
  });

  test('aperçu du jour : pas, balance et activités avec leur source', () async {
    final o = await repo.getOverview();
    expect(o.steps.value, 6420);
    expect(o.balanceDay.differenceKcal, -1160);
    expect(o.activities.map((a) => a.source_), [
      ActivitySource_Enum.healthConnect,
      ActivitySource_Enum.manual,
    ]);
    expect(o.health.connected, isFalse);
  });

  test('journée vide : état vide réel', () async {
    backend.setScenario(MockScenario.emptyDay);
    final o = await repo.getOverview();
    expect(o.activities, isEmpty);
    expect(o.steps.value, 0);
  });

  test('saisie manuelle : calories estimées, idempotente', () async {
    final input = ActivityInput(
      type: ActivityInputTypeEnum.walking,
      durationS: 1800,
      intensity: ActivityInputIntensityEnum.light,
    );
    final a = await repo.createActivity(input, idempotencyKey: 'k');
    final b = await repo.createActivity(input, idempotencyKey: 'k');
    expect(a.activity.id, b.activity.id);
    expect(a.activity.kcal, greaterThan(0));
    expect((await repo.getOverview()).activities, hasLength(3));
  });

  test('synchronisation : séance qui chevauche, puis fusion', () async {
    final sync = await repo.syncHealth(
      HealthSyncInput(
        source_: HealthSyncInputSource_Enum.healthConnect,
        days: [HealthSyncInputDaysInner(date: DateTime(2026, 11, 16))],
      ),
      idempotencyKey: 'k',
    );
    final suggestion = sync.mergeSuggestions.single;
    expect(suggestion.manualId, footballId);
    expect((await repo.getOverview()).health.connected, isTrue);

    await repo.mergeActivity(
      suggestion.manualId,
      intoId: suggestion.importedId,
    );
    final ids = (await repo.getOverview()).activities.map((a) => a.id);
    expect(ids, isNot(contains(footballId)));
    expect(ids, contains(importedFootballId));
  });

  test('analyses croisées réservées à Plus', () async {
    expect(
      repo.listInsights(),
      throwsA(
        isA<ProblemFailure>().having(
          (f) => f.code,
          'code',
          ProblemCodes.planRequired,
        ),
      ),
    );
    backend.setScenario(MockScenario.plus);
    expect(await repo.listInsights(), hasLength(3));
  });
}
