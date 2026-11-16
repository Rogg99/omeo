import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo_api/omeo_api.dart';

/// Filtres du catalogue de séances.
typedef WorkoutFilter = ({String? goal, Level? level, int? maxMinutes});

/// Filtres de la bibliothèque d'exercices.
typedef ExerciseFilter = ({String? muscle, Level? level, String? equipment});

/// Exercices et séances guidées (Free : une sélection ; Plus : tout, et le
/// téléchargement hors connexion).
abstract interface class TrainingRepository {
  Future<List<WorkoutSummary>> listWorkouts(WorkoutFilter filter);

  Future<WorkoutDetail> getWorkout(String id);

  Future<List<ExerciseSummary>> listExercises(ExerciseFilter filter);

  Future<ExerciseDetail> getExercise(String id);

  /// Fichiers vidéo à télécharger pour une séance (Plus).
  Future<GetWorkoutDownload200Response> getWorkoutDownload(String id);

  /// Fin de séance : l'API calcule la durée, les calories et les points.
  Future<CompleteWorkoutSession201Response> completeSession(
    CompleteWorkoutSessionRequest request, {
    required String idempotencyKey,
  });
}

/// Implémentation sur l'API réelle.
final class TrainingApiRepository implements TrainingRepository {
  const TrainingApiRepository(this._api);

  final TrainingApi _api;

  @override
  Future<List<WorkoutSummary>> listWorkouts(WorkoutFilter filter) async =>
      (await guardApi(
        () => _api.listWorkouts(
          goal: filter.goal,
          level: filter.level,
          maxMinutes: filter.maxMinutes,
        ),
      )).results;

  @override
  Future<WorkoutDetail> getWorkout(String id) =>
      guardApi(() => _api.getWorkout(id: id));

  @override
  Future<List<ExerciseSummary>> listExercises(ExerciseFilter filter) async =>
      (await guardApi(
        () => _api.listExercises(
          muscle: filter.muscle,
          level: filter.level,
          equipment: filter.equipment,
        ),
      )).results;

  @override
  Future<ExerciseDetail> getExercise(String id) =>
      guardApi(() => _api.getExercise(id: id));

  @override
  Future<GetWorkoutDownload200Response> getWorkoutDownload(String id) =>
      guardApi(() => _api.getWorkoutDownload(id: id));

  @override
  Future<CompleteWorkoutSession201Response> completeSession(
    CompleteWorkoutSessionRequest request, {
    required String idempotencyKey,
  }) => guardApi(
    () => _api.completeWorkoutSession(
      idempotencyKey: idempotencyKey,
      completeWorkoutSessionRequest: request,
    ),
  );
}

/// Dépôt des séances. Le flavor mock le remplace par sa version simulée.
final trainingRepositoryProvider = Provider<TrainingRepository>(
  (ref) => TrainingApiRepository(ref.watch(omeoApiProvider).getTrainingApi()),
);
