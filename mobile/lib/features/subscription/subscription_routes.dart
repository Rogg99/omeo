import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:omeo/app/navigation/feature_routes.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/core/config/app_config.dart';
import 'package:omeo/core/platform/external_links.dart';
import 'package:omeo/features/subscription/data/subscription_repository.dart';
import 'package:omeo/features/subscription/presentation/payments_screen.dart';
import 'package:omeo/features/subscription/presentation/paywall_screen.dart';
import 'package:omeo/features/subscription/presentation/subscription_screen.dart';
import 'package:omeo/features/subscription/subscription_paths.dart';

/// Page des abonnements du store de l'appareil.
Uri _storeSubscriptionsUri() => defaultTargetPlatform == TargetPlatform.iOS
    ? Uri.parse('https://apps.apple.com/account/subscriptions')
    : Uri.parse('https://play.google.com/store/account/subscriptions');

/// Routes du module abonnement et parrainage.
FeatureRoutes subscriptionRoutes(Ref ref) {
  // Abonnement pris sur le site : portail de paiement ouvert dans le
  // navigateur.
  Future<void> manageOnWeb() async {
    try {
      final url = await ref
          .read(subscriptionRepositoryProvider)
          .billingPortalUrl(returnUrl: '${AppConfig.websiteUrl}/compte');
      await openExternal(Uri.parse(url));
    } on ApiFailure catch (e) {
      ref.read(globalErrorBusProvider).report(e);
    }
  }

  return FeatureRoutes(
    routes: [
      GoRoute(
        path: SubscriptionPaths.plus,
        builder: (context, state) =>
            PaywallScreen(onClose: context.pop, onSubscribed: context.pop),
      ),
      GoRoute(
        path: SubscriptionPaths.subscription,
        builder: (context, state) => SubscriptionScreen(
          navigation: (
            onBack: context.pop,
            onPayments: () =>
                unawaited(context.push(SubscriptionPaths.payments)),
            onDiscoverPlus: () =>
                unawaited(context.push(SubscriptionPaths.plus)),
            onReferral: null,
            onManageStore: () =>
                unawaited(openExternal(_storeSubscriptionsUri())),
            onManageWeb: () => unawaited(manageOnWeb()),
          ),
        ),
        routes: [
          GoRoute(
            path: 'payments',
            builder: (context, state) => PaymentsScreen(
              onBack: context.pop,
              onReceipt: (uri) => unawaited(openExternal(uri)),
            ),
          ),
        ],
      ),
    ],
  );
}
