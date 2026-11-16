import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/formatters.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/activity/application/activity_controller.dart';
import 'package:omeo/features/activity/data/health_reader.dart';
import 'package:omeo/features/activity/presentation/merge_sheet.dart';
import 'package:omeo_api/omeo_api.dart'
    show
        Activity,
        ActivityOverview,
        ActivitySource_Enum,
        HealthConnection,
        MergeSuggestion,
        WorkoutSummary;

/// Destinations de l'écran Sport, fournies par le routeur.
typedef SportNavigation = ({
  VoidCallback onBack,
  VoidCallback onAddActivity,
  VoidCallback onWeek,
  ValueChanged<WorkoutSummary>? onWorkout,
  VoidCallback? onAllWorkouts,
});

/// Icône d'un type d'activité, comme dans les maquettes.
OmeoIcons activityIcon(String type) => switch (type) {
  'walking' => OmeoIcons.footprints,
  'running' => OmeoIcons.run,
  'football' => OmeoIcons.ball,
  'dancing' => OmeoIcons.music,
  'cycling' => OmeoIcons.bike,
  'strength' => OmeoIcons.dumbbell,
  'swimming' => OmeoIcons.swim,
  _ => OmeoIcons.pulse,
};

/// Distance en kilomètres pour l'affichage : simple changement d'échelle
/// de la valeur en mètres renvoyée par l'API (aucun calcul métier).
String formatKm(BuildContext context, int meters) =>
    NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(double.parse((meters / 1000).toStringAsFixed(1)));

/// Sport · aujourd'hui (SPO-01) : pas, dépense, balance, activités avec leur
/// source et séances suggérées. Synchronise la santé à l'ouverture.
class SportScreen extends ConsumerStatefulWidget {
  const SportScreen({required this.navigation, super.key});

  final SportNavigation navigation;

  @override
  ConsumerState<SportScreen> createState() => _SportScreenState();
}

class _SportScreenState extends ConsumerState<SportScreen> {
  bool _synced = false;
  bool _connecting = false;

  /// Synchronisation à l'ouverture, une fois l'aperçu chargé.
  Future<void> _syncOnce(HealthConnection health) async {
    if (_synced || !health.connected) return;
    _synced = true;
    try {
      final suggestions = await ref
          .read(activityActionsProvider)
          .sync(since: health.lastSyncAt);
      await _offerMerge(suggestions);
    } on ApiFailure {
      // Synchronisation silencieuse : l'aperçu reste affiché.
    }
  }

  Future<void> _offerMerge(List<MergeSuggestion> suggestions) async {
    if (suggestions.isEmpty || !mounted) return;
    final overview = ref.read(activityOverviewProvider).value;
    if (overview == null) return;
    await showMergeSheet(
      context,
      suggestion: suggestions.first,
      activities: overview.activities,
      onKeepImported: () =>
          ref.read(activityActionsProvider).merge(suggestions.first),
    );
  }

