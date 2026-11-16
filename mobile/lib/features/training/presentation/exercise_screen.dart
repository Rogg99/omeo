import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/training/application/training_controller.dart';
import 'package:omeo/features/training/presentation/exercise_video.dart';
import 'package:omeo_api/omeo_api.dart' show ExerciseDetail;

/// Fiche exercice (EXO-02) : vidéo courte en boucle, consignes numérotées,
/// muscles, niveau, matériel, et conseil de sécurité.
class ExerciseScreen extends ConsumerWidget {
  const ExerciseScreen({
    required this.exerciseId,
    required this.onBack,
    super.key,
  });

  final String exerciseId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final exercise = ref.watch(exerciseProvider(exerciseId));
    return Scaffold(
      body: switch (exercise) {
        AsyncValue(:final value?) => _Content(exercise: value, onBack: onBack),
        AsyncValue(:final error?) => SafeArea(
          child: Column(
            children: [
              OmeoTopBar(
                title: '',
                backLabel: l.commonActionBack,
                onBack: onBack,
              ),
              Expanded(
                child: EmptyState(
                  icon: OmeoIcons.alert,
                  title: l.appTrainingExerciseError,
                  message: failureMessage(l, error),
                  actionLabel: l.commonActionRetry,
                  onAction: () => ref.invalidate(exerciseProvider(exerciseId)),
                ),
              ),
            ],
          ),
        ),
        _ => const Center(child: OmeoSpinner()),
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.exercise, required this.onBack});

  final ExerciseDetail exercise;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final e = exercise;
    final steps = e.instructions
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final equipment = e.equipment ?? const <String>[];
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            children: [
              SizedBox(
                height: 320,
                width: double.infinity,
                child: ExerciseVideo(exerciseId: e.id, media: e.video),
              ),
              PositionedDirectional(
                top: MediaQuery.paddingOf(context).top + 12,
                start: 16,
                child: OmeoIconButton(
                  icon: OmeoIcons.chevL,
                  semanticLabel: l.commonActionBack,
                  mirrorInRtl: true,
                  onPressed: onBack,
                ),
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          sliver: SliverList.list(
            children: [
              Semantics(
                header: true,
                child: Text(e.name, style: text.headlineMedium),
              ),
              const SizedBox(height: OmeoTokens.space3),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OmeoTag(l.appTrainingLevel(e.level.value)),
                  OmeoTag(
                    equipment.isEmpty
                        ? l.appTrainingNoEquipment
                        : equipment.join(', '),
                    tone: OmeoTone.neutral,
                  ),
                  if ((e.muscles ?? const []).isNotEmpty)
                    OmeoTag(e.muscles!.join(' · '), tone: OmeoTone.neutral),
                ],
              ),
              const SizedBox(height: OmeoTokens.space6),
              SectionTitle(l.appTrainingHowTo),
              const SizedBox(height: OmeoTokens.space3),
              for (final (i, step) in steps.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: t.contrast,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: text.labelMedium?.copyWith(
                            color: t.onContrast,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: OmeoTokens.space3),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(step, style: text.bodySmall),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: OmeoTokens.space2),
              OmeoBanner(
                icon: OmeoIcons.alert,
                tone: OmeoTone.warning,
                child: Text(l.appTrainingSafety),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
