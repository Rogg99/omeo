import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/training/application/training_controller.dart';
import 'package:omeo/features/training/data/training_repository.dart';
import 'package:omeo_api/omeo_api.dart'
    show ExerciseSummary, Level, WorkoutSummary;

/// Onglet du catalogue : séances guidées ou bibliothèque d'exercices.
enum TrainingTab { workouts, exercises }

/// Filtre rapide du catalogue (un seul actif à la fois).
enum _Quick { all, cardio, strength, mobility, short, beginner }

/// Durée maximale du filtre « ≤ 15 min ».
const _shortMinutes = 15;

/// Séances guidées (EXO-03) et bibliothèque d'exercices (EXO-01) : filtres
/// par but, durée et niveau. Les contenus Plus restent visibles avec un
/// cadenas.
class TrainingCatalogScreen extends StatefulWidget {
  const TrainingCatalogScreen({
    required this.onBack,
    required this.onWorkout,
    required this.onExercise,
    super.key,
    this.initialTab = TrainingTab.workouts,
  });

  final VoidCallback onBack;
  final ValueChanged<WorkoutSummary> onWorkout;
  final ValueChanged<ExerciseSummary> onExercise;
  final TrainingTab initialTab;

  @override
  State<TrainingCatalogScreen> createState() => _TrainingCatalogScreenState();
}

class _TrainingCatalogScreenState extends State<TrainingCatalogScreen> {
  late TrainingTab _tab = widget.initialTab;
  _Quick _quick = _Quick.all;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final workouts = _tab == TrainingTab.workouts;
    final quicks = workouts
        ? [
            (_Quick.all, l.appTrainingFilterAll),
            (_Quick.cardio, l.appTrainingGoal('cardio')),
            (_Quick.strength, l.appTrainingGoal('strength')),
            (_Quick.mobility, l.appTrainingGoal('mobility')),
            (_Quick.short, l.appTrainingShort),
          ]
        : [
            (_Quick.all, l.appTrainingFilterAllEx),
            (_Quick.beginner, l.appTrainingLevel('beginner')),
          ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OmeoTopBar(
              title: workouts ? l.appTrainingWorkouts : l.appTrainingExercises,
              backLabel: l.commonActionBack,
              onBack: widget.onBack,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OmeoSegmented<TrainingTab>(
                segments: [
                  (value: TrainingTab.workouts, label: l.appTrainingWorkouts),
                  (value: TrainingTab.exercises, label: l.appTrainingExercises),
                ],
                selected: _tab,
                onChanged: (t) => setState(() {
                  _tab = t;
                  _quick = _Quick.all;
                }),
              ),
            ),
            const SizedBox(height: OmeoTokens.space3),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: quicks.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => OmeoChip(
                  label: quicks[i].$2,
                  selected: _quick == quicks[i].$1,
                  onTap: () => setState(() => _quick = quicks[i].$1),
                ),
              ),
            ),
            Expanded(
              child: workouts
                  ? _WorkoutList(
                      filter: (
                        goal: switch (_quick) {
                          _Quick.cardio => 'cardio',
                          _Quick.strength => 'strength',
                          _Quick.mobility => 'mobility',
                          _ => null,
                        },
                        level: null,
                        maxMinutes: _quick == _Quick.short
                            ? _shortMinutes
                            : null,
                      ),
                      onTap: widget.onWorkout,
                    )
                  : _ExerciseGrid(
                      filter: (
                        muscle: null,
                        level: _quick == _Quick.beginner
                            ? Level.beginner
                            : null,
                        equipment: null,
                      ),
                      onTap: widget.onExercise,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutList extends ConsumerWidget {
  const _WorkoutList({required this.filter, required this.onTap});

  final WorkoutFilter filter;
  final ValueChanged<WorkoutSummary> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final workouts = ref.watch(workoutsProvider(filter));
    return switch (workouts) {
      AsyncValue(:final value?) when value.isEmpty => EmptyState(
        icon: OmeoIcons.search,
        title: l.appTrainingEmpty,
      ),
      AsyncValue(:final value?) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        itemCount: value.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) =>
            WorkoutRow(workout: value[i], onTap: () => onTap(value[i])),
      ),
      AsyncValue(:final error?) => EmptyState(
        icon: OmeoIcons.alert,
        title: l.appTrainingErrorTitle,
        message: failureMessage(l, error),
        actionLabel: l.commonActionRetry,
        onAction: () => ref.invalidate(workoutsProvider(filter)),
      ),
      _ => const Center(child: OmeoSpinner()),
    };
  }
}

/// Carte horizontale d'une séance : visuel, nom, but, durée, niveau.
class WorkoutRow extends StatelessWidget {
  const WorkoutRow({required this.workout, required this.onTap, super.key});

  final WorkoutSummary workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final w = workout;
    final meta = l.appTrainingWorkoutMeta(
      l.appTrainingGoal(w.goal.value),
      w.durationS ~/ 60,
      l.appTrainingLevel(w.level.value),
      w.exercisesCount ?? 0,
    );
    return Semantics(
      button: true,
      label: w.locked ? '${w.name}, $meta, ${l.appTrainingLocked}' : null,
      child: Material(
        color: t.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmeoTokens.rLg),
          side: BorderSide(color: t.line),
        ),
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 110,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (w.cover == null)
                        ColoredBox(color: t.infoSoft)
                      else
                        Image.network(
                          w.cover!.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              ColoredBox(color: t.infoSoft),
                        ),
                      if (w.locked)
                        PositionedDirectional(
                          top: 8,
                          start: 8,
                          child: OmeoTag.plus(l.appHomePlusTag),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(w.name, style: text.titleSmall),
                        const SizedBox(height: OmeoTokens.space1),
                        Text(
                          meta,
                          style: text.labelSmall?.copyWith(color: t.text3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseGrid extends ConsumerWidget {
  const _ExerciseGrid({required this.filter, required this.onTap});

  final ExerciseFilter filter;
  final ValueChanged<ExerciseSummary> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final exercises = ref.watch(exercisesProvider(filter));
    return switch (exercises) {
      AsyncValue(:final value?) when value.isEmpty => EmptyState(
        icon: OmeoIcons.search,
        title: l.appTrainingEmpty,
      ),
      AsyncValue(:final value?) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        itemCount: value.length,
        itemBuilder: (context, i) =>
            _ExerciseCard(exercise: value[i], onTap: () => onTap(value[i])),
      ),
      AsyncValue(:final error?) => EmptyState(
        icon: OmeoIcons.alert,
        title: l.appTrainingErrorTitle,
        message: failureMessage(l, error),
        actionLabel: l.commonActionRetry,
        onAction: () => ref.invalidate(exercisesProvider(filter)),
      ),
      _ => const Center(child: OmeoSpinner()),
    };
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.onTap});

  final ExerciseSummary exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final e = exercise;
    return Material(
      color: t.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OmeoTokens.rLg),
        side: BorderSide(color: t.line),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (e.thumbnail == null)
                    ColoredBox(color: t.infoSoft)
                  else
                    Image.network(
                      e.thumbnail!.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(color: t.infoSoft),
                    ),
                  if (e.locked)
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: Semantics(
                        label: l.appTrainingLocked,
                        child: const BadgeIcon(
                          OmeoIcons.lock,
                          tone: OmeoTone.accent,
                          size: BadgeSize.small,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                  Text(
                    l.appTrainingExerciseMeta(
                      (e.muscles ?? const []).join(', '),
                      l.appTrainingLevel(e.level.value),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(color: t.text3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
