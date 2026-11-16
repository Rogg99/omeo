import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/formatters.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/auth/application/auth_actions.dart';
import 'package:omeo/features/auth/application/session.dart';
import 'package:omeo/features/auth/presentation/auth_widgets.dart';
import 'package:omeo/features/onboarding/application/onboarding_controller.dart';
import 'package:omeo/features/profile/application/unit_preferences.dart';
import 'package:omeo/features/profile/presentation/unit_format.dart';
import 'package:omeo_api/omeo_api.dart';

/// Calcul du plan (ONB-15) : l'API crée le compte et calcule les objectifs.
/// Les étapes s'affichent l'une après l'autre pour rendre l'attente utile ;
/// la réponse de l'API termine l'écran.
class PlanComputingScreen extends ConsumerStatefulWidget {
  const PlanComputingScreen({
    required this.onReady,
    required this.onFailed,
    super.key,
    this.stepDelay = const Duration(milliseconds: 700),
  });

  final VoidCallback onReady;

  /// Retour à l'étape 9, où l'erreur est expliquée.
  final VoidCallback onFailed;
  final Duration stepDelay;

  @override
  ConsumerState<PlanComputingScreen> createState() =>
      _PlanComputingScreenState();
}

class _PlanComputingScreenState extends ConsumerState<PlanComputingScreen> {
  static const _steps = 4;
  Timer? _timer;
  int _done = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.stepDelay, (timer) {
      // La dernière étape attend la réponse de l'API.
      if (_done >= _steps - 1) {
        timer.cancel();
        return;
      }
      setState(() => _done++);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _check() {
    final registration = ref.read(registrationProvider);
    final social = ref.read(socialAuthProvider);
    if (registration.hasError) {
      widget.onFailed();
    } else if (registration.value != null || social.value != null) {
      widget.onReady();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(registrationProvider, (_, _) => _check())
      ..listen(socialAuthProvider, (_, _) => _check());
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final labels = [
      l.appOnboardingComputingBmr,
      l.appOnboardingComputingKcal,
      l.appOnboardingComputingMacros,
      l.appOnboardingComputingDishes,
    ];
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  OmeoRing(
                    size: 150,
                    stroke: 10,
                    progress: (_done + 1) / (_steps + 1),
                    semanticLabel: l.appOnboardingComputingTitle,
                    child: const OmeoIcon(OmeoIcons.sparkles, size: 40),
                  ),
                  const SizedBox(height: 32),
                  Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      l.appOnboardingComputingTitle,
                      textAlign: TextAlign.center,
                      style: text.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < labels.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Semantics(
                                  checked: i < _done,
                                  child: SelectionMark(
                                    selected: i < _done,
                                    square: false,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  labels[i],
                                  style: text.bodyMedium?.copyWith(
                                    color: i < _done ? t.text : t.text3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Plan prêt (ONB-16) : objectifs calculés par l'API, durée de l'essai.
class PlanReadyScreen extends ConsumerWidget {
  const PlanReadyScreen({required this.onStart, super.key});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final me = ref.watch(meProvider);
    return BottomActionsScaffold(
      canPop: false,
      body: switch (me) {
        AsyncValue(:final value?) => _PlanSummary(me: value),
        AsyncValue(:final error?) => EmptyState(
          icon: OmeoIcons.alert,
          title: l.appOnboardingReadyError,
          actionLabel: l.commonActionRetry,
          message: failureMessage(l, error),
          onAction: () => ref.invalidate(meProvider),
        ),
        _ => const Padding(
          padding: EdgeInsets.only(top: 120),
          child: Center(child: OmeoSpinner()),
        ),
      },
      actions: [
        OmeoButton(
          label: l.appOnboardingReadyAction,
          onPressed: me.hasValue ? onStart : null,
        ),
      ],
    );
  }
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.me});

  final Me me;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final targets = me.targets;
    final trialEnds = me.entitlements.trialEndsAt;
    final prefs = me.preferences;

    Widget macro(String label, int grams, Color color) => Expanded(
      child: OmeoCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(height: 8),
            FittedBox(
              child: Text(
                l.commonUnitGrams(grams),
                style: text.titleLarge?.copyWith(fontSize: 19),
              ),
            ),
            Text(label, style: text.bodySmall?.copyWith(color: t.text2)),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        if (me.entitlements.tier == PlanTier.trial && trialEnds != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OmeoTag(
              l.appOnboardingTrialUntil(
                context.longDate(trialEnds.toLocal()),
              ),
              icon: OmeoIcons.sparkles,
            ),
          ),
        const SizedBox(height: 16),
        ScreenTitle(l.appOnboardingReadyTitle(me.profile.firstName)),
        const SizedBox(height: 24),
        OmeoCard(
          variant: OmeoCardVariant.black,
          padding: const EdgeInsets.all(26),
          child: Column(
            children: [
              Eyebrow(
                l.appOnboardingReadyKcalLabel,
                color: t.onContrast.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 8),
              FittedBox(
                child: Text(
                  l.commonUnitKcal(targets.kcal),
                  style: text.displayMedium?.copyWith(color: t.onContrast),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: OmeoTokens.space3),
        Row(
          children: [
            macro(l.appHomeMacroProtein, targets.proteinG, t.dataProtein),
            const SizedBox(width: OmeoTokens.space2),
            macro(l.appHomeMacroCarbs, targets.carbsG, t.dataCarbs),
            const SizedBox(width: OmeoTokens.space2),
            macro(l.appHomeMacroFat, targets.fatG, t.dataFat),
          ],
        ),
        const SizedBox(height: OmeoTokens.space3),
        OmeoList(
          children: [
            OmeoListTile(
              icon: OmeoIcons.drop,
              title: l.appOnboardingReadyWater,
              showChevron: false,
              trailing: Text(
                context.water(targets.waterMl, prefs.volumeSystem),
                style: text.titleSmall,
              ),
            ),
            OmeoListTile(
              icon: OmeoIcons.flag,
              title: l.appOnboardingReadyTarget,
              showChevron: false,
              trailing: Text(
                context.weight(me.profile.targetWeightKg, prefs.weightSystem),
                style: text.titleSmall,
              ),
            ),
          ],
        ),
        if (targets.warning != null) ...[
          const SizedBox(height: OmeoTokens.space3),
          OmeoBanner(
            icon: OmeoIcons.alert,
            tone: OmeoTone.warning,
            child: Text(targets.warning!),
          ),
        ],
        const SizedBox(height: OmeoTokens.space3),
        Text(
          l.appOnboardingReadyDisclaimer,
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: t.text3),
        ),
      ],
    );
  }
}
