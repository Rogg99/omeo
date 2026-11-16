import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/features/training/data/training_repository.dart';
import 'package:omeo/mock/fixtures/meals_fixtures.dart';
import 'package:omeo/mock/fixtures/training_fixtures.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo_api/omeo_api.dart';
import 'package:uuid/uuid.dart';

/// Séances simulées : Free voit les contenus Plus verrouillés, Plus peut
/// tout lancer et télécharger.
final class TrainingMockRepository implements TrainingRepository {
  TrainingMockRepository(this._backend);

  final MockBackend _backend;
  static const _uuid = Uuid();
  final _sessions = <String, CompleteWorkoutSession201Response>{};

  bool get _plus => _backend.scenario == MockScenario.plus;

  static const _notFound = ProblemFailure(status: 404, code: 'not_found');
  static const _planRequired = ProblemFailure(
    status: 403,
    code: ProblemCodes.planRequired,
    meta: {'feature': 'workouts'},
  );

  @override
  Future<List<WorkoutSummary>> listWorkouts(WorkoutFilter filter) =>
      _backend.call(
        () => [
          for (final w in workoutsFixture(plus: _plus))
            if ((filter.goal == null || w.goal.value == filter.goal) &&
                (filter.level == null || w.level == filter.level) &&
                (filter.maxMinutes == null ||
                    w.durationS <= filter.maxMinutes! * 60))
              w,
        ],
      );

  @override
  Future<WorkoutDetail> getWorkout(String id) => _backend.call(() {
    final w = workoutFixture(id, plus: _plus);
    if (w == null) throw _notFound;
    return w;
  });

  @override
  Future<List<ExerciseSummary>> listExercises(ExerciseFilter filter) =>
      _backend.call(
        () => [
          for (final e in exercisesFixture(plus: _plus))
            if ((filter.level == null || e.level == filter.level) &&
                (filter.muscle == null ||
                    (e.muscles ?? const []).contains(filter.muscle)))
              e,
        ],
      );

  @override
  Future<ExerciseDetail> getExercise(String id) => _backend.call(() {
    final e = exerciseFixture(id, plus: _plus);
    if (e == null) throw _notFound;
    return e;
  });

  @override
  Future<GetWorkoutDownload200Response> getWorkoutDownload(String id) =>
      _backend.call(() {
        if (!_plus) throw _planRequired;
        final w = workoutFixture(id, plus: true);
        if (w == null) throw _notFound;
        return GetWorkoutDownload200Response.fromJson({
          'expires_at': DateTime.now()
              .toUtc()
              .add(const Duration(hours: 1))
              .toIso8601String(),
          'files': [
            for (final s in w.steps)
              {
                'exercise_id': s.exercise.id,
                'url': s.exercise.video.hlsUrl,
                'size': 2400000,
              },
          ],
        });
      });

  @override
  Future<CompleteWorkoutSession201Response> completeSession(
    CompleteWorkoutSessionRequest request, {
    required String idempotencyKey,
  }) => _backend.call(
    () => _sessions[idempotencyKey] ??= sessionFixture(
      id: _uuid.v4(),
      request: request,
      day: mealWriteFixture(
        mealId: 'day',
        title: '',
        now: DateTime.now(),
        input: MealInput(
          source_: MealInputSource_Enum.program,
          mealType: MealType.lunch,
        ),
      ).day,
    ),
  );
}
