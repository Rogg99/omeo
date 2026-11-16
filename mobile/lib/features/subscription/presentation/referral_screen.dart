import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/subscription/application/subscription_controller.dart';
import 'package:omeo_api/omeo_api.dart'
    show ReferralOverview, ReferralOverviewRefereesInnerStatusEnum;

/// Couleur de marque de WhatsApp, pour son bouton de partage.
const _whatsappGreen = Color(0xFF25D366);

/// Destinations du parrainage, fournies par le routeur.
typedef ReferralNavigation = ({
  VoidCallback onBack,

  /// Partage du message (lien compris) sur WhatsApp, en priorité.
  ValueChanged<String> shareOnWhatsApp,

  /// Feuille de partage du système.
  ValueChanged<String> shareElsewhere,
});

/// Parrainage (REF-01) : code et lien à partager, règles, jours gagnés et
/// filleuls, tels que renvoyés par l'API.
class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({required this.navigation, super.key});

  final ReferralNavigation navigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final referral = ref.watch(referralProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OmeoTopBar(
              title: l.appReferralTitle,
              backLabel: l.commonActionBack,
              onBack: navigation.onBack,
            ),
            Expanded(
              child: switch (referral) {
                AsyncValue(:final value?) => _Content(
                  referral: value,
                  navigation: navigation,
                ),
                AsyncValue(:final error?) => EmptyState(
                  icon: OmeoIcons.alert,
                  title: l.appReferralErrorTitle,
                  message: failureMessage(l, error),
                  actionLabel: l.commonActionRetry,
                  onAction: () => ref.invalidate(referralProvider),
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

class _Content extends StatelessWidget {
  const _Content({required this.referral, required this.navigation});

  final ReferralOverview referral;
  final ReferralNavigation navigation;

  Future<void> _copy(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: referral.code));
    unawaited(HapticFeedback.selectionClick());
    messenger.showSnackBar(SnackBar(content: Text(l.appReferralCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final referees = referral.referees ?? const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: [
        OmeoCard(
          variant: OmeoCardVariant.green,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BadgeIcon(
                OmeoIcons.gift,
                tone: OmeoTone.glass,
                size: BadgeSize.large,
              ),
              const SizedBox(height: OmeoTokens.space4),
              Semantics(
                header: true,
                child: Text(
                  l.appReferralHeroTitle,
                  style: text.headlineMedium?.copyWith(color: t.onPrimary),
                ),
              ),
              const SizedBox(height: OmeoTokens.space2),
              Text(
                l.appReferralHeroBody(referral.daysCap),
                style: text.bodySmall?.copyWith(
                  color: t.onPrimary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: OmeoTokens.space3),
        OmeoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.appReferralYourCode,
                style: text.labelSmall?.copyWith(
                  color: t.text3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: OmeoTokens.space2),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      referral.code,
                      style: text.headlineLarge?.copyWith(letterSpacing: 1.6),
                    ),
                  ),
                  OmeoIconButton(
                    icon: OmeoIcons.copy,
                    semanticLabel: l.appReferralCopy,
                    onPressed: () => unawaited(_copy(context)),
                  ),
                ],
              ),
              const SizedBox(height: OmeoTokens.space4),
              Semantics(
                button: true,
                label: l.appReferralWhatsapp,
                excludeSemantics: true,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _whatsappGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () =>
                      navigation.shareOnWhatsApp(referral.shareMessage),
                  icon: const OmeoIcon(OmeoIcons.whatsapp, color: Colors.white),
                  label: Text(l.appReferralWhatsapp),
                ),
              ),
              const SizedBox(height: OmeoTokens.space2),
              OmeoButton(
                label: l.appReferralOtherApps,
                icon: OmeoIcons.share,
                variant: OmeoButtonVariant.outline,
                size: OmeoButtonSize.medium,
                onPressed: () =>
                    navigation.shareElsewhere(referral.shareMessage),
              ),
            ],
          ),
        ),
        const SizedBox(height: OmeoTokens.space3),
        OmeoCard(
          child: Row(
            children: [
              Expanded(
                child: Text(l.appReferralDaysEarned, style: text.titleSmall),
              ),
              Text(
                l.appReferralDaysValue(referral.daysEarned, referral.daysCap),
                style: text.titleSmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: OmeoTokens.space6),
        SectionTitle(l.appReferralReferees),
        const SizedBox(height: OmeoTokens.space3),
        if (referees.isEmpty)
          Text(
            l.appReferralEmpty,
            style: text.bodySmall?.copyWith(color: t.text2),
          )
        else
          OmeoList(
            children: [
              for (final r in referees)
                OmeoListTile(
                  leading: _Initial(
                    name: r.firstName ?? '?',
                    validated:
                        r.status ==
                        ReferralOverviewRefereesInnerStatusEnum.validated,
                  ),
                  title: r.firstName ?? '',
                  subtitle: l.appReferralRefereeStatus(
                    r.status?.value ?? 'pending',
                  ),
                  showChevron: false,
                  trailing:
                      r.status ==
                          ReferralOverviewRefereesInnerStatusEnum.validated
                      ? const SelectionMark(selected: true, square: false)
                      : const OmeoIcon(OmeoIcons.clock),
                ),
            ],
          ),
        const SizedBox(height: OmeoTokens.space3),
        Text(
          l.appReferralRules,
          style: text.labelSmall?.copyWith(color: t.text3),
        ),
      ],
    );
  }
}

/// Pastille avec l'initiale du filleul.
class _Initial extends StatelessWidget {
  const _Initial({required this.name, required this.validated});

  final String name;
  final bool validated;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final colors = toneColors(
      t,
      validated ? OmeoTone.primary : OmeoTone.neutral,
    );
    return ExcludeSemantics(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.background,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          name.characters.first.toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.foreground,
          ),
        ),
      ),
    );
  }
}
