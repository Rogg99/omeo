import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/formatters.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/tracking/application/home_controller.dart';
import 'package:omeo/features/tracking/presentation/home_sections.dart';
import 'package:omeo_api/omeo_api.dart';

/// Actions de navigation de l'accueil, fournies par le routeur. Une action
/// absente rend l'élément correspondant non interactif.
typedef HomeNavigation = ({
  VoidCallback? openHelp,
  VoidCallback? openNotifications,
  ValueChanged<HomeQuickActionsInner>? quickAction,
  ValueChanged<DateTime>? openJournal,
  ValueChanged<HomeShortcutsEnum>? openShortcut,
  VoidCallback? openProgram,
  ValueChanged<ChallengeToday>? openChallenge,
  VoidCallback? openRewards,
});

/// Accueil : une information clé en haut (calories restantes), puis les
/// actions rapides et ce qui est en cours (HOM-01 à HOM-05).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    required this.navigation,
    required this.unreadNotifications,
    super.key,
  });

  final HomeNavigation navigation;
  final int unreadNotifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final home = ref.watch(homeProvider);

    final header = OmeoAppBar(
      helpLabel: l.appNavHelp,
      notificationsLabel: l.appNavNotifications(unreadNotifications),
      unreadCount: unreadNotifications,
      onHelp: navigation.openHelp,
      onNotifications: navigation.openNotifications,
    );

    final Widget body = switch (home) {
      AsyncValue(:final value?) => _HomeContent(
        home: value,
        navigation: navigation,
        onSelectDay: (date) =>
            ref.read(selectedHomeDayProvider.notifier).day = date,
      ),
      AsyncValue(:final error?) => EmptyState(
        icon: OmeoIcons.alert,
        title: l.appHomeLoadError,
        message: failureMessage(l, error),
        actionLabel: l.commonActionRetry,
        onAction: () => ref.invalidate(homeProvider),
      ),
      _ => const _HomeSkeleton(),
    };

    return RefreshIndicator(
      onRefresh: () => ref.refresh(homeProvider.future),
      child: CustomScrollView(
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverToBoxAdapter(child: header),
          ),
          SliverToBoxAdapter(child: body),
          // Place pour la barre d'onglets flottante.
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.home,
    required this.navigation,
    required this.onSelectDay,
  });

  final Home home;
  final HomeNavigation navigation;
  final ValueChanged<DateTime?> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final selectedIndex = home.week.indexWhere(
      (d) => DateUtils.isSameDay(d.date, home.date),
    );
    final isToday = home.week.any(
      (d) => d.isToday && DateUtils.isSameDay(d.date, home.date),
    );
    final firstDay = isToday && (home.day.mealsCount ?? 0) == 0;
    final challenges = home.activeChallenges ?? const <ChallengeToday>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(context.longDate(home.date)),
              const SizedBox(height: 4),
              Semantics(
                header: true,
                child: Text(
                  home.greeting,
                  style: text.headlineMedium?.copyWith(fontSize: 24),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: OmeoTokens.space4),
        DayStrip(
          selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
          onSelect: (i) {
            final day = home.week[i];
            onSelectDay(day.isToday ? null : day.date);
          },
          days: [
            for (final d in home.week)
              (
                shortName: d.label,
                number: context.number(d.dayNumber ?? d.date.day),
                semanticLabel: context.longDate(d.date),
                hasEntries:
                    d.status != WeekDayStatusEnum.empty &&
                    d.status != WeekDayStatusEnum.future,
                isFuture: d.status == WeekDayStatusEnum.future,
              ),
          ],
        ),
        if (firstDay)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: FirstPhotoCard(
              onTakePhoto: navigation.quickAction == null
                  ? null
                  : () {
                      for (final a in home.quickActions) {
                        if (a.kind == HomeQuickActionsInnerKindEnum.photo) {
                          navigation.quickAction!(a);
                        }
                      }
                    },
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: NutritionCard(day: home.day, isToday: isToday),
        ),
        if (!isToday && navigation.openJournal != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: OmeoButton(
              label: l.appHomeSeeDayJournal,
              variant: OmeoButtonVariant.outline,
              size: OmeoButtonSize.medium,
              trailingIcon: OmeoIcons.arrowR,
              onPressed: () => navigation.openJournal!(home.date),
            ),
          ),
        if (isToday)
          QuickAddSection(
            actions: home.quickActions,
            onAction: navigation.quickAction,
          ),
        if (home.day.balance != null)
          BalanceSection(
            balance: home.day.balance!,
            onDetails: navigation.openJournal == null
                ? null
                : () => navigation.openJournal!(home.date),
          ),
        if (home.activeProgram != null || challenges.isNotEmpty)
          InProgressSection(
            program: home.activeProgram,
            challenges: challenges,
            onProgram: navigation.openProgram,
            onChallenge: navigation.openChallenge,
          ),
        if (home.insight != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: InsightCard(insight: home.insight!),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: RewardsCard(
            rewards: home.rewards,
            onTap: navigation.openRewards,
          ),
        ),
        if (home.shortcuts.isNotEmpty)
          ShortcutsGrid(
            shortcuts: home.shortcuts,
            onTap: navigation.openShortcut,
          ),
      ],
    );
  }
}

/// Squelette de l'accueil, aux proportions des maquettes.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: 120, height: 12),
          SizedBox(height: 8),
          Skeleton(width: 200, height: 28),
          SizedBox(height: 16),
          Skeleton(height: 64, radius: 20),
          SizedBox(height: 16),
          Skeleton(height: 260, radius: OmeoTokens.rLg),
          SizedBox(height: 28),
          Skeleton(width: 160, height: 20),
          SizedBox(height: 12),
          Skeleton(height: 132, radius: OmeoTokens.rLg),
        ],
      ),
    );
  }
}
