import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/features/training/data/training_repository.dart';
import 'package:omeo_api/omeo_api.dart';
import 'package:path_provider/path_provider.dart';

/// Séances filtrées (EXO-03).
// Le type d'une famille de providers n'est pas exporté par Riverpod 3.
// ignore: specify_nonobvious_property_types
final workoutsProvider = FutureProvider.autoDispose
    .family<List<WorkoutSummary>, WorkoutFilter>(
      (ref, filter) =>
          ref.watch(trainingRepositoryProvider).listWorkouts(filter),
    );

/// Exercices filtrés (EXO-01).
// ignore: specify_nonobvious_property_types
final exercisesProvider = FutureProvider.autoDispose
    .family<List<ExerciseSummary>, ExerciseFilter>(
      (ref, filter) =>
          ref.watch(trainingRepositoryProvider).listExercises(filter),
    );

/// Détail d'une séance (EXO-04).
// ignore: specify_nonobvious_property_types
final workoutProvider = FutureProvider.autoDispose
    .family<WorkoutDetail, String>(
      (ref, id) => ref.watch(trainingRepositoryProvider).getWorkout(id),
    );

/// Fiche d'un exercice (EXO-02).
// ignore: specify_nonobvious_property_types
final exerciseProvider = FutureProvider.autoDispose
    .family<ExerciseDetail, String>(
      (ref, id) => ref.watch(trainingRepositoryProvider).getExercise(id),
    );

/// Vidéos téléchargées pour le hors connexion (Plus), une par exercice.
abstract interface class WorkoutDownloads {
  /// Fichier local de la vidéo d'un exercice, s'il a été téléchargé.
  Future<File?> localVideo(String exerciseId);

  Future<bool> isDownloaded(WorkoutDetail workout);

  /// Télécharge les fichiers fournis par l'API (URL signées, durée limitée).
  Future<void> download(String workoutId);
}

/// Téléchargements dans le dossier de l'app (jamais dans la galerie).
final class FileWorkoutDownloads implements WorkoutDownloads {
  FileWorkoutDownloads(this._repo, {Dio? storage})
    : _storage = storage ?? Dio();

  final TrainingRepository _repo;

  /// Client nu : les URL signées ne reçoivent aucun en-tête de l'app.
  final Dio _storage;

  Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/workouts');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _file(String exerciseId) async =>
      File('${(await _dir()).path}/$exerciseId.video');

  @override
  Future<File?> localVideo(String exerciseId) async {
    final file = await _file(exerciseId);
    return file.existsSync() ? file : null;
  }

  @override
  Future<bool> isDownloaded(WorkoutDetail workout) async {
    for (final step in workout.steps) {
      if (await localVideo(step.exercise.id) == null) return false;
    }
    return workout.steps.isNotEmpty;
  }

  @override
  Future<void> download(String workoutId) async {
    final manifest = await _repo.getWorkoutDownload(workoutId);
    for (final f in manifest.files) {
      final target = await _file(f.exerciseId);
      if (target.existsSync() && target.lengthSync() == f.size) continue;
      final partial = File('${target.path}.part');
      try {
        await _storage.download(f.url, partial.path);
        await partial.rename(target.path);
      } on DioException catch (e) {
        if (partial.existsSync()) await partial.delete();
        throw failureFromDio(e);
      }
    }
  }
}

final Provider<WorkoutDownloads> workoutDownloadsProvider = Provider(
  (ref) => FileWorkoutDownloads(ref.watch(trainingRepositoryProvider)),
);

/// La séance est-elle disponible hors connexion ?
// ignore: specify_nonobvious_property_types
final workoutDownloadedProvider = FutureProvider.autoDispose
    .family<bool, WorkoutDetail>(
      (ref, workout) =>
          ref.watch(workoutDownloadsProvider).isDownloaded(workout),
    );

/// Télécharge une séance ; les refus de l'API passent par le bus global.
Future<void> downloadWorkout(Ref ref, String workoutId) async {
  try {
    await ref.read(workoutDownloadsProvider).download(workoutId);
  } on ApiFailure catch (e) {
    ref.read(globalErrorBusProvider).report(e);
    rethrow;
  }
}
