import 'dart:async';

import 'package:flutter/material.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo_api/omeo_api.dart'
    show Activity, ActivitySource_Enum, MergeSuggestion;

/// Propose de fusionner une saisie manuelle avec la séance importée qui la
/// chevauche (SPO-03).
Future<void> showMergeSheet(
  BuildContext context, {
  required MergeSuggestion suggestion,
  required List<Activity> activities,
  required Future<void> Function() onKeepImported,
}) {
  final l = AppLocalizations.of(context);
  Activity? find(String id) => activities.where((a) => a.id == id).firstOrNull;
  final imported = find(suggestion.importedId);
  final manual = find(suggestion.manualId);
  if (imported == null || manual == null) return Future.value();
  return showOmeoSheet<void>(
    context: context,
    title: l.appActivityMergeTitle,
    closeLabel: l.commonActionClose,
    builder: (sheetContext) => MergeSheet(
      message: suggestion.message ?? l.appActivityMergeBody,
      imported: imported,
      manual: manual,
      onKeepImported: () async {
        final messenger = ScaffoldMessenger.of(sheetContext);
        try {
          await onKeepImported();
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        } on ApiFailure catch (e) {
          messenger.showSnackBar(
            SnackBar(content: Text(failureMessage(l, e))),
          );
        }
      },
      onKeepBoth: () => Navigator.of(sheetContext).pop(),
    ),
  );
}

/// Contenu de la feuille de fusion : les deux activités, puis le choix.
class MergeSheet extends StatelessWidget {
  const MergeSheet({
    required this.message,
    required this.imported,
    required this.manual,
    required this.onKeepImported,
    required this.onKeepBoth,
    super.key,
  });

  final String message;
  final Activity imported;
  final Activity manual;
  final Future<void> Function() onKeepImported;
  final VoidCallback onKeepBoth;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;

    Widget option(Activity a) {
      final start = a.startedAt?.toLocal();
      final ml = MaterialLocalizations.of(context);
      final time = start == null
          ? ''
          : '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(start))} · ';
      final source = l.appActivitySource(
        a.source_ == ActivitySource_Enum.manual ? 'manual' : a.source_.value,
      );
      return OmeoCard(
        variant: OmeoCardVariant.flat,
        child: Row(
          children: [
            BadgeIcon(
              a.source_ == ActivitySource_Enum.manual
                  ? OmeoIcons.edit
                  : OmeoIcons.heart,
              tone: a.source_ == ActivitySource_Enum.manual
                  ? OmeoTone.neutral
                  : OmeoTone.primary,
            ),
            const SizedBox(width: OmeoTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$time${a.label ?? l.appActivityType(a.type)}',
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$source · '
                    '${l.appActivityActivityDetail(a.durationS ~/ 60, a.kcal)}',
                    style: text.labelSmall?.copyWith(color: t.text2),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: text.bodySmall?.copyWith(color: t.text2)),
        const SizedBox(height: OmeoTokens.space4),
        option(imported),
        const SizedBox(height: 10),
        option(manual),
        const SizedBox(height: 20),
        OmeoButton(
          label: l.appActivityMergeKeepImported,
          onPressed: () => unawaited(onKeepImported()),
        ),
        const SizedBox(height: OmeoTokens.space2),
        OmeoButton(
          label: l.appActivityMergeKeepBoth,
          variant: OmeoButtonVariant.outline,
          onPressed: onKeepBoth,
        ),
      ],
    );
  }
}
