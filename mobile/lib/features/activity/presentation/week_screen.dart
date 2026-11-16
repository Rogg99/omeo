import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/formatters.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/activity/application/activity_controller.dart';
import 'package:omeo_api/omeo_api.dart'
    show ActivityOverview, ActivityOverviewBalanceWeekInner;

/// Balance de la semaine (SPO-04) : mangé et dépensé jour par jour, en
/// barres jumelles, avec la balance du jour renvoyée par l'API.
class WeekBalanceScreen extends ConsumerWidget {
  const WeekBalanceScreen({
    required this.onBack,
    required this.onInsights,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onInsights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final overview = ref.watch(activityOverviewProvider);
    final week = overview.value?.balanceWeek;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OmeoTopBar(
              title: l.appActivityWeekScreenTitle,
              eyebrow: week == null || week.isEmpty
                  ? null
                  : l.appActivityWeekScreenEyebrow(
                      context.shortDate(week.first.date),
                    ),
              backLabel: l.commonActionBack,
              onBack: onBack,
            ),
            Expanded(
              child: switch (overview) {
                AsyncValue(:final value?) => _WeekContent(
                  overview: value,
                  onInsights: onInsights,
                ),
                AsyncValue(:final error?) => EmptyState(
                  icon: OmeoIcons.alert,
                  title: l.appActivityErrorTitle,
                  message: failureMessage(l, error),
                  actionLabel: l.commonActionRetry,
                  onAction: () => ref.invalidate(activityOverviewProvider),
                ),
                _ => const Center(child: OmeoSpinner()),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekContent extends StatelessWidget {
  const _WeekContent({required this.overview, required this.onInsights});

  final ActivityOverview overview;
  final VoidCallback onInsights;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final b = overview.balanceDay;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: [
        OmeoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.signedNumber(b.differenceKcal),
                      style: text.displaySmall?.copyWith(
                        color: t.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  OmeoTag(l.appActivityWeekScreenTodayStatus(b.status.value)),
                ],
              ),
              const SizedBox(height: 20),
              RepaintBoundary(child: _TwinBars(days: overview.balanceWeek)),
              const SizedBox(height: OmeoTokens.space3),
              Row(
                children: [
                  _Legend(
                    color: OmeoTokens.brown700,
                    label: l.appActivityWeekScreenEaten,
                  ),
                  const SizedBox(width: 14),
                  _Legend(color: t.info, label: l.appActivityWeekScreenBurned),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: OmeoTokens.space3),
        OmeoList(
          children: [
            OmeoListTile(
              icon: OmeoIcons.sparkles,
              title: l.appActivityWeekScreenInsights,
              subtitle: l.appActivityWeekScreenInsightsHint,
              trailing: OmeoTag.plus(l.appHomePlusTag),
              onTap: onInsights,
            ),
          ],
        ),
      ],
    );
  }
}

/// Barres jumelles mangé / dépensé. La hauteur des barres est mise à
/// l'échelle de la plus grande valeur de la semaine (dessin uniquement).
class _TwinBars extends StatelessWidget {
  const _TwinBars({required this.days});

  final List<ActivityOverviewBalanceWeekInner> days;

  static const double _height = 150;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final locale = Localizations.localeOf(context).toLanguageTag();
    var max = 1;
    for (final d in days) {
      if (d.consumedKcal > max) max = d.consumedKcal;
      if (d.burnedKcal > max) max = d.burnedKcal;
    }
    double h(int v) => (_height - 24) * v / max;

    Widget bar(double height, Color color) => Expanded(
      child: Container(
        height: height < 3 ? 3 : height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ),
    );

    return Semantics(
      label: l.appActivityWeekScreenChart,
      child: SizedBox(
        height: _height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final d in days)
              Expanded(
                child: Semantics(
                  label: l.appActivityWeekScreenDay(
                    context.longDate(d.date),
                    d.consumedKcal,
                    d.burnedKcal,
                  ),
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            bar(h(d.consumedKcal), OmeoTokens.brown700),
                            const SizedBox(width: 3),
                            bar(h(d.burnedKcal), t.info),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat.E(locale).format(d.date).characters.first,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: t.text3,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: context.omeo.text2),
      ),
    ],
  );
}

/// Analyses croisées (SPO-05), Plus : constats hebdomadaires nutrition ×
/// activité calculés par l'API. En Free, l'API répond 403 plan_required et
/// la présentation de Plus s'ouvre.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  static OmeoIcons _icon(String? kind) => switch (kind) {
    'weekend_pattern' => OmeoIcons.calendar,
    'low_steps' => OmeoIcons.footprints,
    _ => OmeoIcons.sparkles,
  };

  static OmeoTone _tone(String? kind) => switch (kind) {
    'weekend_pattern' => OmeoTone.accent,
    'low_steps' => OmeoTone.info,
    _ => OmeoTone.primary,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final insights = ref.watch(insightsProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OmeoTopBar(
              title: l.appActivityInsightsTitle,
              eyebrow: l.appActivityInsightsEyebrow,
              backLabel: l.commonActionBack,
              onBack: onBack,
            ),
            Expanded(
              child: switch (insights) {
                AsyncValue(:final value?) when value.isEmpty => EmptyState(
                  icon: OmeoIcons.sparkles,
                  title: l.appActivityInsightsEmpty,
                ),
                AsyncValue(:final value?) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final insight = value[i];
                    return OmeoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BadgeIcon(
                            _icon(insight.kind),
                            tone: _tone(insight.kind),
                          ),
                          const SizedBox(height: OmeoTokens.space3),
                          Text(insight.message, style: text.titleSmall),
                        ],
                      ),
                    );
                  },
                ),
                AsyncValue(:final error?) => EmptyState(
                  icon: OmeoIcons.lock,
                  title: l.appActivityInsightsErrorTitle,
                  message: failureMessage(l, error),
                  actionLabel: l.commonActionRetry,
                  onAction: () => ref.invalidate(insightsProvider),
                ),
                _ => const Center(child: OmeoSpinner()),
              },
            ),
          ],
        ),
      ),
    );
  }
}
