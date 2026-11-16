import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:omeo/app/navigation/app_shell.dart';
import 'package:omeo/app/navigation/feature_routes.dart';
import 'package:omeo/features/activity/activity_paths.dart';
import 'package:omeo/features/meals/meals_paths.dart';
import 'package:omeo/features/meals/meals_routes.dart';
import 'package:omeo/features/subscription/subscription_paths.dart';
import 'package:omeo/features/tracking/application/tracking_controllers.dart';
import 'package:omeo/features/tracking/presentation/home_screen.dart';
import 'package:omeo/features/tracking/presentation/journal_screen.dart';
import 'package:omeo/features/tracking/presentation/progress_screen.dart';
import 'package:omeo/features/tracking/presentation/weight_screen.dart';
import 'package:omeo/features/tracking/tracking_paths.dart';
import 'package:omeo_api/omeo_api.dart' show HomeShortcutsEnum;

/// Routes du module de suivi : onglets Accueil, Journal et Progression.
FeatureRoutes trackingRoutes(Ref ref) => FeatureRoutes(
  tabs: {
    AppTab.home: [
      GoRoute(
        path: TrackingPaths.home,
        builder: (context, state) => HomeScreen(
          unreadNotifications: 0,
          // Chaque destination est branchée par le module qui la fournit.
          navigation: (
            openHelp: null,
            openNotifications: null,
            quickAction: (action) => mealQuickAction(context, action),
            openJournal: (date) {
              ref.read(journalDayProvider.notifier).select(date);
              context.go(TrackingPaths.journal);
            },
            openShortcut: (shortcut) {
              final path = switch (shortcut) {
                HomeShortcutsEnum.sport => ActivityPaths.sport,
                // Nutrition (journal), recettes et plantes : branchés par
                // leurs modules.
                _ => null,
              };
              if (path != null) unawaited(context.push(path));
            },
            openProgram: null,
            openChallenge: null,
            openRewards: null,
          ),
        ),
      ),
    ],
    AppTab.journal: [
      GoRoute(
        path: TrackingPaths.journal,
        builder: (context, state) {
          final date = DateTime.tryParse(
            state.uri.queryParameters['date'] ?? '',
          );
          if (date != null) {
            scheduleMicrotask(
              () => ref.read(journalDayProvider.notifier).select(date),
            );
          }
          final addMeal = AddMealAction.of(context);
          return JournalScreen(
            navigation: (
              addMeal: addMeal == null ? null : (_) => addMeal(context),
              openMeal: (meal) => context.push(MealsPaths.mealOf(meal.id)),
            ),
          );
        },
      ),
    ],
    AppTab.progress: [
      GoRoute(
        path: TrackingPaths.progress,
        builder: (context, state) => ProgressScreen(
          navigation: (
            discoverPlus: () => context.push(SubscriptionPaths.plus),
            scanMeal: () => context.push(MealsPaths.camera),
            connectHealth: () => context.push(TrackingPaths.healthPermission),
            openWeight: () => context.push(TrackingPaths.weight),
          ),
        ),
      ),
    ],
  },
  routes: [
    GoRoute(
      path: TrackingPaths.weight,
      builder: (context, state) => const WeightScreen(),
    ),
    GoRoute(
      path: TrackingPaths.healthPermission,
      builder: (context, state) => HealthPermissionScreen(onDone: context.pop),
    ),
  ],
);
