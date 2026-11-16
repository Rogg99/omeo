import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:omeo/app/navigation/app_shell.dart';
import 'package:omeo/app/navigation/feature_routes.dart';
import 'package:omeo/features/auth/auth_routes.dart';
import 'package:omeo/features/meals/meals_routes.dart';
import 'package:omeo/features/onboarding/onboarding_routes.dart';
import 'package:omeo/features/subscription/subscription_routes.dart';
import 'package:omeo/features/support/support_routes.dart';
import 'package:omeo/features/tracking/tracking_paths.dart';
import 'package:omeo/features/tracking/tracking_routes.dart';

/// Modules qui contribuent à la navigation : une ligne par module.
final List<FeatureRoutesBuilder> _modules = [
  authRoutes,
  onboardingRoutes,
  trackingRoutes,
  supportRoutes,
  mealsRoutes,
  subscriptionRoutes,
];

final routerProvider = Provider<GoRouter>((ref) {
  final modules = [for (final build in _modules) build(ref)];
  final branchTabs = [
    for (final tab in AppTab.values)
      if (modules.any((m) => m.tabs.containsKey(tab))) tab,
  ];
  final onAddMeal = modules
      .map((m) => m.onAddMeal)
      .firstWhere((f) => f != null, orElse: () => null);

  final router = GoRouter(
    initialLocation: TrackingPaths.home,
    refreshListenable: Listenable.merge([
      for (final m in modules) ?m.refresh,
    ]),
    redirect: (context, state) {
      for (final m in modules) {
        final target = m.redirect?.call(context, state);
        if (target != null) return target;
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(
          navigationShell: shell,
          branchTabs: branchTabs,
          onAddMeal: onAddMeal,
          banners: [
            for (final m in modules) ?m.shellBanner,
          ],
        ),
        branches: [
          for (final tab in branchTabs)
            StatefulShellBranch(
              routes: [for (final m in modules) ...?m.tabs[tab]],
            ),
        ],
      ),
      for (final m in modules) ...m.routes,
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