  Future<void> _connect() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _connecting = true);
    try {
      final (outcome, suggestions) = await ref
          .read(activityActionsProvider)
          .connect();
      switch (outcome) {
        case HealthConnectOutcome.connected:
          _synced = true;
          await _offerMerge(suggestions);
        case HealthConnectOutcome.denied:
          messenger.showSnackBar(
            SnackBar(content: Text(l.appActivityConnectDenied)),
          );
        case HealthConnectOutcome.needsInstall:
          messenger.showSnackBar(
            SnackBar(
              content: Text(l.appActivityConnectInstall),
              action: SnackBarAction(
                label: l.appActivityInstall,
                onPressed: () =>
                    unawaited(ref.read(healthReaderProvider).install()),
              ),
            ),
          );
        case HealthConnectOutcome.unsupported:
          messenger.showSnackBar(
            SnackBar(content: Text(l.appActivityConnectUnsupported)),
          );
      }
    } on ApiFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage(l, e))));
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final overview = ref.watch(activityOverviewProvider);
    ref.listen(activityOverviewProvider, (_, next) {
      final health = next.value?.health;
      if (health != null) unawaited(_syncOnce(health));
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OmeoTopBar(
              title: l.appActivityTitle,
              backLabel: l.commonActionBack,
              onBack: widget.navigation.onBack,
              trailing: OmeoIconButton(
                icon: OmeoIcons.plus,
                semanticLabel: l.appActivityAdd,
                onPressed: widget.navigation.onAddActivity,
              ),
            ),
            Expanded(
              child: switch (overview) {
                AsyncValue(:final value?) => RefreshIndicator(
                  onRefresh: () async {
                    _synced = false;
                    // La synchronisation recharge l'aperçu ; sans santé
                    // connectée, on le relit simplement.
                    if (value.health.connected) {
                      await _syncOnce(value.health);
                    } else {
                      ref.invalidate(activityOverviewProvider);
                    }
                  },
                  child: _Content(
                    overview: value,
                    navigation: widget.navigation,
                    connecting: _connecting,
                    onConnect: () => unawaited(_connect()),
                  ),
                ),
                AsyncValue(:final error?) => EmptyState(
                  icon: OmeoIcons.alert,
                  title: l.appActivityErrorTitle,
                  message: failureMessage(l, error),
                  actionLabel: l.commonActionRetry,
                  onAction: () => ref.invalidate(activityOverviewProvider),
                ),
                _ => const _Skeleton(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.overview,
    required this.navigation,
    required this.connecting,
    required this.onConnect,
  });

  final ActivityOverview overview;
  final SportNavigation navigation;
  final bool connecting;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final workouts = overview.recommendedWorkouts ?? const <WorkoutSummary>[];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: [
        _StepsCard(overview: overview),
        if (!overview.health.connected) ...[
          const SizedBox(height: OmeoTokens.space3),
          OmeoCard(
            variant: OmeoCardVariant.soft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.appActivityConnectTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: OmeoTokens.space1),
                Text(
                  l.appActivityConnectBody,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: OmeoTokens.space3),
                OmeoButton(
                  label: l.appActivityConnect,
                  icon: OmeoIcons.sync,
                  size: OmeoButtonSize.medium,
                  loading: connecting,
                  onPressed: connecting ? null : onConnect,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: OmeoTokens.space3),
        _BalanceCard(overview: overview),
        const SizedBox(height: OmeoTokens.space6),
        SectionTitle(
          l.appActivityTodayActivities,
          actionLabel: l.appActivityWeek,
          onAction: navigation.onWeek,
        ),
        const SizedBox(height: OmeoTokens.space3),
        if (overview.activities.isEmpty)
          Text(
            l.appActivityEmptyActivities,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.omeo.text2),
          )
        else
          OmeoList(
            children: [
              for (final a in overview.activities) ActivityTile(activity: a),
            ],
          ),
        if (workouts.isNotEmpty) ...[
          const SizedBox(height: OmeoTokens.space6),
          SectionTitle(
            l.appActivityForYou,
            actionLabel: navigation.onAllWorkouts == null
                ? null
                : l.appActivitySeeAll,
            onAction: navigation.onAllWorkouts,
          ),
          const SizedBox(height: OmeoTokens.space3),
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: workouts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) => WorkoutCard(
                workout: workouts[i],
                onTap: navigation.onWorkout == null
                    ? null
                    : () => navigation.onWorkout!(workouts[i]),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard({required this.overview});

  final ActivityOverview overview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final steps = overview.steps;
    final health = overview.health;
    final sync = health.lastSyncAt?.toLocal();

    Widget stat(String label, String value, String unit) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.labelSmall?.copyWith(
            color: t.text3,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: value, style: text.titleLarge),
              TextSpan(
                text: ' $unit',
                style: text.bodySmall?.copyWith(color: t.text3),
              ),
            ],
          ),
        ),
      ],
    );

    return OmeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RepaintBoundary(
                child: OmeoRing(
                  progress: steps.percent / 100,
                  size: 130,
                  color: t.info,
                  trackColor: t.infoSoft,
                  semanticLabel: l.appActivityStepsRing(
                    steps.value,
                    steps.target,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.number(steps.value),
                        style: text.headlineMedium,
                      ),
                      Text(
                        l.appActivityStepsOf(steps.target),
                        style: text.labelSmall?.copyWith(
                          color: t.text3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    stat(
                      l.appActivityBurned,
                      context.number(overview.balanceDay.burnedKcal),
                      l.appActivityKcalUnit,
                    ),
                    const SizedBox(height: OmeoTokens.space3),
                    if (overview.distanceM != null)
                      stat(
                        l.appActivityDistance,
                        formatKm(context, overview.distanceM!),
                        'km',
                      ),
                    const SizedBox(height: OmeoTokens.space3),
                    if (overview.activeMinutes != null)
                      stat(
                        l.appActivityActive,
                        context.number(overview.activeMinutes!),
                        l.appActivityMinUnit,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (health.connected && sync != null) ...[
            const SizedBox(height: OmeoTokens.space3),
            Row(
              children: [
                OmeoIcon(OmeoIcons.sync, size: 16, color: t.text3),
                const SizedBox(width: 6),
                Text(
                  l.appActivitySynced(
                    health.source_?.value ?? 'other',
                    MaterialLocalizations.of(
                      context,
                    ).formatTimeOfDay(TimeOfDay.fromDateTime(sync)),
                  ),
                  style: text.labelSmall?.copyWith(color: t.text3),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.overview});

  final ActivityOverview overview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final b = overview.balanceDay;
    Widget cell(String label, String value, {Color? color}) => Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: text.labelSmall?.copyWith(
              color: t.onContrast.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: text.titleLarge?.copyWith(color: color ?? t.onContrast),
          ),
        ],
      ),
    );
    return OmeoCard(
      variant: OmeoCardVariant.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.appActivityBalanceTitle,
            style: text.titleMedium?.copyWith(color: t.onContrast),
          ),
          const SizedBox(height: OmeoTokens.space4),
          Row(
            children: [
              cell(l.appActivityEaten, context.number(b.consumedKcal)),
              cell(l.appActivitySpent, context.number(b.burnedKcal)),
              cell(
                l.appActivityGap,
                context.signedNumber(b.differenceKcal),
                color: t.primarySoft,
              ),
            ],
          ),
          if (b.label != null) ...[
            const SizedBox(height: OmeoTokens.space3),
            Text(
              b.label!,
              style: text.labelSmall?.copyWith(
                color: t.onContrast.withValues(alpha: 0.65),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ligne d'une activité : type, heure, durée, calories et source.
class ActivityTile extends StatelessWidget {
  const ActivityTile({required this.activity, super.key});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final a = activity;
    final started = a.startedAt?.toLocal();
    final time = started == null
        ? ''
        : MaterialLocalizations.of(
            context,
          ).formatTimeOfDay(TimeOfDay.fromDateTime(started));
    final minutes = a.durationS ~/ 60;
    return OmeoListTile(
      icon: activityIcon(a.type),
      title: a.label ?? l.appActivityType(a.type),
      subtitle: a.avgHr == null
          ? l.appActivityActivityLine(time, minutes)
          : l.appActivityActivityLineHr(time, minutes, a.avgHr!),
      showChevron: false,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            l.commonUnitKcal(a.kcal),
            style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            l.appActivitySource(
              a.source_ == ActivitySource_Enum.manual
                  ? 'manual'
                  : a.source_.value,
            ),
            style: text.labelSmall?.copyWith(color: t.text3),
          ),
        ],
      ),
    );
  }
}

/// Carte d'une séance : visuel, nom, durée et niveau ; cadenas pour Plus.
class WorkoutCard extends StatelessWidget {
  const WorkoutCard({
    required this.workout,
    required this.onTap,
    super.key,
    this.width = 220,
  });

  final WorkoutSummary workout;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final w = workout;
    return SizedBox(
      width: width,
      child: Material(
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
              Stack(
                children: [
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: w.cover == null
                        ? ColoredBox(color: t.infoSoft)
                        : Image.network(
                            w.cover!.url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                ColoredBox(color: t.infoSoft),
                          ),
                  ),
                  if (w.locked)
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: OmeoTag.plus(l.appHomePlusTag),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall,
                    ),
                    Text(
                      l.appActivityWorkoutMeta(
                        w.durationS ~/ 60,
                        w.level.value,
                      ),
                      style: text.labelSmall?.copyWith(color: t.text3),
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

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
    child: Column(
      children: [
        Skeleton(height: 190, radius: OmeoTokens.rLg),
        SizedBox(height: 12),
        Skeleton(height: 130, radius: OmeoTokens.rLg),
        SizedBox(height: 24),
        Skeleton(height: 72, radius: OmeoTokens.rLg),
      ],
    ),
  );
}
