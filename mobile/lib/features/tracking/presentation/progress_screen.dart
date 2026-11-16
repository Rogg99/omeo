import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/formatters.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/tracking/application/home_controller.dart';
import 'package:omeo/features/tracking/application/tracking_controllers.dart';
import 'package:omeo/features/tracking/data/health.dart';
import 'package:omeo/features/tracking/data/tracking_repository.dart';
import 'package:omeo_api/omeo_api.dart';

/// Actions de la progression, fournies par le routeur.
typedef ProgressNavigation = ({
  VoidCallback? discoverPlus,
  VoidCallback? scanMeal,
  VoidCallback? connectHealth,
  VoidCallback? openWeight,
});

/// Valeur avec une décimale au plus (sel en grammes), sans calcul métier.
String _value(BuildContext context, num v) => v is int || v == v.roundToDouble()
    ? context.number(v.round())
    : context.number((v * 10).round() / 10);

/// Progression (PRO-01 à PRO-04) : courbe par nutriment, périodes Plus
/// verrouillées en Free, santé et résumé du jour.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({required this.navigation, super.key});

  final ProgressNavigation navigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final selection = ref.watch(progressSelectionProvider);
    final allowed = ref.watch(longRangeAllowedProvider);
    final locked = selection.range != ProgressRange.week && !allowed;
    // Une période verrouillée ne demande rien à l'API : aperçu flouté.
    final progress = locked
        ? null
        : ref.watch(
            progressProvider((
              metric: selection.metric,
              range: selection.range,
            )),
          );
    final weekly = ref.watch(
      progressProvider((metric: selection.metric, range: ProgressRange.week)),
    );

    Future<void> refresh() async {
      ref
        ..invalidate(progressProvider)
        ..invalidate(homeProvider);
      await ref.read(
        progressProvider((
          metric: selection.metric,
          range: ProgressRange.week,
        )).future,
      );
    }

    final empty = weekly.value?.empty ?? false;
    final health = weekly.value?.health;

    final body = switch (progress ?? weekly) {
      _ when empty => _EmptyProgress(onScan: navigation.scanMeal),
      AsyncValue(:final error?) when !locked => EmptyState(
        icon: OmeoIcons.alert,
        title: l.appProgressLoadError,
        message: failureMessage(l, error),
        actionLabel: l.commonActionRetry,
        onAction: () => unawaited(refresh()),
      ),
      AsyncValue(:final value?) => _ChartCard(
        progress: locked ? null : value,
        locked: locked,
        onDiscoverPlus: navigation.discoverPlus,
      ),
      _ => const Skeleton(height: 360, radius: OmeoTokens.rLg),
    };

    return RefreshIndicator(
      onRefresh: refresh,
      child: CustomScrollView(
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverToBoxAdapter(
              child: OmeoTopBar(
                title: l.appNavProgress,
                backLabel: l.commonActionBack,
                trailing: OmeoIconButton(
                  icon: OmeoIcons.refresh,
                  semanticLabel: l.appProgressRefresh,
                  onPressed: () => unawaited(refresh()),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.list(
              children: [
                body,
                if (health != null &&
                    (health.connected ||
                        ref.watch(healthAccessProvider) != null))
                  Padding(
                    padding: const EdgeInsets.only(top: OmeoTokens.space4),
                    child: HealthCard(
                      connection: health,
                      onConnect: navigation.connectHealth,
                    ),
                  ),
                if (!empty) ...[
                  const SizedBox(height: OmeoTokens.space6),
                  const _TodayGrid(),
                ],
                const SizedBox(height: OmeoTokens.space4),
                OmeoList(
                  children: [
                    OmeoListTile(
                      icon: OmeoIcons.scale,
                      iconTone: OmeoTone.neutral,
                      title: l.appProgressWeightTitle,
                      onTap: navigation.openWeight,
                    ),
                  ],
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte principale : total du jour, onglets, périodes et courbe.
class _ChartCard extends ConsumerWidget {
  const _ChartCard({
    required this.progress,
    required this.locked,
    this.onDiscoverPlus,
  });

  /// `null` quand la période est verrouillée (aperçu flouté).
  final Progress? progress;
  final bool locked;
  final VoidCallback? onDiscoverPlus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final selection = ref.watch(progressSelectionProvider);
    final controller = ref.read(progressSelectionProvider.notifier);
    final allowed = ref.watch(longRangeAllowedProvider);
    final p = progress;
    final salt = selection.metric == ProgressMetric.salt;
    final unit = (p?.unit ?? ProgressUnitEnum.kcal) == ProgressUnitEnum.kcal
        ? l.appProgressUnitKcal
        : l.appProgressUnitGrams;
    final locale = Localizations.localeOf(context).toLanguageTag();

    final metrics = [
      (ProgressMetric.kcal, OmeoIcons.flame, l.appProgressMetricKcal),
      (ProgressMetric.carbs, OmeoIcons.wheat, l.appProgressMetricCarbs),
      (ProgressMetric.fat, OmeoIcons.drop, l.appProgressMetricFat),
      (ProgressMetric.protein, OmeoIcons.beef, l.appProgressMetricProtein),
      (ProgressMetric.fiber, OmeoIcons.leaf, l.appProgressMetricFiber),
      (ProgressMetric.salt, OmeoIcons.salt, l.appProgressMetricSalt),
    ];
    final ranges = [
      (ProgressRange.week, l.appProgressRange7),
      (ProgressRange.month, l.appProgressRange30),
      (ProgressRange.quarter, l.appProgressRange90),
      (ProgressRange.year, l.appProgressRange365),
    ];

    final points = [
      for (final s in p?.series ?? const <ProgressSeriesInner>[])
        if (s.value != null) s,
    ];
    final values = [for (final s in points) s.value!.toDouble()];
    final chartLabel = p == null
        ? l.appProgressLockedTitle
        : l.appProgressChartLabel(
            _value(context, p.today),
            unit,
            p.average == null ? '—' : _value(context, p.average!),
          );

    final Widget chart;
    if (locked || p == null) {
      chart = _LockedPreview(onDiscoverPlus: onDiscoverPlus);
    } else if (values.isEmpty) {
      chart = SizedBox(
        height: 150,
        child: Center(
          child: Text(
            l.appProgressNoData,
            style: text.bodyMedium?.copyWith(color: t.text3),
          ),
        ),
      );
    } else if (salt ||
        selection.range == ProgressRange.week && values.length <= 7) {
      chart = RepaintBoundary(
        child: OmeoBarChart(
          values: values,
          labels: [
            for (final s in points) DateFormat.E(locale).format(s.date),
          ],
          color: salt ? t.dataSalt : null,
          semanticLabel: chartLabel,
        ),
      );
    } else {
      chart = RepaintBoundary(
        child: OmeoLineChart(
          values: values,
          goal: p.target?.toDouble(),
          semanticLabel: chartLabel,
        ),
      );
    }

    return OmeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (p != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.appHomeToday,
                        style: text.bodyMedium?.copyWith(color: t.text2),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: _value(context, p.today)),
                              TextSpan(
                                text: ' $unit',
                                style: TextStyle(fontSize: 18, color: t.text3),
                              ),
                            ],
                          ),
                          style: text.displaySmall?.copyWith(fontSize: 40),
                        ),
                      ),
                    ],
                  ),
                ),
                if (p.deltaPercent != null)
                  OmeoTag(
                    l.appProgressDeltaYesterday(
                      context.signedNumber(p.deltaPercent!),
                    ),
                    icon: OmeoIcons.trend,
                  ),
              ],
            ),
          const SizedBox(height: OmeoTokens.space4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (metric, icon, label) in metrics) ...[
                  OmeoChip(
                    label: label,
                    icon: icon,
                    selected: selection.metric == metric,
                    onTap: () => controller.metric(metric),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: OmeoTokens.space4),
          OmeoSegmented<ProgressRange>(
            segments: [
              for (final (range, label) in ranges)
                (
                  value: range,
                  label: range == ProgressRange.week || allowed
                      ? label
                      : l.appProgressRangeLocked(label),
                ),
            ],
            selected: selection.range,
            onChanged: controller.range,
          ),
          const SizedBox(height: OmeoTokens.space5),
          chart,
          if (p != null && !locked) ...[
            const SizedBox(height: OmeoTokens.space3),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              children: [
                if (p.target != null)
                  Text(
                    l.appProgressTarget(_value(context, p.target!), unit),
                    style: text.bodySmall?.copyWith(color: t.text2),
                  ),
                if (p.average != null)
                  Text(
                    l.appProgressAverage(_value(context, p.average!), unit),
                    style: text.bodySmall?.copyWith(color: t.text2),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Période réservée à Plus (PRO-03) : aperçu flouté et explication, sans
/// cul-de-sac.
class _LockedPreview extends StatelessWidget {
  const _LockedPreview({this.onDiscoverPlus});

  final VoidCallback? onDiscoverPlus;

  static const List<double> _shape = [
    2200.0,
    2400,
    2100,
    2500,
    2300,
    2000,
    2250,
    2350,
    2150,
    2450,
    2200,
    2050,
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        ExcludeSemantics(
          child: Opacity(
            opacity: 0.6,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: const OmeoLineChart(values: _shape, semanticLabel: ''),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BadgeIcon(
                OmeoIcons.lock,
                tone: OmeoTone.contrast,
                round: true,
              ),
              const SizedBox(height: 8),
              Text(
                l.appProgressLockedTitle,
                textAlign: TextAlign.center,
                style: text.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                l.appProgressLockedBody,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: t.text2),
              ),
              if (onDiscoverPlus != null) ...[
                const SizedBox(height: 12),
                OmeoButton(
                  label: l.commonPlusDiscover,
                  size: OmeoButtonSize.small,
                  expand: false,
                  onPressed: onDiscoverPlus,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Avant les premiers repas (PRO-04).
class _EmptyProgress extends StatelessWidget {
  const _EmptyProgress({this.onScan});

  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    return OmeoCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          ExcludeSemantics(
            child: CustomPaint(
              size: const Size(200, 110),
              painter: _EmptyCurvePainter(line: t.lineStrong, dot: t.accent),
            ),
          ),
          const SizedBox(height: OmeoTokens.space4),
          Text(l.appProgressEmptyTitle, style: text.headlineSmall),
          const SizedBox(height: OmeoTokens.space2),
          Text(
            l.appProgressEmptyBody,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: t.text2),
          ),
          if (onScan != null) ...[
            const SizedBox(height: OmeoTokens.space5),
            OmeoButton(
              label: l.appProgressScanMeal,
              icon: OmeoIcons.camera,
              size: OmeoButtonSize.medium,
              expand: false,
              onPressed: onScan,
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCurvePainter extends CustomPainter {
  const _EmptyCurvePainter({required this.line, required this.dot});

  final Color line;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(10, 95)
      ..cubicTo(40, 90, 50, 60, 80, 65)
      ..cubicTo(110, 70, 130, 30, 190, 20);
    final paint = Paint()
      ..color = line
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 14) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
    canvas
      ..drawCircle(const Offset(190, 20), 7, Paint()..color = dot)
      ..drawRect(const Rect.fromLTWH(0, 100, 200, 2), Paint()..color = line);
  }

  @override
  bool shouldRepaint(_EmptyCurvePainter old) =>
      old.line != line || old.dot != dot;
}

/// Carte Health Connect / Apple Health : lecture seule, état et connexion.
class HealthCard extends StatelessWidget {
  const HealthCard({required this.connection, super.key, this.onConnect});

  final HealthConnection connection;
  final VoidCallback? onConnect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final connected = connection.connected;
    final source = connection.source_ == HealthConnectionSource_Enum.appleHealth
        ? l.appProgressAppleHealth
        : l.appProgressHealthConnect;
    final sync = connection.lastSyncAt;
    return OmeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              BadgeIcon(
                OmeoIcons.heart,
                tone: connected ? OmeoTone.primary : OmeoTone.contrast,
              ),
              const SizedBox(width: OmeoTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(source, style: text.titleSmall),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        OmeoTag(
                          connected
                              ? l.appProgressHealthConnected
                              : l.appProgressHealthNotConnected,
                          tone: connected ? OmeoTone.primary : OmeoTone.neutral,
                          icon: connected ? OmeoIcons.check : null,
                        ),
                        OmeoTag(
                          l.appProgressHealthReadOnly,
                          tone: OmeoTone.neutral,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OmeoTokens.space4),
          _InfoLine(
            icon: OmeoIcons.download,
            text: connection.readTypesLabel ?? l.appProgressHealthReads,
          ),
          const SizedBox(height: 8),
          _InfoLine(icon: OmeoIcons.ban, text: l.appProgressHealthWrites),
          const SizedBox(height: 12),
          if (connected && sync != null)
            Text(
              l.appProgressHealthSynced(
                DateFormat.Hm(
                  Localizations.localeOf(context).toLanguageTag(),
                ).format(sync.toLocal()),
                context.shortDate(sync.toLocal()),
              ),
              style: text.bodySmall?.copyWith(color: t.text3),
            )
          else if (!connected) ...[
            Text(
              l.appProgressHealthPitch,
              style: text.bodyMedium?.copyWith(color: t.text2),
            ),
            if (onConnect != null) ...[
              const SizedBox(height: OmeoTokens.space4),
              OmeoButton(
                label: l.appProgressHealthConnectAction(source),
                size: OmeoButtonSize.medium,
                onPressed: onConnect,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final OmeoIcons icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      OmeoIcon(icon, size: 18, color: context.omeo.text2),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      ),
    ],
  );
}

/// Résumé du jour : les six nutriments de l'accueil (valeurs de l'API).
class _TodayGrid extends ConsumerWidget {
  const _TodayGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final day = ref.watch(homeProvider).value?.day;
    if (day == null) return const SizedBox.shrink();
    final cells = [
      (
        l.appProgressMetricKcal,
        day.kcal,
        l.appProgressUnitKcal,
        OmeoTokens.sage700,
      ),
      (
        l.appProgressMetricCarbs,
        day.carbs,
        l.appProgressUnitGrams,
        OmeoTokens.sage600,
      ),
      (
        l.appProgressMetricFat,
        day.fat,
        l.appProgressUnitGrams,
        OmeoTokens.brown600,
      ),
      (
        l.appProgressMetricProtein,
        day.protein,
        l.appProgressUnitGrams,
        OmeoTokens.brown700,
      ),
      (
        l.appProgressMetricFiber,
        day.fiber,
        l.appProgressUnitGrams,
        OmeoTokens.sage800,
      ),
      (
        l.appProgressMetricSalt,
        day.salt,
        l.appProgressUnitGrams,
        OmeoTokens.ink950,
      ),
    ];
    const ink = OmeoTokens.cream50;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l.appHomeToday, style: text.titleMedium),
        ),
        const SizedBox(height: OmeoTokens.space3),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            for (final (label, gauge, unit, color) in cells)
              if (gauge != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(OmeoTokens.rLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: text.bodySmall?.copyWith(
                          color: ink.withValues(alpha: 0.75),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          '${_value(context, gauge.value)} $unit',
                          style: text.headlineSmall?.copyWith(color: ink),
                        ),
                      ),
                      OmeoBar.onColor(progress: gauge.percent / 100),
                    ],
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

/// Autorisation santé (PRO-05) : demandée au moment où elle sert ; un refus
/// n'a aucune conséquence bloquante.
class HealthPermissionScreen extends ConsumerWidget {
  const HealthPermissionScreen({required this.onDone, super.key});

  /// Fermeture, après la connexion ou « Plus tard ».
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final access = ref.watch(healthAccessProvider);
    final state = ref.watch(healthProvider);
    final source =
        access?.source == SetHealthConnectionRequestSource_Enum.appleHealth
        ? l.appProgressAppleHealth
        : l.appProgressHealthConnect;
    final items = [
      (OmeoIcons.footprints, l.appProgressHealthSteps),
      (OmeoIcons.flame, l.appProgressHealthCalories),
      (OmeoIcons.pulse, l.appProgressHealthWorkouts),
      (OmeoIcons.scale, l.appProgressHealthWeight),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OmeoTopBar(
              title: '',
              close: true,
              backLabel: l.commonActionClose,
              onBack: onDone,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const Row(
                    children: [
                      BadgeIcon(
                        OmeoIcons.sparkles,
                        tone: OmeoTone.contrast,
                        size: BadgeSize.large,
                      ),
                      SizedBox(width: 12),
                      OmeoIcon(OmeoIcons.chevsLR, size: 20),
                      SizedBox(width: 12),
                      BadgeIcon(
                        OmeoIcons.heart,
                        tone: OmeoTone.info,
                        size: BadgeSize.large,
                      ),
                    ],
                  ),
                  const SizedBox(height: OmeoTokens.space6),
                  Semantics(
                    header: true,
                    child: Text(
                      l.appProgressPermissionTitle,
                      style: text.headlineLarge,
                    ),
                  ),
                  const SizedBox(height: OmeoTokens.space2),
                  Text(
                    l.appProgressPermissionBody,
                    style: text.bodyLarge?.copyWith(color: t.text2),
                  ),
                  const SizedBox(height: OmeoTokens.space6),
                  OmeoList(
                    children: [
                      for (final (icon, label) in items)
                        OmeoListTile(
                          leading: BadgeIcon(icon, size: BadgeSize.small),
                          title: label,
                          showChevron: false,
                          trailing: OmeoTag(
                            l.appProgressHealthReadTag,
                            tone: OmeoTone.neutral,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: OmeoTokens.space4),
                  OmeoBanner(
                    icon: OmeoIcons.shieldCheck,
                    tone: OmeoTone.primary,
                    child: Text(l.appProgressPermissionPrivacy(source)),
                  ),
                  if (state.hasError) ...[
                    const SizedBox(height: OmeoTokens.space3),
                    Text(
                      failureMessage(l, state.error!),
                      style: text.bodySmall?.copyWith(color: t.danger),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  OmeoButton(
                    label: l.appProgressPermissionContinue(source),
                    loading: state.isLoading,
                    onPressed: access == null
                        ? null
                        : () async {
                            final ok = await ref
                                .read(healthProvider.notifier)
                                .connect();
                            if (!context.mounted) return;
                            if (!ok && !ref.read(healthProvider).hasError) {
                              showOmeoToast(
                                context,
                                l.appProgressPermissionDenied,
                              );
                            }
                            if (ok) onDone();
                          },
                  ),
                  const SizedBox(height: OmeoTokens.space2),
                  OmeoButton(
                    label: l.appProgressPermissionLater,
                    variant: OmeoButtonVariant.ghost,
                    onPressed: onDone,
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
