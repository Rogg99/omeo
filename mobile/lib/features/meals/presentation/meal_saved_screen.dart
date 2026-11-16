import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/meals/data/meals_repository.dart';
import 'package:omeo_api/omeo_api.dart'
    show
        FeedbackInput,
        FeedbackInputRatingEnum,
        FeedbackReason,
        GaugeStatusEnum,
        MealWriteResult;

/// Repas enregistré (MEA-09) : célébration courte, points gagnés, reste du
/// jour renvoyé par l'API, et avis sur l'analyse en un geste.
class MealSavedScreen extends ConsumerStatefulWidget {
  const MealSavedScreen({
    required this.result,
    required this.onDone,
    super.key,
    this.corrections = 0,
  });

  final MealWriteResult result;
  final VoidCallback onDone;

  /// Corrections faites à l'écran de vérification, jointes à un avis négatif.
  final int corrections;

  @override
  ConsumerState<MealSavedScreen> createState() => _MealSavedScreenState();
}

class _MealSavedScreenState extends ConsumerState<MealSavedScreen> {
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    unawaited(HapticFeedback.mediumImpact());
  }

  Future<void> _send(FeedbackInput feedback) async {
    final analysisId = widget.result.meal.analysisId;
    if (analysisId == null) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(mealsRepositoryProvider)
          .sendFeedback(analysisId: analysisId, feedback: feedback);
      if (mounted) setState(() => _sent = true);
      messenger.showSnackBar(SnackBar(content: Text(l.appMealSavedThanks)));
    } on ApiFailure catch (e) {
      ref.read(globalErrorBusProvider).report(e);
      messenger.showSnackBar(SnackBar(content: Text(failureMessage(l, e))));
    }
  }

  Future<void> _negative() async {
    final l = AppLocalizations.of(context);
    final feedback = await showOmeoSheet<FeedbackInput>(
      context: context,
      title: l.appMealFeedbackTitle,
      closeLabel: l.commonActionClose,
      builder: (_) => NegativeFeedbackSheet(corrections: widget.corrections),
    );
    if (feedback != null) await _send(feedback);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final day = widget.result.day;
    final kcal = day.kcal;
    final over = kcal.status == GaugeStatusEnum.over && kcal.overBy != null;
    final points = widget.result.rewards.points;
    final askFeedback =
        widget.result.meal.analysisId != null &&
        widget.result.meal.feedbackGiven != true &&
        !_sent;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 64, 20, 24),
          child: Column(
            children: [
              OmeoRing(
                progress: kcal.percent / 100,
                size: 150,
                semanticLabel: l.appMealSavedRing(kcal.percent),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: t.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: OmeoIcon(
                      OmeoIcons.check,
                      size: 36,
                      color: t.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: OmeoTokens.space6),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  l.appMealDishSaved(widget.result.meal.mealType.value),
                  style: text.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: OmeoTokens.space2),
              Text(
                over
                    ? l.appMealSavedOver(l.commonUnitKcal(kcal.overBy!))
                    : l.appMealSavedRemaining(
                        l.commonUnitKcal(kcal.remaining ?? 0),
                      ),
                style: text.bodyMedium?.copyWith(color: t.text2),
                textAlign: TextAlign.center,
              ),
              if (points > 0) ...[
                const SizedBox(height: OmeoTokens.space4),
                OmeoTag(
                  l.appMealSavedPoints(points),
                  tone: OmeoTone.accent,
                  icon: OmeoIcons.star,
                ),
              ],
              if (askFeedback) ...[
                const SizedBox(height: OmeoTokens.space8),
                OmeoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.appMealSavedFeedbackTitle,
                        style: text.titleMedium,
                      ),
                      const SizedBox(height: OmeoTokens.space1),
                      Text(
                        l.appMealSavedFeedbackBody,
                        style: text.bodySmall?.copyWith(color: t.text2),
                      ),
                      const SizedBox(height: OmeoTokens.space4),
                      Row(
                        children: [
                          Expanded(
                            child: OmeoButton(
                              label: l.appMealSavedYes,
                              icon: OmeoIcons.thumbUp,
                              variant: OmeoButtonVariant.outline,
                              size: OmeoButtonSize.medium,
                              onPressed: () => unawaited(
                                _send(
                                  FeedbackInput(
                                    rating: FeedbackInputRatingEnum.up,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OmeoButton(
                              label: l.appMealSavedNo,
                              icon: OmeoIcons.thumbDown,
                              variant: OmeoButtonVariant.outline,
                              size: OmeoButtonSize.medium,
                              onPressed: () => unawaited(_negative()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: OmeoButton(label: l.appMealSavedDone, onPressed: widget.onDone),
      ),
    );
  }
}

/// Avis négatif (MEA-10) : motif en un geste, commentaire facultatif. Les
/// corrections faites sont jointes automatiquement par l'API.
class NegativeFeedbackSheet extends StatefulWidget {
  const NegativeFeedbackSheet({required this.corrections, super.key});

  final int corrections;

  @override
  State<NegativeFeedbackSheet> createState() => _NegativeFeedbackSheetState();
}

class _NegativeFeedbackSheetState extends State<NegativeFeedbackSheet> {
  FeedbackReason? _reason;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final reason in FeedbackReason.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OmeoOption(
              title: l.appMealFeedbackReason(reason.value),
              selected: _reason == reason,
              onTap: () => setState(() => _reason = reason),
            ),
          ),
        const SizedBox(height: OmeoTokens.space2),
        TextField(
          controller: _comment,
          minLines: 2,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(hintText: l.appMealFeedbackCommentHint),
        ),
        if (widget.corrections > 0) ...[
          const SizedBox(height: OmeoTokens.space2),
          OmeoBanner(
            icon: OmeoIcons.info,
            child: Text(l.appMealFeedbackCorrections(widget.corrections)),
          ),
        ],
        const SizedBox(height: OmeoTokens.space4),
        OmeoButton(
          label: l.appMealFeedbackSend,
          onPressed: _reason == null
              ? null
              : () => Navigator.of(context).pop(
                  FeedbackInput(
                    rating: FeedbackInputRatingEnum.down,
                    reason: _reason,
                    comment: _comment.text.trim().isEmpty
                        ? null
                        : _comment.text.trim(),
                  ),
                ),
        ),
      ],
    );
  }
}
