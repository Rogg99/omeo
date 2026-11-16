import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/mock/fixtures/activity_fixtures.dart';
import 'package:omeo/mock/fixtures/training_fixtures.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/training_mock_repository.dart';
import 'package:omeo_api/omeo_api.dart';

void main() {
  late MockBackend backend;
  late TrainingMockRepository repo;

  setUp(() {
    backend = MockBackend(latency: Duration.zero, scenario: MockScenario.free);
    repo = TrainingMockRepository(backend);
  });

  test('Free : contenus Plus visibles mais verrouillés', () async {
    final workouts = await repo.listWorkouts(
      (goal: null, level: null, maxMinutes: null),
    );
    expect(workouts, hasLength(4));
    expect(
      workouts.firstWhere((w) => w.id == cardioSansMaterielId).locked,
      isTrue,
    );
    final exercises = await repo.listExercises(
      (muscle: null, level: null, equipment: null),
    );
    expect(exercises.where((e) => e.locked), hasLength(2));
  });

  test('filtres : durée maximale et but', () async {
    final short = await repo.listWorkouts(
      (goal: null, level: null, maxMinutes: 15),
    );
    expect(short.map((w) => w.durationS), everyElement(lessThanOrEqualTo(900)));
    final cardio = await repo.listWorkouts(
      (goal: 'cardio', level: null, maxMinutes: null),
    );
    expect(
      cardio.map((w) => w.goal),
      everyElement(WorkoutSummaryGoalEnum.cardio),
    );
  });

  test('séance : enchaînement en deux tours, avec repos et mode', () async {
    final w = await repo.getWorkout(cardioSansMaterielId);
    expect(w.steps, hasLength(8));
    expect(w.steps.first.mode, WorkoutDetailAllOfStepsModeEnum.time);
    expect(w.steps[1].reps, 15);
    expect(w.steps.first.exercise.video.hlsUrl, endsWith('.m3u8'));
  });

  test('téléchargement réservé à Plus', () async {
    expect(
      repo.getWorkoutDownload(reveilMobiliteId),
      throwsA(
        isA<ProblemFailure>().having(
          (f) => f.code,
          'code',
          ProblemCodes.planRequired,
        ),
      ),
    );
    backend.scenario = MockScenario.plus;
    final d = await repo.getWorkoutDownload(reveilMobiliteId);
    expect(d.files, isNotEmpty);
  });

  test('fin de séance : idempotente, points et calories de l’API', () async {
    final request = CompleteWorkoutSessionRequest(
      workoutId: cardioSansMaterielId,
      startedAt: DateTime(2026, 11, 16, 7),
      endedAt: DateTime(2026, 11, 16, 7, 21, 14),
      completedSteps: 8,
    );
    final a = await repo.completeSession(request, idempotencyKey: 'k');
    final b = await repo.completeSession(request, idempotencyKey: 'k');
    expect(a.id, b.id);
    expect(a.durationS, 1274);
    expect((a.kcal, a.rewards.points), (196, 30));
  });

  test('fiche introuvable : 404', () {
    expect(
      repo.getExercise('inconnu'),
      throwsA(isA<ProblemFailure>().having((f) => f.status, 'status', 404)),
    );
    expect(exerciseFixture(squatId, plus: false)?.name, 'Squat');
  });
}
