import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        PlanCatalogPlansInnerIntervalEnum,
        PlanTier,
        QuotaFeatureEnum,
        SubscriptionState;

/// Présentation d'Omeo Plus (PLS-01) : situation actuelle, annuel mis en
/// avant avec son économie, bénéfices et mentions du store. Fermable.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({
    required this.onClose,
    required this.onSubscribed,
    super.key,
    this.onWebCheckout,
  });

  final VoidCallback onClose;
  final VoidCallback onSubscribed;

  /// Paiement sur le site, proposé seulement si l'API l'autorise.
  final VoidCallback? onWebCheckout;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String? _selected;
  bool _busy = false;

  Future<void> _run(Future<PurchaseOutcome> Function() action) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final outcome = await action();
      switch (outcome) {
        case PurchaseOutcome.plus:
          unawaited(HapticFeedback.mediumImpact());
          messenger.showSnackBar(
            SnackBar(content: Text(l.appPlusPaywallWelcome)),
          );
          widget.onSubscribed();
        case PurchaseOutcome.nothingToRestore:
          messenger.showSnackBar(
            SnackBar(content: Text(l.appPlusPaywallNothingRestored)),
          );
        case PurchaseOutcome.cancelled:
          break;
      }
    } on StoreBillingException {
      messenger.showSnackBar(
        SnackBar(content: Text(l.appPlusPaywallStoreError)),
      );
    } on ApiFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage(l, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final offers = ref.watch(planOffersProvider);
    final state = ref.watch(subscriptionProvider).value;

    return Scaffold(
      body: switch (offers) {
        AsyncValue(:final value?) => _content(context, value, state),
        AsyncValue(:final error?) => SafeArea(
          child: Column(
            children: [
              OmeoTopBar(
                title: '',
                backLabel: l.commonActionClose,
                close: true,
                onBack: widget.onClose,
              ),
              Expanded(
                child: EmptyState(
                  icon: OmeoIcons.alert,
                  title: l.appPlusPaywallErrorTitle,
                  message: failureMessage(l, error),
                  actionLabel: l.commonActionRetry,
                  onAction: () => ref.invalidate(planOffersProvider),
                ),
              ),
            ],
          ),
        ),
        _ => const Center(child: OmeoSpinner()),
      },
    );
  }

  Widget _content(
    BuildContext context,
    List<PlanOffer> offers,
    SubscriptionState? state,
  ) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final featured = offers.where((o) => o.plan.featured).firstOrNull;
    final selectedCode =
        _selected ?? (featured ?? offers.firstOrNull)?.plan.code;
    final selected = offers
        .where((o) => o.plan.code == selectedCode)
        .firstOrNull;
    final canBuy = state?.canPurchaseInApp ?? true;
    final store = l.appPlusPaywallStore(
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    );
    final perks = ref.watch(_perksProvider).value ?? const <String>[];

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(state: state, onClose: widget.onClose),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                sliver: SliverList.list(
                  children: [
                    for (final o in offers) ...[
                      _PlanOption(
                        offer: o,
                        selected: o.plan.code == selectedCode,
                        onTap: () => setState(() => _selected = o.plan.code),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (perks.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      OmeoList(
                        children: [
                          for (final perk in perks)
                            OmeoListTile(
                              leading: const BadgeIcon(
                                OmeoIcons.check,
                                size: BadgeSize.small,
                                round: true,
                              ),
                              title: perk,
                              showChevron: false,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: OmeoTokens.space4),
                    Text(
                      l.appPlusPaywallLegal(store),
                      textAlign: TextAlign.center,
                      style: text.labelSmall?.copyWith(color: t.text3),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: _busy
                            ? null
                            : () => unawaited(
                                _run(
                                  () => ref
                                      .read(purchaseActionsProvider)
                                      .restore(),
                                ),
                              ),
                        child: Text(l.appPlusPaywallRestore),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            children: [
              if (canBuy && selected != null)
                OmeoButton(
                  label: l.appPlusPaywallContinue(
                    selected.storePrice ?? selected.plan.price.formatted ?? '',
                    selected.plan.interval.value,
                  ),
                  loading: _busy,
                  onPressed: _busy
                      ? null
                      : () => unawaited(
                          _run(
                            () => ref
                                .read(purchaseActionsProvider)
                                .buy(selected.plan),
                          ),
                        ),
                )
              else if ((state?.webCheckoutAllowed ?? false) &&
                  widget.onWebCheckout != null)
                OmeoButton(
                  label: l.appPlusPaywallWeb,
                  trailingIcon: OmeoIcons.arrowUR,
                  onPressed: widget.onWebCheckout,
                ),
              const SizedBox(height: OmeoTokens.space1),
              OmeoButton(
                label: l.appPlusPaywallStayFree,
                variant: OmeoButtonVariant.ghost,
                onPressed: widget.onClose,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bénéfices de Plus : libellés de la comparaison renvoyée par l'API.
final FutureProvider<List<String>> _perksProvider = FutureProvider.autoDispose(
  (ref) async {
    final catalog = await ref.watch(planCatalogProvider.future);
    return [for (final c in catalog.comparison) c.label];
  },
);

class _Hero extends StatelessWidget {
  const _Hero({required this.state, required this.onClose});

  final SubscriptionState? state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    const cream = Color(0xFFF4EFE6);
    final s = state;
    final photo = s == null
        ? null
        : quotaFor(s.quotas, QuotaFeatureEnum.photoAnalysis);
    final voice = s == null
        ? null
        : quotaFor(s.quotas, QuotaFeatureEnum.textAnalysis);
    final quotaLine = [
      if (photo?.limit != null && photo?.remaining != null)
        l.appPlusPaywallQuotaPhoto(photo!.remaining!, photo.limit!),
      if (voice?.limit != null && voice!.limit! > 0 && voice.remaining != null)
        l.appPlusPaywallQuotaText(voice.remaining!, voice.limit!),
    ].join(' · ');
    final trial = s?.entitlements.tier == PlanTier.trial;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        20,
        26,
      ),
      decoration: const BoxDecoration(
        color: OmeoTokens.sage800,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OmeoTag(
                l.appPlusPaywallTag,
                tone: OmeoTone.glass,
                icon: OmeoIcons.crown,
              ),
              const Spacer(),
              Material(
                color: Colors.white.withValues(alpha: 0.12),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: l.commonActionClose,
                  onPressed: onClose,
                  icon: const OmeoIcon(OmeoIcons.x, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Semantics(
            header: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${l.appPlusPaywallTitle}\n'),
                  TextSpan(
                    text: l.appPlusPaywallTitleAccent,
                    style: const TextStyle(
                      fontFamily: 'Instrument Serif',
                      fontStyle: FontStyle.italic,
                      fontSize: 38,
                      color: Color(0xFFF2A26B),
                    ),
                  ),
                ],
              ),
              style: text.displaySmall?.copyWith(color: cream),
            ),
          ),
          if (s != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(OmeoTokens.rLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          trial ? l.appPlusPaywallTrial : l.appPlusPaywallFree,
                          style: text.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (trial && s.trialDaysLeft != null)
                        Text(
                          l.appPlusPaywallTrialLeft(s.trialDaysLeft!),
                          style: text.bodySmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                  if (quotaLine.isNotEmpty) ...[
                    const SizedBox(height: OmeoTokens.space2),
                    Text(
                      quotaLine,
                      style: text.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.offer,
    required this.selected,
    required this.onTap,
  });

  final PlanOffer offer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final plan = offer.plan;
    final monthly = plan.monthlyEquivalent?.formatted;
    final savings = plan.savingsPercent;
    final subtitle = plan.interval == PlanCatalogPlansInnerIntervalEnum.month
        ? l.appPlusPaywallNoCommitment
        : [
            if (monthly != null) l.appPlusPaywallPerMonth(monthly),
            if (savings != null) l.appPlusPaywallSavings(savings),
          ].join(' · ');
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? t.primarySoft : t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmeoTokens.rLg),
          side: BorderSide(
            color: selected ? t.primary : t.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(OmeoTokens.rLg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(plan.name, style: text.titleMedium),
                          if (plan.featured)
                            OmeoTag(
                              l.appPlusPaywallBest,
                              tone: OmeoTone.accent,
                            ),
                        ],
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: text.bodySmall?.copyWith(color: t.text2),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  offer.storePrice ?? plan.price.formatted ?? '',
                  style: text.titleLarge,
                ),
                const SizedBox(width: 12),
                SelectionMark(selected: selected, square: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
