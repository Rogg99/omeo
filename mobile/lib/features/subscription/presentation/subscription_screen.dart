import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/meals/application/quotas_controller.dart';
import 'package:omeo/features/subscription/application/subscription_controller.dart';
import 'package:omeo/features/subscription/data/store_billing.dart';
import 'package:omeo_api/omeo_api.dart'
    show
        Quota,
        QuotaFeatureEnum,
        SubscriptionState,
        SubscriptionStateCanManageEnum,
        SubscriptionStatus;

/// Destinations de « Mon abonnement », fournies par le routeur.
typedef SubscriptionNavigation = ({
  VoidCallback onBack,
  VoidCallback onPayments,
  VoidCallback onDiscoverPlus,
  VoidCallback? onReferral,

  /// Gestion dans le store (Google Play ou App Store).
  VoidCallback onManageStore,

  /// Gestion sur le site (portail de paiement).
  VoidCallback onManageWeb,
});

/// Nom du store de l'appareil, pour les libellés.
String storeName(AppLocalizations l) => l.appPlusPaywallStore(
  defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
);

/// Mon abonnement (PLS-04) et paiement en échec (PLS-05) : état calculé par
/// l'API, renouvellement, canal d'achat, quotas et paiements.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({required this.navigation, super.key});

  final SubscriptionNavigation navigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(subscriptionProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OmeoTopBar(
              title: l.appPlusSubscriptionTitle,
              backLabel: l.commonActionBack,
              onBack: navigation.onBack,
            ),
            Expanded(
              child: switch (state) {
                AsyncValue(:final value?) => RefreshIndicator(
                  onRefresh: () => ref.refresh(subscriptionProvider.future),
                  child: _Content(state: value, navigation: navigation),
                ),
                AsyncValue(:final error?) => EmptyState(
                  icon: OmeoIcons.alert,
                  title: l.appPlusSubscriptionErrorTitle,
                  message: failureMessage(l, error),
                  actionLabel: l.commonActionRetry,
                  onAction: () => ref.invalidate(subscriptionProvider),
                ),
                _ => const Center(child: OmeoSpinner()),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.state, required this.navigation});

  final SubscriptionState state;
  final SubscriptionNavigation navigation;

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final outcome = await ref.read(purchaseActionsProvider).restore();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            outcome == PurchaseOutcome.plus
                ? l.appPlusPaywallRestored
                : l.appPlusPaywallNothingRestored,
          ),
        ),
      );
    } on StoreBillingException {
      messenger.showSnackBar(
        SnackBar(content: Text(l.appPlusPaywallStoreError)),
      );
    } on ApiFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage(l, e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final sub = state.subscription;
    final grace = sub?.status == SubscriptionStatus.grace;
    final manage = state.canManage;
    final store = storeName(l);
    final photo = quotaFor(state.quotas, QuotaFeatureEnum.photoAnalysis);
    final voice = quotaFor(state.quotas, QuotaFeatureEnum.textAnalysis);
    final resetsAt = photo?.resetsAt ?? voice?.resetsAt;
    final granted = state.grantedDaysLeft ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: [
        if (grace) ...[
          OmeoBanner(
            icon: OmeoIcons.alert,
            tone: OmeoTone.danger,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${l.appPlusSubscriptionGraceTitle} ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: l.appPlusSubscriptionGraceBody(
                      MaterialLocalizations.of(
                        context,
                      ).formatFullDate(sub!.currentPeriodEnd.toLocal()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: OmeoTokens.space3),
        ],
        if (sub == null)
          OmeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.appPlusSubscriptionNoneTitle, style: text.titleMedium),
                const SizedBox(height: OmeoTokens.space1),
                Text(
                  l.appPlusSubscriptionNoneBody,
                  style: text.bodySmall?.copyWith(color: t.text2),
                ),
                const SizedBox(height: OmeoTokens.space4),
                OmeoButton(
                  label: l.commonPlusDiscover,
                  icon: OmeoIcons.sparkles,
                  size: OmeoButtonSize.medium,
                  onPressed: navigation.onDiscoverPlus,
                ),
              ],
            ),
          )
        else
          _PlanCard(
            state: state,
            grace: grace,
            onFix: manage == SubscriptionStateCanManageEnum.web
                ? navigation.onManageWeb
                : navigation.onManageStore,
          ),
        if (photo != null || voice != null) ...[
          const SizedBox(height: OmeoTokens.space6),
          SectionTitle(l.appPlusSubscriptionThisPeriod),
          const SizedBox(height: OmeoTokens.space3),
          OmeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photo != null)
                  _QuotaLine(label: l.appPlusSubscriptionQuotaPhoto, q: photo),
                if (photo != null && voice != null) const SizedBox(height: 14),
                if (voice != null && (voice.limit ?? 1) > 0)
                  _QuotaLine(label: l.appPlusSubscriptionQuotaText, q: voice),
                if (resetsAt != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    l.appPlusSubscriptionResets(
                      MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(resetsAt.toLocal()),
                    ),
                    style: text.labelSmall?.copyWith(color: t.text3),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: OmeoTokens.space4),
        OmeoList(
          children: [
            if (manage == SubscriptionStateCanManageEnum.store)
              OmeoListTile(
                icon: OmeoIcons.store,
                title: l.appPlusSubscriptionManageStore(store),
                subtitle: l.appPlusSubscriptionManageStoreHint,
                trailing: const OmeoIcon(OmeoIcons.arrowUR),
                showChevron: false,
                onTap: navigation.onManageStore,
              ),
            if (manage == SubscriptionStateCanManageEnum.web)
              OmeoListTile(
                icon: OmeoIcons.store,
                title: l.appPlusSubscriptionManageWeb,
                subtitle: l.appPlusSubscriptionManageStoreHint,
                trailing: const OmeoIcon(OmeoIcons.arrowUR),
                showChevron: false,
                onTap: navigation.onManageWeb,
              ),
            OmeoListTile(
              icon: OmeoIcons.receipt,
              title: l.appPlusSubscriptionPayments,
              onTap: navigation.onPayments,
            ),
            OmeoListTile(
              icon: OmeoIcons.refresh,
              title: l.appPlusSubscriptionRestore,
              showChevron: false,
              onTap: () => unawaited(_restore(context, ref)),
            ),
            if (granted > 0)
              OmeoListTile(
                icon: OmeoIcons.gift,
                title: l.appPlusSubscriptionGranted,
                subtitle: l.appPlusSubscriptionGrantedHint(granted),
                onTap: navigation.onReferral,
              ),
          ],
        ),
        const SizedBox(height: OmeoTokens.space4),
        Text(
          manage == SubscriptionStateCanManageEnum.web
              ? l.appPlusSubscriptionWebNote
              : l.appPlusSubscriptionCancelNote,
          style: text.labelSmall?.copyWith(color: t.text3),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.state,
    required this.grace,
    required this.onFix,
  });

  final SubscriptionState state;
  final bool grace;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final sub = state.subscription!;
    final channel = l.appPlusSubscriptionChannel(sub.channel.value);
    final date = MaterialLocalizations.of(
      context,
    ).formatFullDate(sub.currentPeriodEnd.toLocal());
    final price = sub.price?.formatted;
    final name = sub.planName ?? sub.planCode;

    if (grace) {
      return OmeoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                OmeoTag(
                  l.appPlusSubscriptionGraceTag,
                  tone: OmeoTone.warning,
                ),
                const Spacer(),
                Text(channel, style: text.bodySmall?.copyWith(color: t.text3)),
              ],
            ),
            const SizedBox(height: OmeoTokens.space3),
            Text(
              price == null ? name : '$name · $price',
              style: text.headlineSmall,
            ),
            const SizedBox(height: OmeoTokens.space4),
            OmeoButton(
              label: state.canManage == SubscriptionStateCanManageEnum.web
                  ? l.appPlusSubscriptionFixWeb
                  : l.appPlusSubscriptionFixStore(storeName(l)),
              size: OmeoButtonSize.medium,
              onPressed: onFix,
            ),
          ],
        ),
      );
    }

    return OmeoCard(
      variant: OmeoCardVariant.black,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OmeoTag(name, tone: OmeoTone.glass, icon: OmeoIcons.crown),
              const Spacer(),
              OmeoTag(l.appPlusSubscriptionStatus(sub.status.value)),
            ],
          ),
          if (price != null) ...[
            const SizedBox(height: OmeoTokens.space4),
            Text(
              price,
              style: text.headlineMedium?.copyWith(color: t.onContrast),
            ),
          ],
          const SizedBox(height: OmeoTokens.space1),
          Text(
            sub.autoRenew
                ? l.appPlusSubscriptionRenews(date, channel)
                : l.appPlusSubscriptionEnds(date, channel),
            style: text.bodySmall?.copyWith(
              color: t.onContrast.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Consommation d'un quota telle que renvoyée par l'API (sans calcul).
class _QuotaLine extends StatelessWidget {
  const _QuotaLine({required this.label, required this.q});

  final String label;
  final Quota q;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final limit = q.limit;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          limit == null
              ? l.appMealAddUnlimited
              : l.appPlusSubscriptionQuotaValue(q.used, limit),
          style: text.bodySmall?.copyWith(color: t.text3),
        ),
      ],
    );
  }
}
