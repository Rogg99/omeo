import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:omeo/app/navigation/feature_routes.dart';
import 'package:omeo/features/subscription/subscription_paths.dart';
import 'package:omeo/features/training/presentation/exercise_screen.dart';
import 'package:omeo/features/training/presentation/session_screen.dart';
import 'package:omeo/features/training/presentation/training_catalog_screen.dart';
import 'package:omeo/features/training/presentation/workout_screen.dart';
import 'package:omeo/features/training/training_paths.dart';

/// Routes du module des séances.
FeatureRoutes trainingRoutes(Ref ref) => FeatureRoutes(
  routes: [
    GoRoute(
      path: TrainingPaths.catalog,
      builder: (context, state) => TrainingCatalogScreen(
        onBack: context.pop,
        onWorkout: (w) =>
            unawaited(context.push(TrainingPaths.workoutOf(w.id))),
        onExercise: (e) =>
            unawaited(context.push(TrainingPaths.exerciseOf(e.id))),
      ),
      routes: [
        GoRoute(
          path: 'workouts/:id',
          builder: (context, state) => WorkoutScreen(
            workoutId: state.pathParameters['id']!,
            navigation: (
              onBack: context.pop,
              onStart: (w) =>
                  unawaited(context.push(TrainingPaths.sessionOf(w.id))),
              onLocked: () => unawaited(context.push(SubscriptionPaths.plus)),
            ),
          ),
          routes: [
            GoRoute(
              path: 'play',
              builder: (context, state) => SessionScreen(
                workoutId: state.pathParameters['id']!,
                navigation: (onQuit: context.pop, onDone: context.pop),
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'exercises/:id',
          builder: (context, state) => ExerciseScreen(
            exerciseId: state.pathParameters['id']!,
            onBack: context.pop,
          ),
        ),
      ],
    ),
  ],
);
