/// Chemins du module des séances (liens profonds compris).
abstract final class TrainingPaths {
  /// Bibliothèque : séances guidées (EXO-03) et exercices (EXO-01).
  static const catalog = '/training';
  static const workout = '/training/workouts/:id';
  static const session = '/training/workouts/:id/play';
  static const exercise = '/training/exercises/:id';

  static String workoutOf(String id) => '/training/workouts/$id';

  static String sessionOf(String id) => '/training/workouts/$id/play';

  static String exerciseOf(String id) => '/training/exercises/$id';
}
