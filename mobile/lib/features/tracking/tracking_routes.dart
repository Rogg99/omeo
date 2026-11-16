import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:omeo/app/navigation/feature_routes.dart';
import 'package:omeo/features/activity/activity_paths.dart';
import 'package:omeo/features/meals/meals_routes.dart';
import 'package:omeo/features/tracking/presentation/home_screen.dart';
import 'package:omeo/features/tracking/tracking_paths.dart';
import 'package:omeo_api/omeo_api.dart' show HomeShortcutsEnum;

/// Routes du module de suivi : onglet Accueil.
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
            openJournal: null,
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
  },
);
