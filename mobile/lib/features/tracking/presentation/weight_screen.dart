import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/formatters.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/units/units.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/auth/application/session.dart';
import 'package:omeo/features/profile/application/unit_preferences.dart';
import 'package:omeo/features/profile/presentation/unit_format.dart';
import 'package:omeo/features/tracking/application/tracking_controllers.dart';
import 'package:omeo/features/tracking/data/tracking_repository.dart';
import 'package:omeo_api/omeo_api.dart';

/// Suivi du poids (PRO-06) : courbe avec cible, écart restant, tendance et
/// source de chaque mesure.
class WeightScreen extends ConsumerWidget {
  const WeightScreen({super.key, this.onReminderSettings});

  /// Réglage du rappel de pesée (notifications).
  final VoidCallback? onReminderSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final range = ref.watch(weightRangeProvider);
    final overview = ref.watch(weightsProvider(range));
    final unit =
        ref.watch(meProvider).value?.preferences.weightSystem ??
        UnitSystem.metric;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            OmeoTopBar(
              title: l.appProgressWeightTitle,
              backLabel: l.commonActionBack,
              trailing: onReminderSettings == null
                  ? null
                  : OmeoIconButton(
                      icon: OmeoIcons.settings,
                      semanticLabel: l.appProgressWeightReminder,
                      onPressed: onReminderSettings,
                    ),
            ),
            Expanded(
              child: switch (overview) {
                AsyncValue(:final value?) => _WeightContent(
                  overview: value,
                  range: range,
                  unit: unit,
                ),
                AsyncValue(:final error?) => EmptyState(
                  icon: OmeoIcons.alert,
                  title: l.appProgressLoadError,
                  message: failureMessage(l, error),
                  actionLabel: l.commonActionRetry,
                  onAction: () => ref.invalidate(weightsProvider(range)),
                ),
                _ => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Skeleton(height: 320, radius: OmeoTokens.rLg),
                ),
              },
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: OmeoButton(
          label: l.appProgressWeightAdd,
          icon: OmeoIcons.plus,
          onPressed: () => unawaited(
            showWeighInSheet(
              context,
              initialKg: overview.value?.currentKg?.toDouble(),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeightContent extends ConsumerWidget {
  const _WeightContent({
    required this.overview,
    required this.range,
    required this.unit,
  });

  final WeightOverview overview;
  final WeightRange range;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final series = overview.series;
    final latest = series.isEmpty ? null : series.last;
    final current = overview.currentKg;
    final trend = overview.trendKgPerWeek;
    final values = [
      for (final s in series) Units.displayWeight(s.weightKg.toDouble(), unit),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: [
        OmeoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                latest == null
                    ? l.appProgressWeightCurrent
                    : l.appProgressWeightCurrentOn(
                        context.shortDate(latest.date),
                      ),
                style: text.bodyMedium?.copyWith(color: t.text2),
              ),
              Text(
                current == null ? '—' : context.weight(current, unit),
                style: text.displaySmall?.copyWith(fontSize: 44),
              ),
              const SizedBox(height: OmeoTokens.space4),
              OmeoSegmented<WeightRange>(
                segments: [
                  (value: WeightRange.month, label: l.appProgressWeightRange1m),
                  (
                    value: WeightRange.quarter,
                    label: l.appProgressWeightRange3m,
                  ),
                  (value: WeightRange.year, label: l.appProgressWeightRange1y),
                ],
                selected: range,
                onChanged: (r) =>
                    ref.read(weightRangeProvider.notifier).range = r,
              ),
              const SizedBox(height: OmeoTokens.space5),
              if (values.length < 2)
                SizedBox(
                  height: 150,
                  child: Center(
                    child: Text(
                      l.appProgressWeightFewPoints,
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: t.text3),
                    ),
                  ),
                )
              else
                RepaintBoundary(
                  child: OmeoLineChart(
                    values: values,
                    goal: Units.displayWeight(
                      overview.targetKg.toDouble(),
                      unit,
                    ),
                    color: OmeoTokens.brown700,
                    semanticLabel: l.appProgressWeightChart(
                      current == null ? '—' : context.weight(current, unit),
                      context.weight(overview.targetKg, unit),
                    ),
                  ),
                ),
              const SizedBox(height: OmeoTokens.space3),
              Wrap(
                spacing: 14,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    l.appProgressWeightTarget(
                      context.weight(overview.targetKg, unit),
                    ),
                    style: text.bodySmall?.copyWith(color: t.text2),
                  ),
                  if (trend != null)
                    Text(
                      l.appProgressWeightTrend(
                        context.signedWeight(trend, unit),
                      ),
                      style: text.bodySmall?.copyWith(color: t.text2),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (overview.remainingKg != null) ...[
          const SizedBox(height: OmeoTokens.space3),
          OmeoCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.appProgressWeightRemaining,
                    style: text.bodyMedium?.copyWith(color: t.text2),
                  ),
                ),
                Text(
                  context.weight(overview.remainingKg!, unit),
                  style: text.titleLarge,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: OmeoTokens.space6),
        Semantics(
          header: true,
          child: Text(l.appProgressWeightMeasures, style: text.titleMedium),
        ),
        const SizedBox(height: OmeoTokens.space3),
        if (series.isEmpty)
          Text(
            l.appProgressWeightEmpty,
            style: text.bodyMedium?.copyWith(color: t.text2),
          )
        else
          OmeoList(
            children: [
              for (final s in series.reversed.take(12))
                OmeoListTile(
                  icon: s.source_ == WeightOverviewSeriesInnerSource_Enum.manual
                      ? OmeoIcons.edit
                      : OmeoIcons.heart,
                  iconTone: OmeoTone.neutral,
                  title: context.weight(s.weightKg, unit),
                  subtitle: l.appProgressWeightMeasure(
                    context.shortDate(s.date),
                    switch (s.source_) {
                      WeightOverviewSeriesInnerSource_Enum.manual =>
                        l.appProgressWeightManual,
                      WeightOverviewSeriesInnerSource_Enum.healthConnect =>
                        l.appProgressHealthConnect,
                      WeightOverviewSeriesInnerSource_Enum.appleHealth =>
                        l.appProgressAppleHealth,
                    },
                  ),
                  showChevron: false,
                  trailing:
                      s.source_ == WeightOverviewSeriesInnerSource_Enum.manual
                      ? OmeoIconButton(
                          icon: OmeoIcons.trash,
                          small: true,
                          ghost: true,
                          semanticLabel: l.appProgressWeightDelete,
                          onPressed: () => unawaited(
                            _delete(context, ref, s.id),
                          ),
                        )
                      : null,
                ),
            ],
          ),
        const SizedBox(height: 8),
        Text(
          l.appProgressWeightManualWins,
          style: text.bodySmall?.copyWith(color: t.text3),
        ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    final l = AppLocalizations.of(context);
    try {
      await ref.read(weightWriterProvider).delete(id);
      if (context.mounted) {
        showOmeoToast(
          context,
          l.appProgressWeightDeleted,
          icon: OmeoIcons.trash,
        );
      }
    } on Object catch (e) {
      if (context.mounted) showOmeoToast(context, failureMessage(l, e));
    }
  }
}

/// Nouvelle pesée (PRO-07) : saisie rapide, date modifiable.
Future<void> showWeighInSheet(BuildContext context, {double? initialKg}) {
  final l = AppLocalizations.of(context);
  return showOmeoSheet<void>(
    context: context,
    title: l.appProgressWeighInTitle,
    closeLabel: l.commonActionClose,
    builder: (_) => WeighInSheet(initialKg: initialKg),
  );
}

class WeighInSheet extends ConsumerStatefulWidget {
  const WeighInSheet({super.key, this.initialKg});

  final double? initialKg;

  @override
  ConsumerState<WeighInSheet> createState() => _WeighInSheetState();
}

class _WeighInSheetState extends ConsumerState<WeighInSheet> {
  final _input = TextEditingController();
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  bool _saving = false;
  bool _initialized = false;

  UnitSystem get _unit =>
      ref.read(meProvider).value?.preferences.weightSystem ?? UnitSystem.metric;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final kg = widget.initialKg;
    if (kg != null) _setDisplayed(Units.displayWeight(kg, _unit));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  double? get _displayed =>
      double.tryParse(_input.text.trim().replaceAll(',', '.'));

  void _setDisplayed(double value) {
    _input.text = context.number((value * 10).round() / 10);
    setState(() {});
  }

  /// Ajuste la saisie d'un dixième (aide à la saisie, aucune valeur métier).
  void _nudge(double delta) {
    final v = _displayed;
    if (v != null) _setDisplayed(v + delta);
  }

  double? get _kg {
    final v = _displayed;
    if (v == null) return null;
    final kg = Units.weightToApi(v, _unit);
    return kg < 30 || kg > 300 ? null : kg;
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final kg = _kg;
    if (kg == null) return;
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      final outcome = await ref
          .read(weightWriterProvider)
          .add(weightKg: kg, date: _date);
      if (!mounted) return;
      Navigator.of(context).pop();
      showOmeoToast(
        context,
        switch (outcome) {
          TrackingSaved(:final result) when result.rewards.points > 0 =>
            l.appProgressWeighInSavedPoints(result.rewards.points),
          TrackingSaved() => l.appProgressWeighInSaved,
          TrackingQueued() => l.appProgressWeighInQueued,
        },
        icon: OmeoIcons.check,
      );
    } on Object catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showOmeoToast(context, failureMessage(l, e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final unit = _unit;
    final unitLabel = unit == UnitSystem.metric
        ? l.appOnboardingUnitKg
        : l.appOnboardingUnitLb;
    final today = DateUtils.isSameDay(_date, DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        OmeoTextField(
          controller: _input,
          big: true,
          autofocus: widget.initialKg == null,
          unit: unitLabel,
          hint: '0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
            LengthLimitingTextInputFormatter(5),
          ],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: OmeoTokens.space4),
        Row(
          children: [
            Expanded(
              child: OmeoButton(
                label: l.appProgressWeighInStep(context.number(0.1)),
                icon: OmeoIcons.minus,
                variant: OmeoButtonVariant.outline,
                size: OmeoButtonSize.medium,
                onPressed: () => _nudge(-0.1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OmeoButton(
                label: l.appProgressWeighInStep(context.number(0.1)),
                icon: OmeoIcons.plus,
                variant: OmeoButtonVariant.outline,
                size: OmeoButtonSize.medium,
                onPressed: () => _nudge(0.1),
              ),
            ),
          ],
        ),
        const SizedBox(height: OmeoTokens.space4),
        OmeoList(
          children: [
            OmeoListTile(
              icon: OmeoIcons.calendar,
              title: today ? l.appHomeToday : context.longDate(_date),
              showChevron: false,
              trailing: TextButton(
                onPressed: _pickDate,
                child: Text(l.appProgressWeighInEditDate),
              ),
            ),
          ],
        ),
        const SizedBox(height: OmeoTokens.space3),
        OmeoBanner(
          icon: OmeoIcons.refresh,
          tone: OmeoTone.info,
          child: Text(l.appProgressWeighInRecalc),
        ),
        const SizedBox(height: OmeoTokens.space4),
        OmeoButton(
          label: l.commonActionSave,
          loading: _saving,
          onPressed: _kg == null ? null : _save,
        ),
      ],
    );
  }
}
