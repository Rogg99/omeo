import 'package:flutter/material.dart';
import 'package:omeo/core/l10n/formatters.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo_api/omeo_api.dart' show CompleteWorkoutSession201Response;

/// Minuteur affiché : changement d'échelle des secondes (« 0:27 »).
String sessionClock(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = (seconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

/// Séance terminée (EXO-07) : durée, calories et points tels que renvoyés
/// par l'API.
class SessionDoneView extends StatelessWidget {
  const SessionDoneView({
    required this.workoutName,
    required this.result,
    required this.onDone,
    super.key,
  });

  final String workoutName;
  final CompleteWorkoutSession201Response result;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;

    Widget stat(String value, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: t.surface2,
          borderRadius: BorderRadius.circular(OmeoTokens.rMd),
        ),
        child: Column(
          children: [
            Text(value, style: text.titleLarge),
            Text(label, style: text.labelSmall?.copyWith(color: t.text2)),
          ],
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: t.accent,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: OmeoIcon(
                    OmeoIcons.trophy,
                    size: 44,
                    color: OmeoTokens.cream50,
                  ),
                ),
              ),
              const SizedBox(height: OmeoTokens.space6),
              Semantics(
                header: true,
                child: Text(
                  l.appTrainingFinishedTitle,
                  style: text.headlineLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: OmeoTokens.space2),
              Text(
                workoutName,
                style: text.bodyMedium?.copyWith(color: t.text2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: OmeoTokens.space6),
              Row(
                children: [
                  stat(
                    sessionClock(result.durationS),
                    l.appTrainingFinishedDuration,
                  ),
                  const SizedBox(width: 8),
                  stat(context.number(result.kcal), l.appTrainingFinishedKcal),
                  const SizedBox(width: 8),
                  stat(
                    context.signedNumber(result.rewards.points),
                    l.appTrainingFinishedPoints,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: OmeoButton(label: l.appTrainingFinish, onPressed: onDone),
      ),
    );
  }
}
