import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/meals/application/analysis_controller.dart';
import 'package:omeo_api/omeo_api.dart' show Analysis;

/// Ce qui est analysé : la photo prise (affichée pendant l'analyse) ou un
/// texte (saisie vocale ou écrite).
sealed class AnalysisRequest {
  const AnalysisRequest();
}

final class PhotoRequest extends AnalysisRequest {
  const PhotoRequest(this.bytes);
  final Uint8List bytes;
}

final class TextRequest extends AnalysisRequest {
  const TextRequest(this.text);
  final String text;
}

/// Destinations de l'écran d'analyse, fournies par le routeur.
typedef AnalysisNavigation = ({
  ValueChanged<Analysis> onSucceeded,
  VoidCallback onClose,
  VoidCallback? onRetake,
  VoidCallback? onSearchCatalog,
});

/// Analyse en cours (MEA-03), puis photo inexploitable (MEA-08) ou erreur.
/// Fermer annule l'interrogation (SYS-07).
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({
    required this.request,
    required this.navigation,
    super.key,
  });

  final AnalysisRequest request;
  final AnalysisNavigation navigation;

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(Future.microtask(_start));
  }

  Future<void> _start() {
    final controller = ref.read(analysisControllerProvider.notifier);
    return switch (widget.request) {
      PhotoRequest(:final bytes) => controller.analyzePhoto(bytes),
      TextRequest(:final text) => controller.analyzeText(text),
    };
  }

  void _close() {
    ref.read(analysisControllerProvider.notifier).cancel();
    widget.navigation.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(analysisControllerProvider);
    ref.listen(analysisControllerProvider, (_, next) {
      if (next is AnalysisDone && !next.unusable) {
        widget.navigation.onSucceeded(next.analysis);
      }
    });
    final photo = switch (widget.request) {
      PhotoRequest(:final bytes) => bytes,
      TextRequest() => null,
    };

    final Widget body = switch (state) {
      AnalysisRunning(:final step) => _Running(photo: photo, step: step),
      AnalysisDone(unusable: true) => _Unusable(photo: photo),
      AnalysisDone() => _Running(photo: photo, step: AnalysisStep.processing),
      AnalysisError(:final failure) => EmptyState(
        icon: OmeoIcons.alert,
        title: l.appMealAnalysisErrorTitle,
        message: failureMessage(l, failure),
        actionLabel: l.commonActionRetry,
        onAction: () => unawaited(_start()),
      ),
    };
    final unusable = state is AnalysisDone && state.unusable;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(analysisControllerProvider.notifier).cancel();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              OmeoTopBar(
                title: l.appMealAnalysisTitle,
                backLabel: l.commonActionClose,
                close: true,
                onBack: _close,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: body,
                ),
              ),
              if (unusable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      OmeoButton(
                        label: l.appMealAnalysisRetake,
                        icon: OmeoIcons.camera,
                        onPressed: widget.navigation.onRetake,
                      ),
                      const SizedBox(height: OmeoTokens.space2),
                      OmeoButton(
                        label: l.appMealAnalysisSearchCatalog,
                        variant: OmeoButtonVariant.ghost,
                        onPressed: widget.navigation.onSearchCatalog,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.bytes, required this.height, this.blur = false});

  final Uint8List bytes;
  final double height;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final image = Image.memory(
      bytes,
      fit: BoxFit.cover,
      height: height,
      width: double.infinity,
      semanticLabel: AppLocalizations.of(context).appMealAnalysisPhotoLabel,
      gaplessPlayback: true,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: blur
          ? ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: image,
            )
          : image,
    );
  }
}

/// Étapes de l'analyse : les deux premières sont franchies à la mise en file,
/// la troisième tourne pendant le traitement.
class _Running extends StatelessWidget {
  const _Running({required this.photo, required this.step});

  final Uint8List? photo;
  final AnalysisStep step;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final reached = switch (step) {
      AnalysisStep.preparing || AnalysisStep.uploading => 0,
      AnalysisStep.queued => 1,
      AnalysisStep.processing => 2,
    };
    final steps = [
      l.appMealAnalysisStepDish,
      l.appMealAnalysisStepIngredients,
      l.appMealAnalysisStepPortions,
      l.appMealAnalysisStepNutrients,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photo != null) _Photo(bytes: photo!, height: 340),
        const SizedBox(height: OmeoTokens.space6),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(l.appMealAnalysisHeading, style: text.headlineMedium),
        ),
        const SizedBox(height: OmeoTokens.space4),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _StepRow(
              label: steps[i],
              done: i < reached,
              active: i == reached,
            ),
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.done,
    required this.active,
  });

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    return Row(
      children: [
        SizedBox.square(
          dimension: 22,
          child: active
              ? const OmeoSpinner(size: 22)
              : SelectionMark(selected: done, square: false),
        ),
        const SizedBox(width: OmeoTokens.space3),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: done ? t.text : t.text3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Photo floue ou sans nourriture (MEA-08) : non décomptée du quota.
class _Unusable extends StatelessWidget {
  const _Unusable({required this.photo});

  final Uint8List? photo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        if (photo != null) _Photo(bytes: photo!, height: 300, blur: true),
        const SizedBox(height: OmeoTokens.space4),
        const BadgeIcon(
          OmeoIcons.camera,
          tone: OmeoTone.warning,
          size: BadgeSize.large,
          round: true,
        ),
        const SizedBox(height: OmeoTokens.space4),
        Semantics(
          header: true,
          child: Text(
            l.appMealAnalysisUnusableTitle,
            style: text.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: OmeoTokens.space2),
        Text(
          l.appMealAnalysisUnusableBody,
          style: text.bodyMedium?.copyWith(color: t.text2),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        OmeoCard(
          variant: OmeoCardVariant.sunk,
          child: Column(
            children: [
              for (final tip in [
                l.appMealAnalysisTipTop,
                l.appMealAnalysisTipLight,
                l.appMealAnalysisTipStill,
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const OmeoIcon(OmeoIcons.check, size: 18),
                      const SizedBox(width: OmeoTokens.space2),
                      Expanded(child: Text(tip, style: text.bodySmall)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
