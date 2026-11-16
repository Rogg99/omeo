import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/formatters.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/meals/application/meal_controller.dart';
import 'package:omeo/features/meals/presentation/meal_type_chips.dart';
import 'package:omeo_api/omeo_api.dart' show Meal, MealType;

/// Détail d'un repas (MEA-15), ouvert depuis le journal : photo, apports,
/// ingrédients et actions de gestion. [onEdit] ouvre la correction des
/// ingrédients ; absente, l'action est masquée.
class MealDetailScreen extends ConsumerWidget {
  const MealDetailScreen({
    required this.mealId,
    required this.onBack,
    super.key,
    this.onEdit,
  });

  final String mealId;
  final VoidCallback onBack;
  final ValueChanged<Meal>? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final meal = ref.watch(mealProvider(mealId));
    return Scaffold(
      body: switch (meal) {
        AsyncValue(:final value?) => _MealContent(
          meal: value,
          onBack: onBack,
          onEdit: onEdit,
        ),
        AsyncValue(:final error?) => SafeArea(
          child: Column(
            children: [
              OmeoTopBar(
                title: '',
                backLabel: l.commonActionBack,
                onBack: onBack,
              ),
              Expanded(
                child: EmptyState(
                  icon: OmeoIcons.alert,
                  title: l.appMealDetailErrorTitle,
                  message: failureMessage(l, error),
                  actionLabel: l.commonActionRetry,
                  onAction: () => ref.invalidate(mealProvider(mealId)),
                ),
              ),
            ],
          ),
        ),
        _ => const Center(child: OmeoSpinner()),
      },
    );
  }
}

class _MealContent extends ConsumerWidget {
  const _MealContent({
    required this.meal,
    required this.onBack,
    required this.onEdit,
  });

  final Meal meal;
  final VoidCallback onBack;
  final ValueChanged<Meal>? onEdit;

