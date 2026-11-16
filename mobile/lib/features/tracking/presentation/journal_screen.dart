import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
import 'package:omeo/features/tracking/presentation/water_sheet.dart';
import 'package:omeo_api/omeo_api.dart' hide Image;
import 'package:omeo_api/omeo_api.dart' as api show Image;

/// Fraction 0–1 d'une jauge, à partir du pourcentage arrondi par l'API.
double gaugeFraction(Gauge g) => g.percent / 100;

/// Actions du journal, fournies par le routeur.
typedef JournalNavigation = ({
  /// Ajoute un repas (menu « + » du module des repas).
  ValueChanged<MealType>? addMeal,

  /// Ouvre le détail d'un repas.
  ValueChanged<Meal>? openMeal,
});

/// Journal du jour (HIS-01) : objectif, macros, 4 repas, hydratation et
/// message ; journée vide (HIS-04) ; calendrier (HIS-02).
class JournalScreen extends ConsumerWidget {
  const JournalScreen({required this.navigation, super.key});

  final JournalNavigation navigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final date = ref.watch(journalDayProvider);
    final detail = ref.watch(dayDetailProvider(date));
    final select = ref.read(journalDayProvider.notifier).select;

    final body = switch (detail) {
      AsyncValue(:final value?) => _DayContent(
        detail: value,
        navigation: navigation,
      ),
      AsyncValue(:final error?) => EmptyState(
        icon: OmeoIcons.alert,
        title: l.appJournalLoadError,
        message: failureMessage(l, error),
        actionLabel: l.commonActionRetry,
        onAction: () => ref.invalidate(dayDetailProvider(date)),
      ),
      _ => const _JournalSkeleton(),
    };

