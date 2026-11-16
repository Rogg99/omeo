import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/units/units.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/auth/application/session.dart';
import 'package:omeo/features/profile/application/unit_preferences.dart';
import 'package:omeo/features/profile/presentation/unit_format.dart';
import 'package:omeo/features/tracking/application/tracking_controllers.dart';
import 'package:omeo_api/omeo_api.dart';

/// Ajoute de l'eau et confirme par un message : enregistré, ou en attente
/// du réseau. Annulable pendant quelques secondes (SYS-07).
Future<void> addWaterWithFeedback(
  BuildContext context,
  WidgetRef ref, {
  required int amountMl,
  required DateTime date,
}) async {
  final l = AppLocalizations.of(context);
  final writer = ref.read(waterWriterProvider);
  unawaited(HapticFeedback.lightImpact());
  try {
    final outcome = await writer.add(amountMl: amountMl, date: date);
    if (!context.mounted) return;
    switch (outcome) {
      case TrackingSaved():
        showOmeoToast(
          context,
          l.appJournalWaterSaved,
          icon: OmeoIcons.drop,
          actionLabel: l.appJournalUndo,
          onAction: () =>
              unawaited(writer.add(amountMl: -amountMl, date: date)),
        );
      case TrackingQueued():
        showOmeoToast(
          context,
          l.appJournalWaterQueued,
          icon: OmeoIcons.cloudUp,
        );
    }
  } on Object catch (error) {
    if (context.mounted) showOmeoToast(context, failureMessage(l, error));
  }
}

/// Ajouter de l'eau (HIS-03) : verre, bouteille ou quantité libre.
Future<void> showWaterSheet(BuildContext context, {required Water water}) {
  final l = AppLocalizations.of(context);
  return showOmeoSheet<void>(
    context: context,
    title: l.appJournalWaterTitle,
    closeLabel: l.commonActionClose,
    builder: (_) => WaterSheet(water: water),
  );
}

class WaterSheet extends ConsumerStatefulWidget {
  const WaterSheet({required this.water, super.key});

  final Water water;

  @override
  ConsumerState<WaterSheet> createState() => _WaterSheetState();
}

class _WaterSheetState extends ConsumerState<WaterSheet> {
  late int? _amountMl = widget.water.quickAddMl.firstOrNull;
  final _custom = TextEditingController();
  bool _customMode = false;

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  UnitSystem get _volume =>
      ref.watch(meProvider).value?.preferences.volumeSystem ??
      UnitSystem.metric;

  /// Quantité libre saisie dans l'unité de l'utilisateur, en ml pour l'API.
  int? get _customMl {
    final value = double.tryParse(_custom.text.trim().replaceAll(',', '.'));
    if (value == null || value <= 0) return null;
    final ml = Units.clToMl(Units.volumeToApi(value, _volume));
    return ml > 3000 ? null : ml;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final gauge = widget.water.gauge;
    final volume = _volume;
    final amount = _customMode ? _customMl : _amountMl;

    Widget option(
      OmeoIcons icon,
      String title,
      String sub, {
      required bool selected,
      required VoidCallback onTap,
    }) => Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: OmeoCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: selected
                  ? Border.all(color: t.dataWater, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(OmeoTokens.rMd),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  BadgeIcon(icon, tone: OmeoTone.info, round: true),
                  const SizedBox(height: 8),
                  Text(title, style: text.labelLarge),
                  Text(sub, style: text.bodySmall?.copyWith(color: t.text3)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final quick = widget.water.quickAddMl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: OmeoRing(
            size: 170,
            stroke: 14,
            progress: gauge.percent / 100,
            color: t.dataWater,
            trackColor: t.infoSoft,
            semanticLabel: l.appJournalWaterOf(
              context.water(gauge.value, volume),
              context.water(gauge.target, volume),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.water(gauge.value, volume),
                  style: text.headlineMedium,
                ),
                Text(
                  l.appJournalWaterTarget(context.water(gauge.target, volume)),
                  style: text.bodySmall?.copyWith(color: t.text3),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: OmeoTokens.space6),
        Row(
          children: [
            for (var i = 0; i < quick.length && i < 2; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              option(
                i == 0 ? OmeoIcons.cup : OmeoIcons.drop,
                i == 0 ? l.appJournalWaterGlass : l.appJournalWaterBottle,
                context.water(quick[i], volume),
                selected: !_customMode && _amountMl == quick[i],
                onTap: () => setState(() {
                  _customMode = false;
                  _amountMl = quick[i];
                }),
              ),
            ],
            const SizedBox(width: 8),
            option(
              OmeoIcons.edit,
              l.appJournalWaterOther,
              l.appJournalWaterFree,
              selected: _customMode,
              onTap: () => setState(() => _customMode = true),
            ),
          ],
        ),
        if (_customMode) ...[
          const SizedBox(height: OmeoTokens.space4),
          OmeoTextField(
            controller: _custom,
            autofocus: true,
            hint: '0',
            unit: volume == UnitSystem.metric
                ? l.appJournalUnitCl
                : l.appJournalUnitOz,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
              LengthLimitingTextInputFormatter(5),
            ],
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: OmeoTokens.space5),
        OmeoButton(
          label: amount == null
              ? l.appJournalWaterAdd
              : l.appJournalWaterQuick(context.water(amount, volume)),
          onPressed: amount == null
              ? null
              : () {
                  Navigator.of(context).pop();
                  unawaited(
                    addWaterWithFeedback(
                      context,
                      ref,
                      amountMl: amount,
                      date: widget.water.date,
                    ),
                  );
                },
        ),
      ],
    );
  }
}
