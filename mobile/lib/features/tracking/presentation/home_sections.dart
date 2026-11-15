import 'package:flutter/material.dart';
import 'package:omeo/core/l10n/formatters.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo_api/omeo_api.dart';

/// Fraction 0–1 pour dessiner une jauge, à partir du pourcentage de l'API.
double _fraction(int percent) => percent / 100;

/// Carte « Nutrition du jour » (anneau des kcal et macros).
class NutritionCard extends StatelessWidget {
  const NutritionCard({required this.day, required this.isToday, super.key});

  final DaySummary day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final kcal = day.kcal;
    final over = kcal.status == GaugeStatusEnum.over;
    final heroValue = over ? (kcal.overBy ?? 0) : (kcal.remaining ?? 0);
    final heroColor = over ? t.accentText : t.text;

    Widget macro(String label, Gauge g, Color color) => MacroRow(
      label: label,
      valueText: l.appHomeMacroValue(g.value, g.target),
      progress: _fraction(g.percent),
      color: g.status == GaugeStatusEnum.over ? t.accent : color,
    );

    Widget stat(OmeoIcons icon, OmeoTone tone, String label, num value) => Row(
      children: [
        BadgeIcon(icon, tone: tone, size: BadgeSize.small),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: text.labelSmall),
              Text(
                l.commonUnitKcal(value),
                style: text.titleSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return OmeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l.appHomeNutritionTitle, style: text.titleLarge),
              ),
              if (over && kcal.overBy != null)
                OmeoTag(l.appHomeOverTag(kcal.overBy!), tone: OmeoTone.accent)
              else
                OmeoTag(
                  isToday ? l.appHomeToday : context.shortDate(day.date),
                ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              // Anneau réduit sur les petits écrans (320 dp).
              final ringSize = constraints.maxWidth < 300 ? 104.0 : 128.0;
              return Row(
                children: [
                  OmeoRing(
                    size: ringSize,
                    progress: _fraction(kcal.percent),
                    color: over ? t.accent : t.primary,
                    semanticLabel: over
                        ? l.appHomeRingOver(heroValue)
                        : l.appHomeRingRemaining(heroValue),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            child: Text(
                              over
                                  ? context.signedNumber(heroValue)
                                  : context.number(heroValue),
                              style: text.displaySmall?.copyWith(
                                fontSize: 32,
                                color: heroColor,
                              ),
                            ),
                          ),
                          Text(
                            over ? l.appHomeKcalOver : l.appHomeKcalRemaining,
                            textAlign: TextAlign.center,
                            style: text.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        macro(
                          l.appHomeMacroProtein,
                          day.protein,
                          t.dataProtein,
                        ),
                        const SizedBox(height: 14),
                        macro(l.appHomeMacroCarbs, day.carbs, t.dataCarbs),
                        const SizedBox(height: 14),
                        macro(l.appHomeMacroFat, day.fat, t.dataFat),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          if (over) ...[
            const SizedBox(height: OmeoTokens.space4),
            OmeoBanner(
              icon: OmeoIcons.smile,
              child: Text(l.appHomeOverMessage),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(),
          ),
          Row(
            children: [
              Expanded(
                child: stat(
                  OmeoIcons.flame,
                  OmeoTone.primary,
                  l.appHomeConsumed,
                  kcal.value,
                ),
              ),
              const SizedBox(width: OmeoTokens.space3),
              Expanded(
                child: stat(
                  OmeoIcons.target,
                  OmeoTone.accent,
                  l.appHomeTarget,
                  kcal.target,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ajout rapide : photo en premier, puis vocal et catalogue.
class QuickAddSection extends StatelessWidget {
  const QuickAddSection({
    required this.actions,
    this.onAction,
    super.key,
  });

  final List<HomeQuickActionsInner> actions;
  final ValueChanged<HomeQuickActionsInner>? onAction;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    HomeQuickActionsInner? find(HomeQuickActionsInnerKindEnum kind) {
      for (final a in actions) {
        if (a.kind == kind) return a;
      }
      return null;
    }

    final photo = find(HomeQuickActionsInnerKindEnum.photo);
    final voice = find(HomeQuickActionsInnerKindEnum.voice);
    final catalog = find(HomeQuickActionsInnerKindEnum.catalog);

    Widget small(HomeQuickActionsInner action, OmeoIcons icon, String label) {
      final locked =
          action.lockedReason ==
          HomeQuickActionsInnerLockedReasonEnum.planRequired;
      return OmeoCard.tight(
        onTap: onAction == null ? null : () => onAction!(action),
        child: Row(
          children: [
            BadgeIcon(icon, size: BadgeSize.small),
            const SizedBox(width: 8),
            // Le libellé tient sur une ligne, réduit si l'étiquette Plus
            // manque de place (petits écrans, grand texte).
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  label,
                  maxLines: 1,
                  style: text.titleSmall?.copyWith(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (locked) OmeoTag.plus(l.appHomePlusTag),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          l.appHomeAddMealTitle,
          trailingText: photo?.remaining == null
              ? null
              : l.appMealAnalysesLeft(photo!.remaining!),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (photo != null)
                  Expanded(
                    flex: 13,
                    child: OmeoCard(
                      variant: OmeoCardVariant.black,
                      padding: const EdgeInsets.all(16),
                      onTap: onAction == null ? null : () => onAction!(photo),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const BadgeIcon(
                              OmeoIcons.camera,
                              tone: OmeoTone.glass,
                            ),
                            const SizedBox(height: OmeoTokens.space4),
                            Text(
                              l.appHomePhotoTitle,
                              style: text.titleMedium?.copyWith(
                                color: context.omeo.onContrast,
                              ),
                            ),
                            Text(
                              l.appHomePhotoSubtitle,
                              style: text.bodySmall?.copyWith(
                                color: context.omeo.onContrast.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: OmeoTokens.space3),
                Expanded(
                  flex: 10,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (voice != null)
                        small(voice, OmeoIcons.mic, l.appHomeVoice),
                      const SizedBox(height: 10),
                      if (catalog != null)
                        small(catalog, OmeoIcons.search, l.appHomeCatalog),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Balance du jour : mangé, dépensé, écart (valeurs de l'API).
class BalanceSection extends StatelessWidget {
  const BalanceSection({required this.balance, this.onDetails, super.key});

  final Balance balance;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    Widget cell(String label, String value, {Color? color}) => Column(
      children: [
        Text(label.toUpperCase(), style: text.labelSmall),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            value,
            style: text.headlineSmall?.copyWith(fontSize: 19, color: color),
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          l.appHomeBalanceTitle,
          actionLabel: onDetails == null ? null : l.appHomeDetails,
          onAction: onDetails,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: OmeoCard(
            child: Row(
              children: [
                Expanded(
                  child: cell(
                    l.appHomeEaten,
                    context.number(balance.consumedKcal),
                  ),
                ),
                Expanded(
                  child: cell(
                    l.appHomeBurned,
                    context.number(balance.burnedKcal),
                  ),
                ),
                Expanded(
                  child: cell(
                    l.appHomeDifference,
                    context.signedNumber(balance.differenceKcal),
                    color: balance.status == BalanceStatusEnum.surplus
                        ? t.accentText
                        : t.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Programme et challenges en cours.
class InProgressSection extends StatelessWidget {
  const InProgressSection({
    required this.program,
    required this.challenges,
    this.onProgram,
    this.onChallenge,
    this.onSeeAll,
    super.key,
  });

  final ProgramToday? program;
  final List<ChallengeToday> challenges;
  final VoidCallback? onProgram;
  final ValueChanged<ChallengeToday>? onChallenge;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final p = program;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          l.appHomeInProgress,
          actionLabel: onSeeAll == null ? null : l.appHomeSeeAll,
          onAction: onSeeAll,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              if (p != null)
                OmeoCard(
                  variant: OmeoCardVariant.green,
                  onTap: onProgram,
                  child: Row(
                    children: [
                      const BadgeIcon(
                        OmeoIcons.flag,
                        tone: OmeoTone.glass,
                        size: BadgeSize.large,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l
                                  .appHomeProgramDay(p.dayIndex, p.totalDays)
                                  .toUpperCase(),
                              style: text.labelSmall?.copyWith(
                                color: t.onPrimary.withValues(alpha: 0.7),
                              ),
                            ),
                            Text(
                              p.programName,
                              style: text.titleMedium?.copyWith(
                                color: t.onPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            OmeoBar.onColor(progress: _fraction(p.percent)),
                            if (p.tasksDone != null && p.tasksTotal != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  l.appHomeProgramTasks(
                                    p.tasksDone!,
                                    p.tasksTotal!,
                                  ),
                                  style: text.bodySmall?.copyWith(
                                    color: t.onPrimary.withValues(alpha: 0.75),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      OmeoIcon(
                        OmeoIcons.chevR,
                        color: t.onPrimary,
                        mirrorInRtl: true,
                      ),
                    ],
                  ),
                ),
              for (final c in challenges) ...[
                const SizedBox(height: 10),
                OmeoCard(
                  onTap: onChallenge == null ? null : () => onChallenge!(c),
                  child: Row(
                    children: [
                      const BadgeIcon(
                        OmeoIcons.drop,
                        tone: OmeoTone.accent,
                        size: BadgeSize.large,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l
                                  .appHomeChallengeDay(
                                    c.dayIndex,
                                    c.durationDays,
                                  )
                                  .toUpperCase(),
                              style: text.labelSmall,
                            ),
                            Text(c.name, style: text.titleMedium),
                            if (c.todayLabel != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  c.todayLabel!,
                                  style: text.bodyMedium?.copyWith(
                                    fontSize: 13,
                                    color: t.text2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      OmeoIcon(
                        OmeoIcons.chevR,
                        color: t.text3,
                        mirrorInRtl: true,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Constat de la semaine (Plus).
class InsightCard extends StatelessWidget {
  const InsightCard({required this.insight, super.key});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return OmeoCard(
      variant: OmeoCardVariant.accent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BadgeIcon(
            OmeoIcons.lightbulb,
            tone: OmeoTone.accent,
            size: BadgeSize.small,
            background: context.omeo.surface,
          ),
          const SizedBox(width: OmeoTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.appHomeInsightTitle,
                        style: text.titleSmall,
                      ),
                    ),
                    OmeoTag.plus(l.appHomePlusTag),
                  ],
                ),
                const SizedBox(height: 4),
                Text(insight.message, style: text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Niveau, série et progression vers le niveau suivant.
class RewardsCard extends StatelessWidget {
  const RewardsCard({required this.rewards, this.onTap, super.key});

  final RewardsSummary rewards;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final progress = rewards.progressToNextPercent;
    return OmeoCard(
      onTap: onTap,
      child: Row(
        children: [
          const BadgeIcon(
            OmeoIcons.award,
            tone: OmeoTone.contrast,
            size: BadgeSize.large,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.appHomeLevel(rewards.level.rank, rewards.level.name),
                        style: text.titleMedium?.copyWith(fontSize: 15),
                      ),
                    ),
                    OmeoTag(
                      l.appHomeStreak(rewards.streak),
                      tone: OmeoTone.accent,
                      icon: OmeoIcons.flame,
                    ),
                  ],
                ),
                if (progress != null) ...[
                  const SizedBox(height: 8),
                  OmeoBar(
                    progress: _fraction(progress),
                    color: t.accent,
                    thickness: BarThickness.thin,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  l.appHomePoints(rewards.totalPoints),
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Raccourcis « Explorer » (2 × 2).
class ShortcutsGrid extends StatelessWidget {
  const ShortcutsGrid({required this.shortcuts, this.onTap, super.key});

  final List<HomeShortcutsEnum> shortcuts;
  final ValueChanged<HomeShortcutsEnum>? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    const ink = OmeoTokens.cream50;
    ({OmeoIcons icon, String title, String sub, Color color}) spec(
      HomeShortcutsEnum s,
    ) => switch (s) {
      HomeShortcutsEnum.nutrition => (
        icon: OmeoIcons.utensils,
        title: l.appHomeShortcutNutrition,
        sub: l.appHomeShortcutNutritionSub,
        color: OmeoTokens.brown700,
      ),
      HomeShortcutsEnum.sport => (
        icon: OmeoIcons.dumbbell,
        title: l.appHomeShortcutSport,
        sub: l.appHomeShortcutSportSub,
        color: OmeoTokens.sage700,
      ),
      HomeShortcutsEnum.recipes => (
        icon: OmeoIcons.book,
        title: l.appHomeShortcutRecipes,
        sub: l.appHomeShortcutRecipesSub,
        color: OmeoTokens.ink950,
      ),
      HomeShortcutsEnum.plants => (
        icon: OmeoIcons.leaf,
        title: l.appHomeShortcutPlants,
        sub: l.appHomeShortcutPlantsSub,
        color: OmeoTokens.sage800,
      ),
    };

    Widget tile(HomeShortcutsEnum s) {
      final x = spec(s);
      final radius = BorderRadius.circular(OmeoTokens.rLg);
      return Semantics(
        button: onTap != null,
        label: x.title,
        container: true,
        excludeSemantics: true,
        child: Material(
          color: x.color,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null ? null : () => onTap!(s),
            child: Container(
              constraints: const BoxConstraints(minHeight: 120),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BadgeIcon(
                    x.icon,
                    tone: OmeoTone.glass,
                    size: BadgeSize.small,
                  ),
                  const SizedBox(height: OmeoTokens.space6),
                  Text(
                    x.title,
                    style: text.titleMedium?.copyWith(fontSize: 15, color: ink),
                  ),
                  Text(
                    x.sub,
                    style: text.bodySmall?.copyWith(
                      color: ink.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.appHomeExplore),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              for (var i = 0; i < shortcuts.length; i += 2) ...[
                if (i > 0) const SizedBox(height: OmeoTokens.space3),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: tile(shortcuts[i])),
                      const SizedBox(width: OmeoTokens.space3),
                      Expanded(
                        child: i + 1 < shortcuts.length
                            ? tile(shortcuts[i + 1])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Carte du premier jour : guide vers la première photo (HOM-02).
class FirstPhotoCard extends StatelessWidget {
  const FirstPhotoCard({this.onTakePhoto, super.key});

  final VoidCallback? onTakePhoto;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    return OmeoCard(
      variant: OmeoCardVariant.black,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OmeoTag(
            l.appHomeFirstStep,
            tone: OmeoTone.glass,
            icon: OmeoIcons.sparkles,
          ),
          const SizedBox(height: OmeoTokens.space4),
          Text(
            l.appHomeFirstPhotoTitle,
            style: text.headlineMedium?.copyWith(
              fontSize: 24,
              color: t.onContrast,
            ),
          ),
          const SizedBox(height: OmeoTokens.space2),
          Text(
            l.appHomeFirstPhotoBody,
            style: text.bodyMedium?.copyWith(
              color: t.onContrast.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: OmeoTokens.space5),
          OmeoButton(
            label: l.appHomeTakePhoto,
            icon: OmeoIcons.camera,
            variant: OmeoButtonVariant.white,
            size: OmeoButtonSize.medium,
            expand: false,
            onPressed: onTakePhoto,
          ),
        ],
      ),
    );
  }
}
