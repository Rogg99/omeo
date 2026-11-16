import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/training/application/screen_awake.dart';
import 'package:omeo/features/training/application/session_controller.dart';
import 'package:omeo/features/training/application/training_controller.dart';
import 'package:omeo/features/training/presentation/exercise_video.dart';
import 'package:omeo/features/training/presentation/session_done_view.dart';
import 'package:omeo_api/omeo_api.dart'
    show
        CompleteWorkoutSession201Response,
        WorkoutDetail,
        WorkoutDetailAllOfStepsModeEnum;

/// Destinations du lecteur, fournies par le routeur.
typedef SessionNavigation = ({
  /// Abandon confirmé, ou sortie depuis une erreur de chargement.
  VoidCallback onQuit,

  /// « Terminer » sur le récapitulatif.
  VoidCallback onDone,
});

/// Lecteur de séance : exercice (EXO-05), repos (EXO-06), puis
/// récapitulatif (EXO-07) avec les valeurs renvoyées par l'API.
class SessionScreen extends ConsumerWidget {
  const SessionScreen({
    required this.workoutId,
    required this.navigation,
    super.key,
  });

  final String workoutId;
  final SessionNavigation navigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Theme(
      data: OmeoTheme.dark(
        arabic: Localizations.localeOf(context).languageCode == 'ar',
      ),
      child: Builder(
        builder: (context) => switch (ref.watch(workoutProvider(workoutId))) {
          AsyncValue(:final value?) => _Player(
            workout: value,
            navigation: navigation,
          ),
          AsyncValue(:final error?) => Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  OmeoTopBar(
                    title: '',
                    backLabel: l.commonActionClose,
                    close: true,
                    onBack: navigation.onQuit,
                  ),
                  Expanded(
                    child: EmptyState(
                      icon: OmeoIcons.alert,
                      title: l.appTrainingWorkoutError,
                      message: failureMessage(l, error),
                      actionLabel: l.commonActionRetry,
                      onAction: () =>
                          ref.invalidate(workoutProvider(workoutId)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _ => const Scaffold(body: Center(child: OmeoSpinner())),
        },
      ),
    );
  }
}

class _Player extends ConsumerStatefulWidget {
  const _Player({required this.workout, required this.navigation});

  final WorkoutDetail workout;
  final SessionNavigation navigation;

  @override
  ConsumerState<_Player> createState() => _PlayerState();
}

class _PlayerState extends ConsumerState<_Player> {
  late final ScreenAwake _awake;

  /// Envoi de fin de séance : `null` tant que la séance n'est pas finie.
  AsyncValue<CompleteWorkoutSession201Response>? _completion;

  @override
  void initState() {
    super.initState();
    _awake = ref.read(screenAwakeProvider);
    unawaited(_awake.keepOn());
  }

  @override
  void dispose() {
    unawaited(_awake.release());
    super.dispose();
  }

  Future<void> _complete() async {
    setState(() => _completion = const AsyncLoading());
    final controller = ref.read(
      sessionControllerProvider(widget.workout).notifier,
    );
    final result = await AsyncValue.guard(controller.complete);
    if (mounted) setState(() => _completion = result);
  }

  Future<void> _confirmQuit() async {
    final l = AppLocalizations.of(context);
    final quit = await showOmeoSheet<bool>(
      context: context,
      title: l.appTrainingQuitTitle,
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.appTrainingQuitBody,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.omeo.text2),
          ),
          const SizedBox(height: OmeoTokens.space6),
          OmeoButton(
            label: l.appTrainingQuitConfirm,
            variant: OmeoButtonVariant.danger,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: OmeoTokens.space2),
          OmeoButton(
            label: l.appTrainingQuitCancel,
            variant: OmeoButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
    if ((quit ?? false) && mounted) widget.navigation.onQuit();
  }

  @override
  Widget build(BuildContext context) {
    final provider = sessionControllerProvider(widget.workout);
    ref.listen(provider.select((s) => s.finished), (_, finished) {
      if (finished && _completion == null) unawaited(_complete());
    });
    final session = ref.watch(provider);
    final completion = _completion;
    final finished = session.finished || completion != null;

    return PopScope(
      canPop: completion is AsyncData,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && completion == null) unawaited(_confirmQuit());
      },
      child: switch (completion) {
        AsyncData(:final value) => SessionDoneView(
          workoutName: widget.workout.name,
          result: value,
          onDone: widget.navigation.onDone,
        ),
        AsyncError(:final error) => Scaffold(
          body: SafeArea(
            child: EmptyState(
              icon: OmeoIcons.alert,
              title: AppLocalizations.of(context).appTrainingFinishError,
              message: failureMessage(AppLocalizations.of(context), error),
              actionLabel: AppLocalizations.of(context).commonActionRetry,
              onAction: () => unawaited(_complete()),
            ),
          ),
        ),
        _ when finished => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const OmeoSpinner(),
                const SizedBox(height: OmeoTokens.space4),
                Text(AppLocalizations.of(context).appTrainingFinishing),
              ],
            ),
          ),
        ),
        _ => _PhaseView(
          session: session,
          controller: ref.read(provider.notifier),
          onQuit: () => unawaited(_confirmQuit()),
        ),
      },
    );
  }
}

