import 'package:flutter/material.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/auth/presentation/auth_widgets.dart';

/// Nombre total d'étapes affiché (questions + création du compte).
const onboardingTotalSteps = 9;

/// En-tête d'une étape : retour, barre d'étapes et « n/9 ».
class StepHeader extends StatelessWidget {
  const StepHeader({required this.step, required this.onBack, super.key});

  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final label = l.appOnboardingStep(step, onboardingTotalSteps);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: [
          OmeoIconButton(
            icon: OmeoIcons.arrowL,
            ghost: true,
            mirrorInRtl: true,
            semanticLabel: l.appOnboardingPrevious,
            onPressed: onBack,
          ),
          Expanded(
            child: StepsBar(
              current: step,
              total: onboardingTotalSteps,
              semanticLabel: label,
            ),
          ),
          SizedBox(
            width: 44,
            child: ExcludeSemantics(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: context.omeo.primaryText,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une question par écran : pastille, titre, sous-titre, champ, et bouton
/// toujours accessible au pouce.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    required this.step,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.onBack,
    required this.onContinue,
    super.key,
    this.continueLabel,
  });

  final int step;
  final OmeoIcons icon;
  final String title;
  final String subtitle;
  final Widget body;
  final VoidCallback onBack;

  /// `null` : réponse incomplète, bouton désactivé.
  final VoidCallback? onContinue;
  final String? continueLabel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BottomActionsScaffold(
      header: StepHeader(step: step, onBack: onBack),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: HeroBadge(icon),
          ),
          const SizedBox(height: 20),
          ScreenTitle(title, subtitle: subtitle),
          const SizedBox(height: 32),
          body,
        ],
      ),
      actions: [
        OmeoButton(
          label: continueLabel ?? l.commonActionContinue,
          trailingIcon: OmeoIcons.arrowR,
          onPressed: onContinue,
        ),
      ],
    );
  }
}