    return RefreshIndicator(
      onRefresh: () => ref.refresh(dayDetailProvider(date).future),
      child: CustomScrollView(
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverToBoxAdapter(
              child: OmeoTopBar(
                title: l.appNavJournal,
                backLabel: l.commonActionBack,
                trailing: OmeoIconButton(
                  icon: OmeoIcons.calendar,
                  semanticLabel: l.appJournalCalendar,
                  onPressed: () => unawaited(
                    showJournalCalendar(
                      context,
                      selected: date,
                      onPick: select,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _DayNavigator(
              date: date,
              previous: detail.value?.previousDate,
              next: detail.value?.nextDate,
              onSelect: select,
            ),
          ),
          SliverToBoxAdapter(child: body),
          // Place pour la barre d'onglets flottante.
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

/// Navigation jour par jour : précédent, jour affiché, suivant.
class _DayNavigator extends StatelessWidget {
  const _DayNavigator({
    required this.date,
    required this.previous,
    required this.next,
    required this.onSelect,
  });

  final DateTime date;
  final DateTime? previous;
  final DateTime? next;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final today = DateUtils.dateOnly(DateTime.now());
    final name = DateUtils.isSameDay(date, today)
        ? l.appHomeToday
        : DateUtils.isSameDay(date, today.subtract(const Duration(days: 1)))
        ? l.appJournalYesterday
        : context.shortDate(date);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          OmeoIconButton(
            icon: OmeoIcons.chevL,
            small: true,
            mirrorInRtl: true,
            semanticLabel: l.appJournalPreviousDay,
            onPressed: previous == null ? null : () => onSelect(previous!),
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Column(
                children: [
                  Text(name, style: text.titleMedium),
                  Text(
                    context.longDate(date),
                    style: text.bodySmall?.copyWith(color: context.omeo.text3),
                  ),
                ],
              ),
            ),
          ),
          OmeoIconButton(
            icon: OmeoIcons.chevR,
            small: true,
            mirrorInRtl: true,
            semanticLabel: l.appJournalNextDay,
            onPressed: next == null ? null : () => onSelect(next!),
          ),
        ],
      ),
    );
  }
}

class _DayContent extends ConsumerWidget {
  const _DayContent({required this.detail, required this.navigation});

  final DayDetail detail;
  final JournalNavigation navigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final day = detail.day;
    final empty = (day.mealsCount ?? 0) == 0;
    final volume =
        ref.watch(meProvider).value?.preferences.volumeSystem ??
        UnitSystem.metric;

    final meals = Column(
      children: [
        for (final group in detail.mealsByType)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MealGroupCard(
              group: group,
              onAdd: navigation.addMeal == null
                  ? null
                  : () => navigation.addMeal!(group.mealType),
              onOpen: navigation.openMeal,
            ),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (empty) ...[
            _EmptyDay(
              onAdd: navigation.addMeal == null
                  ? null
                  : () => navigation.addMeal!(
                      detail.mealsByType.first.mealType,
                    ),
            ),
            const SizedBox(height: OmeoTokens.space6),
            meals,
          ] else ...[
            _GoalCard(day: day),
            const SizedBox(height: OmeoTokens.space3),
            _MacroGrid(day: day),
            const SizedBox(height: OmeoTokens.space6),
            Semantics(
              header: true,
              child: Text(l.appJournalMealsTitle, style: text.titleMedium),
            ),
            const SizedBox(height: OmeoTokens.space3),
            meals,
          ],
          _WaterCard(water: detail.water, volume: volume),
          const SizedBox(height: OmeoTokens.space3),
          OmeoCard(
            variant: OmeoCardVariant.soft,
            child: Row(
              children: [
                const BadgeIcon(OmeoIcons.target, tone: OmeoTone.contrast),
                const SizedBox(width: OmeoTokens.space3),
                Expanded(child: Text(detail.message, style: text.bodyMedium)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Objectif du jour : kcal consommées sur l'objectif, anneau du pourcentage.
class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.day});

  final DaySummary day;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final kcal = day.kcal;
    return OmeoCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.appJournalGoalTitle,
                  style: text.bodyMedium?.copyWith(color: t.text2),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: context.number(kcal.value)),
                        TextSpan(
                          text: ' / ${context.number(kcal.target)}',
                          style: TextStyle(fontSize: 18, color: t.text3),
                        ),
                      ],
                    ),
                    style: text.displaySmall?.copyWith(fontSize: 34),
                  ),
                ),
                Text(
                  l.appJournalKcalConsumed,
                  style: text.labelMedium?.copyWith(color: t.primaryText),
                ),
              ],
            ),
          ),
          OmeoRing(
            size: 84,
            stroke: 9,
            progress: gaugeFraction(kcal),
            color: kcal.status == GaugeStatusEnum.over ? t.accent : t.primary,
            semanticLabel: l.appJournalPercent(kcal.percent),
            child: Text(
              l.appJournalPercent(kcal.percent),
              style: text.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quatre macros en mini-anneaux : protéines, glucides, lipides, fibres.
class _MacroGrid extends StatelessWidget {
  const _MacroGrid({required this.day});

  final DaySummary day;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    Widget cell(String label, Gauge? g, Color color) => Expanded(
      child: OmeoCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          children: [
            OmeoRing(
              size: 44,
              stroke: 5,
              progress: g == null ? 0 : gaugeFraction(g),
              color: color,
              semanticLabel: g == null
                  ? label
                  : '$label ${l.commonUnitGrams(g.value)}',
            ),
            const SizedBox(height: 8),
            FittedBox(
              child: Text(
                g == null ? '—' : l.commonUnitGrams(g.value),
                style: text.titleSmall,
              ),
            ),
            Text(label, style: text.labelSmall),
          ],
        ),
      ),
    );
    return Row(
      children: [
        cell(l.appJournalProteinShort, day.protein, t.dataProtein),
        const SizedBox(width: 8),
        cell(l.appJournalCarbsShort, day.carbs, t.dataCarbs),
        const SizedBox(width: 8),
        cell(l.appJournalFatShort, day.fat, t.dataFat),
        const SizedBox(width: 8),
        cell(l.appJournalFiber, day.fiber, t.dataFiber),
      ],
    );
  }
}

/// Un repas du jour : total, « + » et plats enregistrés.
class _MealGroupCard extends StatelessWidget {
  const _MealGroupCard({required this.group, this.onAdd, this.onOpen});

  final DayDetailMealsByTypeInner group;
  final VoidCallback? onAdd;
  final ValueChanged<Meal>? onOpen;

