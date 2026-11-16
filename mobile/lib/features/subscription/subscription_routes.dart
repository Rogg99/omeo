import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:omeo/app/navigation/feature_routes.dart';
import 'package:omeo/features/subscription/presentation/paywall_screen.dart';
import 'package:omeo/features/subscription/subscription_paths.dart';

/// Routes du module abonnement et parrainage.
FeatureRoutes subscriptionRoutes(Ref ref) => FeatureRoutes(
  routes: [
    GoRoute(
      path: SubscriptionPaths.plus,
      builder: (context, state) =>
          PaywallScreen(onClose: context.pop, onSubscribed: context.pop),
    ),
  ],
);
