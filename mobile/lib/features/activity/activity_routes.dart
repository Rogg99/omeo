import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:omeo/app/navigation/feature_routes.dart';
import 'package:omeo/features/activity/activity_paths.dart';
import 'package:omeo/features/activity/presentation/add_activity_screen.dart';
import 'package:omeo/features/activity/presentation/sport_screen.dart';
import 'package:omeo/features/activity/presentation/week_screen.dart';
import 'package:omeo/features/training/training_paths.dart';

/// Routes du module activité.
FeatureRoutes activityRoutes(Ref ref) => FeatureRoutes(
  routes: [
    GoRoute(
      path: ActivityPaths.sport,
      builder: (context, state) => SportScreen(
        navigation: (
          onBack: context.pop,
          onAddActivity: () => unawaited(context.push(ActivityPaths.add)),
          onWeek: () => unawaited(context.push(ActivityPaths.week)),
          onWorkout: (w) =>
              unawaited(context.push(TrainingPaths.workoutOf(w.id))),
          onAllWorkouts: () => unawaited(context.push(TrainingPaths.catalog)),
        ),
      ),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => AddActivityScreen(
            onClose: context.pop,
            onSaved: (_) => context.pop(),
          ),
        ),
        GoRoute(
          path: 'week',
          builder: (context, state) => WeekBalanceScreen(
            onBack: context.pop,
            onInsights: () => unawaited(context.push(ActivityPaths.insights)),
          ),
        ),
        GoRoute(
          path: 'insights',
          builder: (context, state) => InsightsScreen(onBack: context.pop),
        ),
      ],
    ),
  ],
);