  static OmeoIcons iconOf(MealType type) => switch (type) {
    MealType.breakfast => OmeoIcons.cup,
    MealType.lunch => OmeoIcons.utensils,
    MealType.snack => OmeoIcons.apple,
    MealType.dinner => OmeoIcons.moon,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    return OmeoCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              BadgeIcon(iconOf(group.mealType)),
              const SizedBox(width: OmeoTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.label, style: text.titleSmall),
                    Text(
                      group.meals.isEmpty
                          ? l.appJournalNoMeal
                          : l.commonUnitKcal(group.kcal),
                      style: text.bodySmall?.copyWith(color: t.text3),
                    ),
                  ],
                ),
              ),
              if (onAdd != null)
                OmeoIconButton(
                  icon: OmeoIcons.plus,
                  small: true,
                  semanticLabel: l.appJournalAddTo(group.label),
                  onPressed: onAdd,
                ),
            ],
          ),
          for (final meal in group.meals) ...[
            const SizedBox(height: 10),
            Semantics(
              button: onOpen != null,
              child: InkWell(
                borderRadius: BorderRadius.circular(OmeoTokens.rSm),
                onTap: onOpen == null ? null : () => onOpen!(meal),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      _MealThumb(photo: meal.photo),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(meal.title, style: text.labelLarge),
                            Text(
                              l.commonUnitKcal(meal.nutrients.kcal),
                              style: text.bodySmall?.copyWith(color: t.text3),
                            ),
                          ],
                        ),
                      ),
                      OmeoIcon(
                        OmeoIcons.chevR,
                        size: 18,
                        color: t.text3,
                        mirrorInRtl: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MealThumb extends StatelessWidget {
  const _MealThumb({required this.photo});

  final api.Image? photo;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final url = photo?.url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: 44,
        child: url == null
            ? ColoredBox(
                color: t.surface2,
                child: OmeoIcon(OmeoIcons.utensils, size: 18, color: t.text3),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: 132,
                errorBuilder: (_, _, _) => ColoredBox(color: t.surface2),
              ),
      ),
    );
  }
}

/// Hydratation : jauge en verres et ajouts rapides.
class _WaterCard extends ConsumerWidget {
  const _WaterCard({required this.water, required this.volume});

  final Water water;
  final UnitSystem volume;

  static const _cells = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final gauge = water.gauge;
    final filled = (gaugeFraction(gauge) * _cells).floor().clamp(0, _cells);
    void open() => unawaited(showWaterSheet(context, water: water));
    return OmeoCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const BadgeIcon(OmeoIcons.drop, tone: OmeoTone.info),
              const SizedBox(width: OmeoTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.appJournalWaterTitle, style: text.titleSmall),
                    Text(
                      l.appJournalWaterOf(
                        context.water(gauge.value, volume),
                        context.water(gauge.target, volume),
                      ),
                      style: text.bodySmall?.copyWith(color: t.text3),
                    ),
                  ],
                ),
              ),
              OmeoIconButton(
                icon: OmeoIcons.plus,
                small: true,
                semanticLabel: l.appJournalWaterAdd,
                onPressed: open,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < _cells; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: i < filled ? t.dataWater : t.infoSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final ml in water.quickAddMl)
                OmeoChip(
                  label: l.appJournalWaterQuick(context.water(ml, volume)),
                  selected: false,
                  onTap: () => unawaited(
                    addWaterWithFeedback(
                      context,
                      ref,
                      amountMl: ml,
                      date: water.date,
                    ),
                  ),
                ),
              OmeoChip(
                label: l.appJournalWaterOther,
                selected: false,
                onTap: open,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Journée vide (HIS-04) : invitation douce, sans culpabiliser.
class _EmptyDay extends StatelessWidget {
  const _EmptyDay({this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: t.surface2,
              shape: BoxShape.circle,
            ),
            child: OmeoIcon(OmeoIcons.utensils, size: 32, color: t.text2),
          ),
          const SizedBox(height: OmeoTokens.space4),
          Text(
            l.appJournalEmptyTitle,
            textAlign: TextAlign.center,
            style: text.headlineSmall,
          ),
          const SizedBox(height: OmeoTokens.space2),
          Text(
            l.appJournalEmptyBody,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: t.text2),
          ),
          if (onAdd != null) ...[
            const SizedBox(height: OmeoTokens.space5),
            OmeoButton(
              label: l.appNavAddMeal,
              icon: OmeoIcons.plus,
              size: OmeoButtonSize.medium,
              expand: false,
              onPressed: onAdd,
            ),
          ],
        ],
      ),
    );
  }
}

class _JournalSkeleton extends StatelessWidget {
  const _JournalSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: Column(
      children: [
        Skeleton(height: 110, radius: OmeoTokens.rLg),
        SizedBox(height: 12),
        Skeleton(height: 100, radius: OmeoTokens.rLg),
        SizedBox(height: 24),
        Skeleton(height: 120, radius: OmeoTokens.rLg),
        SizedBox(height: 10),
        Skeleton(height: 120, radius: OmeoTokens.rLg),
      ],
    ),
  );
}

