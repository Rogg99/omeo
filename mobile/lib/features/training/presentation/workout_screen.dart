import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/formatters.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/training/application/session_controller.dart';
import 'package:omeo/features/training/application/training_controller.dart';
import 'package:omeo_api/omeo_api.dart'
    show WorkoutDetail, WorkoutDetailAllOfStepsModeEnum;

/// Destinations du détail d'une séance, fournies par le routeur.
typedef WorkoutNavigation = ({
  VoidCallback onBack,
  ValueChanged<WorkoutDetail> onStart,

  /// Séance verrouillée : présentation de Plus.
  VoidCallback onLocked,
});

/// Détail d'une séance (EXO-04) : enchaînement complet, durée, calories
/// estimées par l'API et téléchargement hors connexion (Plus).
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({
    required this.workoutId,
    required this.navigation,
    super.key,
  });

  final String workoutId;
  final WorkoutNavigation navigation;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  bool _downloading = false;

  Future<void> _download(WorkoutDetail workout) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _downloading = true);
    try {
      await ref.read(workoutDownloadsProvider).download(workout.id);
      ref.invalidate(workoutDownloadedProvider(workout));
      messenger.showSnackBar(
        SnackBar(content: Text(l.appTrainingDownloadDone)),
      );
    } on ApiFailure catch (e) {
      ref.read(globalErrorBusProvider).report(e);
      messenger.showSnackBar(SnackBar(content: Text(failureMessage(l, e))));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final workout = ref.watch(workoutProvider(widget.workoutId));
    return Scaffold(
      body: switch (workout) {
        AsyncValue(:final value?) => _content(context, value),
        AsyncValue(:final error?) => SafeArea(
          child: Column(
            children: [
              OmeoTopBar(
                title: '',
                backLabel: l.commonActionBack,
                onBack: widget.navigation.onBack,
              ),
              Expanded(
                child: EmptyState(
                  icon: OmeoIcons.alert,
                  title: l.appTrainingWorkoutError,
                  message: failureMessage(l, error),
                  actionLabel: l.commonActionRetry,
                  onAction: () =>
                      ref.invalidate(workoutProvider(widget.workoutId)),
                ),
              ),
            ],
          ),
        ),
        _ => const Center(child: OmeoSpinner()),
      },
      bottomNavigationBar: workout.value == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: OmeoButton(
                label: l.appTrainingStart,
                icon: workout.value!.locked ? OmeoIcons.lock : OmeoIcons.play,
                onPressed: () => workout.value!.locked
                    ? widget.navigation.onLocked()
                    : widget.navigation.onStart(workout.value!),
              ),
            ),
    );
  }

  Widget _content(BuildContext context, WorkoutDetail w) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final downloaded = ref.watch(workoutDownloadedProvider(w)).value ?? false;
    final phases = buildPhases(w.steps);
    final exercises = phases.where((p) => p.kind == PhaseKind.exercise).length;

    Widget stat(String value, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: t.surface2,
          borderRadius: BorderRadius.circular(OmeoTokens.rMd),
        ),
        child: Column(
          children: [
            Text(value, style: text.titleMedium),
            Text(label, style: text.labelSmall?.copyWith(color: t.text2)),
          ],
        ),
      ),
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            children: [
              SizedBox(
                height: 240,
                width: double.infinity,
                child: w.cover == null
                    ? ColoredBox(color: t.infoSoft)
                    : Image.network(
                        w.cover!.url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            ColoredBox(color: t.infoSoft),
                      ),
              ),
              PositionedDirectional(
                top: MediaQuery.paddingOf(context).top + 12,
                start: 16,
                end: 16,
                child: Row(
                  children: [
                    OmeoIconButton(
                      icon: OmeoIcons.chevL,
                      semanticLabel: l.commonActionBack,
                      mirrorInRtl: true,
                      onPressed: widget.navigation.onBack,
                    ),
                    const Spacer(),
                    if ((w.downloadable ?? false) && !downloaded)
                      _downloading
                          ? const OmeoSpinner(size: 28)
                          : OmeoIconButton(
                              icon: OmeoIcons.download,
                              semanticLabel: l.appTrainingDownload,
                              onPressed: () => unawaited(_download(w)),
                            ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          sliver: SliverList.list(
            children: [
              Wrap(
                spacing: 8,
                children: [
                  OmeoTag(l.appTrainingGoal(w.goal.value)),
                  if (downloaded)
                    OmeoTag(
                      l.appTrainingDownloaded,
                      icon: OmeoIcons.download,
                    ),
                  if (w.locked) OmeoTag.plus(l.appHomePlusTag),
                ],
              ),
              const SizedBox(height: OmeoTokens.space2),
              Semantics(
                header: true,
                child: Text(w.name, style: text.headlineMedium),
              ),
              if (w.description != null) ...[
                const SizedBox(height: OmeoTokens.space2),
                Text(
                  w.description!,
                  style: text.bodySmall?.copyWith(color: t.text2),
                ),
              ],
              const SizedBox(height: OmeoTokens.space4),
              Row(
                children: [
                  stat(
                    l.appTrainingMinutes(w.durationS ~/ 60),
                    l.appTrainingDuration,
                  ),
                  const SizedBox(width: 8),
                  if (w.estimatedKcal != null) ...[
                    stat(
                      '~${context.number(w.estimatedKcal!)}',
                      l.appTrainingKcalEstimated,
                    ),
                    const SizedBox(width: 8),
                  ],
                  stat(
                    l.appTrainingLevel(w.level.value),
                    l.appTrainingLevelLabel,
                  ),
                ],
              ),
              const SizedBox(height: OmeoTokens.space6),
              SectionTitle(l.appTrainingStepsTitle(exercises)),
              const SizedBox(height: OmeoTokens.space3),
              OmeoList(
                children: [
                  for (final p in phases)
                    if (p.kind == PhaseKind.rest)
                      OmeoListTile(
                        icon: OmeoIcons.timer,
                        iconTone: OmeoTone.neutral,
                        title: l.appTrainingRest,
                        showChevron: false,
                        trailing: Text(l.appTrainingStepTime(p.durationS ?? 0)),
                      )
                    else
                      OmeoListTile(
                        icon: OmeoIcons.pulse,
                        title: p.step.exercise.name,
                        showChevron: false,
                        trailing: Text(
                          p.step.mode == WorkoutDetailAllOfStepsModeEnum.time
                              ? l.appTrainingStepTime(p.step.durationS ?? 0)
                              : l.appTrainingStepReps(p.step.reps ?? 0),
                        ),
                      ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
