import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:omeo/app/navigation/feature_routes.dart';
import 'package:omeo/features/tracking/presentation/home_screen.dart';
import 'package:omeo/features/tracking/tracking_paths.dart';

/// Routes du module de suivi : onglet Accueil.
FeatureRoutes trackingRoutes(Ref ref) => FeatureRoutes(
  tabs: {
    AppTab.home: [
      GoRoute(
        path: TrackingPaths.home,
        builder: (context, state) => const HomeScreen(
          unreadNotifications: 0,
          // Chaque destination est branchée par le module qui la fournit.
          navigation: (
            openHelp: null,
            openNotifications: null,
            quickAction: null,
            openJournal: null,
            openShortcut: null,
            openProgram: null,
            openChallenge: null,
            openRewards: null,
          ),
        ),
      ),
    ],
  },
);