  void _snack(BuildContext context, String message, {SnackBarAction? action}) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            action: action,
            duration: action == null ? const Duration(seconds: 4) : undoDelay,
          ),
        );

  void _report(BuildContext context, WidgetRef ref, ApiFailure e) {
    ref.read(globalErrorBusProvider).report(e);
    _snack(context, failureMessage(AppLocalizations.of(context), e));
  }

  Future<void> _move(
    BuildContext context,
    WidgetRef ref, {
    required bool duplicate,
  }) async {
    final l = AppLocalizations.of(context);
    final target = await showOmeoSheet<({MealType type, DateTime date})>(
      context: context,
      title: duplicate ? l.appMealMoveDuplicateTitle : l.appMealMoveTitle,
      closeLabel: l.commonActionClose,
      builder: (_) => MoveMealSheet(
        initialType: meal.mealType,
        initialDate: meal.date,
        duplicate: duplicate,
      ),
    );
    if (target == null || !context.mounted) return;
    final actions = ref.read(mealActionsProvider);
    try {
      if (duplicate) {
        await actions.duplicate(
          meal.id,
          mealType: target.type,
          date: target.date,
        );
      } else {
        await actions.move(meal.id, mealType: target.type, date: target.date);
        ref.invalidate(mealProvider(meal.id));
      }
      if (context.mounted) {
        _snack(
          context,
          duplicate ? l.appMealMoveDuplicated : l.appMealMoveMoved,
        );
      }
    } on ApiFailure catch (e) {
      if (context.mounted) _report(context, ref, e);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteMealDialog(meal: meal),
    );
    if (confirmed != true || !context.mounted) return;
    unawaited(HapticFeedback.mediumImpact());
    final pending = ref.read(pendingMealDeletionsProvider.notifier)
      ..schedule(meal.id);
    // Le message reste visible après le retour au journal.
    _snack(
      context,
      l.appMealDeleteDeleted,
      action: SnackBarAction(
        label: l.appMealDeleteUndo,
        onPressed: () => pending.undo(meal.id),
      ),
    );
    onBack();
  }

  Future<void> _deletePhoto(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    try {
      await ref.read(mealActionsProvider).deletePhoto(meal.id);
      ref.invalidate(mealProvider(meal.id));
      if (context.mounted) _snack(context, l.appMealDetailPhotoDeleted);
    } on ApiFailure catch (e) {
      if (context.mounted) _report(context, ref, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final eaten = meal.eatenAt?.toLocal();
    final type = l.appMealTypeName(meal.mealType.value);
    final when = eaten == null
        ? type
        : l.appMealDetailWhen(
            type,
            MaterialLocalizations.of(
              context,
            ).formatTimeOfDay(TimeOfDay.fromDateTime(eaten)),
          );
    final n = meal.nutrients;

    final actions = [
      if (onEdit != null)
        (OmeoIcons.edit, l.appMealDetailEdit, () => onEdit!(meal), false),
      (
        OmeoIcons.move,
        l.appMealDetailMove,
        () => unawaited(_move(context, ref, duplicate: false)),
        false,
      ),
      (
        OmeoIcons.duplicate,
        l.appMealDetailDuplicate,
        () => unawaited(_move(context, ref, duplicate: true)),
        false,
      ),
      (
        OmeoIcons.trash,
        l.appMealDetailDelete,
        () => unawaited(_delete(context, ref)),
        true,
      ),
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            children: [
              SizedBox(
                height: meal.photo == null
                    ? MediaQuery.paddingOf(context).top + 64
                    : 280,
                width: double.infinity,
                child: meal.photo == null
                    ? null
                    : Semantics(
                        image: true,
                        label: l.appMealDetailPhotoLabel(meal.title),
                        child: Image.network(
                          meal.photo!.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              ColoredBox(color: t.surface2),
                        ),
                      ),
              ),
              PositionedDirectional(
                top: MediaQuery.paddingOf(context).top + 12,
                start: 16,
                child: OmeoIconButton(
                  icon: OmeoIcons.chevL,
                  semanticLabel: l.commonActionBack,
                  mirrorInRtl: true,
                  onPressed: onBack,
                ),
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          sliver: SliverList.list(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OmeoTag(when, icon: mealTypeIcon(meal.mealType)),
              ),
              const SizedBox(height: OmeoTokens.space2),
              Semantics(
                header: true,
                child: Text(meal.title, style: text.headlineMedium),
              ),
              Text(
                l.appMealDetailSource(meal.source_),
                style: text.bodySmall?.copyWith(color: t.text2),
              ),
              const SizedBox(height: OmeoTokens.space4),
              OmeoCard(
                variant: OmeoCardVariant.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (final (value, unit) in [
                      (context.number(n.kcal), l.appMealMacroKcal),
                      (l.appMealMacroGrams(n.proteinG), l.appMealMacroProtein),
                      (l.appMealMacroGrams(n.carbsG), l.appMealMacroCarbs),
                      (l.appMealMacroGrams(n.fatG), l.appMealMacroFat),
                    ])
                      Column(
                        children: [
                          Text(
                            value,
                            style: text.titleMedium?.copyWith(
                              color: t.onContrast,
                            ),
                          ),
                          Text(
                            unit,
                            style: text.labelSmall?.copyWith(
                              color: t.onContrast.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: OmeoTokens.space3),
              Row(
                children: [
                  for (final (icon, label, onTap, danger) in actions)
                    Expanded(
                      child: _ActionButton(
                        icon: icon,
                        label: label,
                        danger: danger,
                        onTap: onTap,
                      ),
                    ),
                ],
              ),
              if (meal.items.isNotEmpty) ...[
                const SizedBox(height: OmeoTokens.space6),
                SectionTitle(l.appMealDetailIngredients),
                const SizedBox(height: OmeoTokens.space3),
                OmeoList(
                  children: [
                    for (final item in meal.items)
                      OmeoListTile(
                        title: item.label,
                        subtitle: item.nutrients == null
                            ? l.commonUnitGrams(item.grams)
                            : l.appMealDetailIngredient(
                                item.grams,
                                item.nutrients!.kcal,
                              ),
                        showChevron: false,
                      ),
                  ],
                ),
              ],
              if (meal.photo != null) ...[
                const SizedBox(height: OmeoTokens.space4),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => unawaited(_deletePhoto(context, ref)),
                    icon: const OmeoIcon(OmeoIcons.trash, size: 18),
                    label: Text(l.appMealDetailDeletePhoto),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.danger,
    required this.onTap,
  });

  final OmeoIcons icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(OmeoTokens.rMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              BadgeIcon(
                icon,
                tone: danger ? OmeoTone.danger : OmeoTone.neutral,
                round: true,
              ),
              const SizedBox(height: OmeoTokens.space1),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: danger ? t.danger : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Déplacer ou dupliquer un repas (MEA-16) : type de repas et jour, parmi les
/// sept derniers jours. Renvoie le choix à l'écran appelant.
class MoveMealSheet extends StatefulWidget {
  const MoveMealSheet({
    required this.initialType,
    required this.initialDate,
    super.key,
    this.duplicate = false,
    this.today,
  });

  final MealType initialType;
  final DateTime initialDate;
  final bool duplicate;

  /// Jour courant (figé dans les tests).
  final DateTime? today;

  @override
  State<MoveMealSheet> createState() => _MoveMealSheetState();
}

class _MoveMealSheetState extends State<MoveMealSheet> {
  late MealType _type = widget.initialType;
  late final List<DateTime> _days = () {
    final now = widget.today ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
  }();
  late DateTime _date = _days.firstWhere(
    (d) => DateUtils.isSameDay(d, widget.initialDate),
    orElse: () => _days.last,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final typeName = l.appMealTypeName(_type.value).toLowerCase();
    final day = DateFormat.MMMEd(locale).format(_date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Eyebrow(l.appMealMoveTo),
        const SizedBox(height: OmeoTokens.space2),
        MealTypeChips(
          selected: _type,
          onChanged: (t) => setState(() => _type = t),
        ),
        const SizedBox(height: 20),
        Eyebrow(l.appMealMoveDay),
        const SizedBox(height: OmeoTokens.space2),
        DayStrip(
          selectedIndex: _days.indexOf(_date),
          onSelect: (i) => setState(() => _date = _days[i]),
          days: [
            for (final d in _days)
              (
                shortName: DateFormat.E(locale).format(d),
                number: context.number(d.day),
                semanticLabel: context.longDate(d),
                hasEntries: false,
                isFuture: false,
              ),
          ],
        ),
        const SizedBox(height: OmeoTokens.space6),
        OmeoButton(
          label: widget.duplicate
              ? l.appMealMoveConfirmDuplicate(typeName, day)
              : l.appMealMoveConfirm(typeName, day),
          onPressed: () =>
              Navigator.of(context).pop((type: _type, date: _date)),
        ),
      ],
    );
  }
}

/// Confirmation de suppression (MEA-17) : action destructive en rouge,
/// annulable ensuite pendant quelques secondes (SYS-07).
class DeleteMealDialog extends StatelessWidget {
  const DeleteMealDialog({required this.meal, super.key});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BadgeIcon(
              OmeoIcons.trash,
              tone: OmeoTone.danger,
              size: BadgeSize.large,
              round: true,
            ),
            const SizedBox(height: OmeoTokens.space4),
            Text(
              l.appMealDeleteTitle,
              style: text.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OmeoTokens.space2),
            Text(
              l.appMealDeleteBody(
                meal.title,
                l.commonUnitKcal(meal.nutrients.kcal),
              ),
              style: text.bodySmall?.copyWith(color: t.text2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OmeoButton(
              label: l.commonActionDelete,
              variant: OmeoButtonVariant.danger,
              size: OmeoButtonSize.medium,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: OmeoTokens.space1),
            OmeoButton(
              label: l.commonActionCancel,
              variant: OmeoButtonVariant.ghost,
              size: OmeoButtonSize.medium,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