/// Exercice ou repos, en portrait comme en paysage.
class _PhaseView extends StatelessWidget {
  const _PhaseView({
    required this.session,
    required this.controller,
    required this.onQuit,
  });

  final SessionState session;
  final SessionController controller;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final phase = session.phase;
    final current = phase.stepIndex + 1;
    final topBar = Row(
      children: [
        OmeoIconButton(
          icon: OmeoIcons.x,
          semanticLabel: l.appTrainingQuit,
          onPressed: onQuit,
        ),
        const Spacer(),
        OmeoTag(l.appTrainingProgress(current, session.exercisesCount)),
        const Spacer(),
        Opacity(
          opacity: session.sound ? 1 : 0.45,
          child: OmeoIconButton(
            icon: OmeoIcons.volume,
            semanticLabel: session.sound
                ? l.appTrainingSoundOff
                : l.appTrainingSoundOn,
            onPressed: controller.toggleSound,
          ),
        ),
      ],
    );

    if (phase.kind == PhaseKind.rest) {
      return Scaffold(
        backgroundColor: OmeoTokens.sage800,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                topBar,
                Expanded(
                  child: _RestBody(session: session, controller: controller),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: OmeoTokens.ink950,
      body: OrientationBuilder(
        builder: (context, orientation) {
          final video = ExerciseVideo(
            exerciseId: phase.step.exercise.id,
            media: phase.step.exercise.video,
          );
          final panel = _ExercisePanel(
            session: session,
            controller: controller,
          );
          if (orientation == Orientation.landscape) {
            return Row(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      video,
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Align(
                            alignment: AlignmentDirectional.topStart,
                            child: topBar,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SafeArea(child: Center(child: panel)),
                ),
              ],
            );
          }
          return Column(
            children: [
              Expanded(
                flex: 48,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    video,
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: topBar,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.omeo.bg,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(OmeoTokens.rXl),
                    ),
                  ),
                  child: SafeArea(top: false, child: Center(child: panel)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Barre d'étapes, nom, minuteur géant (ou répétitions), commandes.
class _ExercisePanel extends StatelessWidget {
  const _ExercisePanel({required this.session, required this.controller});

  final SessionState session;
  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final phase = session.phase;
    final remaining = session.remaining;
    final next = session.nextExercise;
    final current = phase.stepIndex + 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StepsBar(
            current: current,
            total: session.exercisesCount,
            semanticLabel: l.appTrainingProgress(
              current,
              session.exercisesCount,
            ),
          ),
          const SizedBox(height: OmeoTokens.space5),
          Semantics(
            header: true,
            child: Text(
              phase.step.exercise.name,
              style: text.headlineMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: OmeoTokens.space2),
          if (remaining != null)
            Semantics(
              label: l.appTrainingTimer(remaining ~/ 60, remaining % 60),
              excludeSemantics: true,
              child: Text(
                sessionClock(remaining),
                style: text.displayLarge?.copyWith(
                  fontSize: 84,
                  height: 1,
                  fontWeight: OmeoTokens.weightSemibold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            )
          else
            Text(
              l.appTrainingStepReps(phase.step.reps ?? 0),
              style: text.headlineLarge,
            ),
          const SizedBox(height: OmeoTokens.space6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OmeoIconButton(
                icon: OmeoIcons.chevL,
                semanticLabel: l.appTrainingPrevious,
                mirrorInRtl: true,
                onPressed: phase.stepIndex == 0 ? null : controller.previous,
              ),
              const SizedBox(width: OmeoTokens.space6),
              if (remaining != null)
                _RoundButton(
                  icon: session.paused ? OmeoIcons.play : OmeoIcons.pause,
                  label: session.paused
                      ? l.appTrainingResume
                      : l.appTrainingPause,
                  onPressed: controller.togglePause,
                )
              else
                _RoundButton(
                  icon: OmeoIcons.check,
                  label: l.appTrainingDoneReps,
                  onPressed: controller.next,
                ),
              const SizedBox(width: OmeoTokens.space6),
              OmeoIconButton(
                icon: OmeoIcons.skip,
                semanticLabel: l.appTrainingNext,
                mirrorInRtl: true,
                onPressed: controller.next,
              ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: OmeoTokens.space5),
            Text(
              l.appTrainingThen(_stepLabel(l, next)),
              style: text.bodySmall?.copyWith(color: t.text2),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// « Pompes inclinées · 10 répétitions » ou « Gainage · 30 s ».
String _stepLabel(AppLocalizations l, SessionPhase p) {
  final amount = p.step.mode == WorkoutDetailAllOfStepsModeEnum.time
      ? l.appTrainingStepTime(p.step.durationS ?? 0)
      : l.appTrainingStepReps(p.step.reps ?? 0);
  return '${p.step.exercise.name} · $amount';
}

/// Repos lisible de loin : anneau, +10 s, passer, exercice à suivre.
class _RestBody extends StatelessWidget {
  const _RestBody({required this.session, required this.controller});

  final SessionState session;
  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final remaining = session.remaining ?? 0;
    final total = session.phase.durationS ?? remaining;
    final next = session.phase;
    const onRest = OmeoTokens.cream50;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Eyebrow(l.appTrainingRest, color: OmeoTokens.dark.primaryHover),
          const SizedBox(height: OmeoTokens.space4),
          OmeoRing(
            size: 220,
            stroke: 14,
            // Dessin de l'anneau uniquement : part du repos écoulée.
            progress: total == 0 ? 0 : remaining / total,
            color: OmeoTokens.dark.primaryHover,
            trackColor: onRest.withValues(alpha: 0.12),
            semanticLabel: l.appTrainingTimer(remaining ~/ 60, remaining % 60),
            child: Text(
              sessionClock(remaining),
              style: text.displayLarge?.copyWith(
                fontSize: 72,
                color: onRest,
                fontWeight: OmeoTokens.weightSemibold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: OmeoTokens.space6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OmeoButton(
                label: l.appTrainingAddTen,
                expand: false,
                size: OmeoButtonSize.small,
                variant: OmeoButtonVariant.outline,
                onPressed: controller.extendRest,
              ),
              const SizedBox(width: OmeoTokens.space3),
              OmeoButton(
                label: l.appTrainingSkip,
                expand: false,
                size: OmeoButtonSize.small,
                variant: OmeoButtonVariant.white,
                onPressed: controller.next,
              ),
            ],
          ),
          const SizedBox(height: OmeoTokens.space8),
          Container(
            padding: const EdgeInsets.all(OmeoTokens.space4),
            decoration: BoxDecoration(
              color: onRest.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(OmeoTokens.rLg),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(OmeoTokens.rMd),
                  child: SizedBox.square(
                    dimension: 64,
                    child: next.step.exercise.video.poster == null
                        ? ColoredBox(color: onRest.withValues(alpha: 0.12))
                        : Image.network(
                            next.step.exercise.video.poster!.url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => ColoredBox(
                              color: onRest.withValues(alpha: 0.12),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: OmeoTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.appTrainingUpNext,
                        style: text.labelSmall?.copyWith(
                          color: onRest.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        next.step.exercise.name,
                        style: text.titleMedium?.copyWith(color: onRest),
                      ),
                      Text(
                        next.step.mode == WorkoutDetailAllOfStepsModeEnum.time
                            ? l.appTrainingStepTime(next.step.durationS ?? 0)
                            : l.appTrainingStepReps(next.step.reps ?? 0),
                        style: text.labelSmall?.copyWith(
                          color: onRest.withValues(alpha: 0.6),
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
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final OmeoIcons icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: t.contrast,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 76,
            child: Center(child: OmeoIcon(icon, color: t.onContrast)),
          ),
        ),
      ),
    );
  }
}