/// Calendrier du mois (HIS-02) : saut direct à une date.
Future<void> showJournalCalendar(
  BuildContext context, {
  required DateTime selected,
  required ValueChanged<DateTime> onPick,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (sheetContext) => OmeoSheet(
    child: JournalCalendar(
      initialMonth: DateTime(selected.year, selected.month),
      selected: selected,
      onPick: (date) {
        Navigator.of(sheetContext).pop();
        onPick(date);
      },
    ),
  ),
);

/// Vue du mois : jours atteints, partiels et sans saisie.
class JournalCalendar extends ConsumerStatefulWidget {
  const JournalCalendar({
    required this.initialMonth,
    required this.selected,
    required this.onPick,
    super.key,
  });

  final DateTime initialMonth;
  final DateTime selected;
  final ValueChanged<DateTime> onPick;

  @override
  ConsumerState<JournalCalendar> createState() => _JournalCalendarState();
}

class _JournalCalendarState extends ConsumerState<JournalCalendar> {
  late DateTime _month = widget.initialMonth;

  void _shift(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = DateUtils.dateOnly(DateTime.now());
    final days = ref.watch(calendarProvider(_month)).value ?? const [];
    final statusOf = {
      for (final d in days) DateUtils.dateOnly(d.date): d.status,
    };
    final firstWeekday = DateTime(_month.year, _month.month).weekday;
    final count = DateUtils.getDaysInMonth(_month.year, _month.month);
    final monday = DateTime(2024);
    final isCurrentMonth =
        _month.year == today.year && _month.month == today.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            OmeoIconButton(
              icon: OmeoIcons.chevL,
              small: true,
              mirrorInRtl: true,
              semanticLabel: l.appJournalPreviousMonth,
              onPressed: () => _shift(-1),
            ),
            Expanded(
              child: Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  DateFormat.yMMMM(locale).format(_month),
                  textAlign: TextAlign.center,
                  style: text.titleLarge,
                ),
              ),
            ),
            OmeoIconButton(
              icon: OmeoIcons.chevR,
              small: true,
              mirrorInRtl: true,
              semanticLabel: l.appJournalNextMonth,
              onPressed: isCurrentMonth ? null : () => _shift(1),
            ),
          ],
        ),
        const SizedBox(height: OmeoTokens.space4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (var i = 0; i < 7; i++)
              Center(
                child: Text(
                  DateFormat(
                    'EEEEE',
                    locale,
                  ).format(monday.add(Duration(days: i))),
                  style: text.labelSmall,
                ),
              ),
            for (var i = 1; i < firstWeekday; i++) const SizedBox.shrink(),
            for (var d = 1; d <= count; d++)
              () {
                final date = DateTime(_month.year, _month.month, d);
                final status = statusOf[date];
                final future = date.isAfter(today);
                final reached =
                    status == GetCalendar200ResponseInnerStatusEnum.onTarget;
                final partial =
                    status != null &&
                    !reached &&
                    status != GetCalendar200ResponseInnerStatusEnum.empty;
                return Semantics(
                  button: !future,
                  selected: DateUtils.isSameDay(date, widget.selected),
                  label: context.longDate(date),
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: future ? null : () => widget.onPick(date),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: reached
                            ? t.primary
                            : partial
                            ? t.primarySoft
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        border: DateUtils.isSameDay(date, today)
                            ? Border.all(color: t.accent, width: 2)
                            : null,
                      ),
                      child: Text(
                        context.number(d),
                        style: text.labelLarge?.copyWith(
                          color: reached
                              ? t.onPrimary
                              : future
                              ? t.text3
                              : t.text,
                        ),
                      ),
                    ),
                  ),
                );
              }(),
          ],
        ),
        const SizedBox(height: OmeoTokens.space4),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 6,
          children: [
            _Legend(color: t.primary, label: l.appJournalLegendReached),
            _Legend(color: t.primarySoft, label: l.appJournalLegendPartial),
            _Legend(border: t.accent, label: l.appJournalLegendToday),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, this.color, this.border});

  final String label;
  final Color? color;
  final Color? border;

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
          border: border == null ? null : Border.all(color: border!, width: 2),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
