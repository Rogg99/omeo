import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/formatters.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/meals/application/meal_writer.dart';
import 'package:omeo/features/meals/application/review_controller.dart';
import 'package:omeo/features/meals/presentation/catalog_screen.dart';
import 'package:omeo/features/meals/presentation/meal_type_chips.dart';
import 'package:omeo_api/omeo_api.dart'
    show
        Analysis,
        AnalysisAlternative,
        AnalysisKindEnum,
        FoodSummary,
        MealWriteResult,
        Nutrients;

/// Destinations de l'écran de vérification, fournies par le routeur.
typedef ReviewNavigation = ({
  VoidCallback onClose,
  void Function(MealWriteResult result, int corrections) onSaved,
  VoidCallback onQueued,

  /// « Autre chose » : choix d'un plat dans le catalogue. `null` si
  /// l'utilisateur renonce.
  Future<String?> Function() pickDish,
});

/// Vérification d'une analyse (MEA-04, MEA-05) : décocher, ajuster les
/// quantités, ajouter un ingrédient (MEA-06), modifier une quantité
/// (MEA-07), type de repas et « Pas satisfait ? ». Les apports affichés sont
/// ceux de l'API ; après une correction, ils sont recalculés à
/// l'enregistrement.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({
    required this.analysis,
    required this.navigation,
    super.key,
  });

  final Analysis analysis;
  final ReviewNavigation navigation;

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(reviewControllerProvider(analysis).notifier);
    final corrections = ref
        .read(reviewControllerProvider(analysis))
        .corrections;
    try {
      final outcome = await controller.save();
      unawaited(HapticFeedback.mediumImpact());
      switch (outcome) {
        case MealSaved(:final result):
          navigation.onSaved(result, corrections);
        case MealQueued():
          navigation.onQueued();
      }
    } on ApiFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage(l, e))));
    }
  }

  Future<void> _selectDish(
    BuildContext context,
    WidgetRef ref,
    String dishId,
  ) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(reviewControllerProvider(analysis).notifier)
          .selectDish(dishId);
      unawaited(HapticFeedback.selectionClick());
      messenger.showSnackBar(
        SnackBar(content: Text(l.appMealReviewDishChanged)),
      );
    } on ApiFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage(l, e))));
    }
  }

  Future<void> _otherDish(BuildContext context, WidgetRef ref) async {
    final dishId = await navigation.pickDish();
    if (dishId != null && context.mounted) {
      await _selectDish(context, ref, dishId);
    }
  }

  Future<void> _addFood(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final food = await showOmeoSheet<FoodSummary>(
      context: context,
      title: l.appMealAddFoodTitle,
      closeLabel: l.commonActionClose,
      builder: (_) => const AddFoodSheet(),
    );
    if (food != null) {
      ref.read(reviewControllerProvider(analysis).notifier).addFood(food);
    }
  }

  Future<void> _editQuantity(
    BuildContext context,
    WidgetRef ref,
    int index,
  ) async {
    final item = ref.read(reviewControllerProvider(analysis)).items[index];
    final grams = await showOmeoSheet<num>(
      context: context,
      title: item.label,
      closeLabel: AppLocalizations.of(context).commonActionClose,
      builder: (_) => QuantitySheet(initialGrams: item.grams),
    );
    if (grams != null) {
      ref
          .read(reviewControllerProvider(analysis).notifier)
          .setGrams(index, grams);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final state = ref.watch(reviewControllerProvider(analysis));
    final controller = ref.read(reviewControllerProvider(analysis).notifier);
    final a = state.analysis;
    final low = a.lowConfidence ?? false;
    final totals = a.totals;
    final alternatives = a.alternatives ?? const <AnalysisAlternative>[];
    final mealType = state.mealType;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OmeoTopBar(
              title: l.appMealReviewTitle,
              eyebrow: l.appMealReviewEyebrow(
                a.kind == AnalysisKindEnum.text ? 'text' : 'photo',
              ),
              backLabel: l.commonActionClose,
              close: true,
              onBack: navigation.onClose,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Row(
                    children: [
                      if (a.photo != null) ...[
                        DishThumb(url: a.photo!.url, size: 84),
                        const SizedBox(width: 14),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                a.dish?.name ?? a.dishLabel ?? '',
                                style: text.headlineSmall,
                              ),
                            ),
                            const SizedBox(height: OmeoTokens.space1),
                            if (low)
                              OmeoTag(
                                l.appMealReviewConfidenceMedium,
                                tone: OmeoTone.warning,
                                icon: OmeoIcons.alert,
                              )
                            else
                              OmeoTag(
                                l.appMealReviewConfidenceHigh,
                                icon: OmeoIcons.sparkles,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (low) ...[
                    const SizedBox(height: OmeoTokens.space4),
                    OmeoBanner(
                      icon: OmeoIcons.alert,
                      tone: OmeoTone.warning,
                      child: Text(l.appMealReviewLowBanner),
                    ),
                  ],
                  const SizedBox(height: OmeoTokens.space4),
                  _Totals(totals: totals, pending: state.totalsPending),
                  const SizedBox(height: OmeoTokens.space6),
                  SectionTitle(
                    l.appMealReviewIngredients,
                    actionLabel: l.appMealReviewAdd,
                    onAction: () => unawaited(_addFood(context, ref)),
                  ),
                  const SizedBox(height: OmeoTokens.space3),
                  OmeoList(
                    children: [
                      for (final (i, item) in state.items.indexed)
                        _IngredientRow(
                          item: item,
                          toCheck:
                              low &&
                              (item.confidence ?? 1) <
                                  reviewConfidenceThreshold,
                          onToggle: () => controller.toggle(i),
                          onLess: () => controller.step(i, up: false),
                          onMore: () => controller.step(i, up: true),
                          onEdit: () =>
                              unawaited(_editQuantity(context, ref, i)),
                        ),
                    ],
                  ),
                  const SizedBox(height: OmeoTokens.space6),
                  SectionTitle(l.appMealReviewMealType),
                  const SizedBox(height: OmeoTokens.space3),
                  MealTypeChips(
                    selected: mealType,
                    onChanged: controller.selectMealType,
                  ),
                  const SizedBox(height: OmeoTokens.space2),
                  Text(
                    l.appMealReviewMealTypeHint,
                    style: text.labelSmall?.copyWith(color: t.text3),
                  ),
                  const SizedBox(height: OmeoTokens.space6),
                  NotSatisfiedCard(
                    alternatives: alternatives,
                    // Dépliée quand la confiance est faible (MEA-05).
                    initiallyOpen: low,
                    onAlternative: (dishId) =>
                        unawaited(_selectDish(context, ref, dishId)),
                    onOther: () => unawaited(_otherDish(context, ref)),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: OmeoButton(
                label: totals != null && !state.totalsPending
                    ? l.appMealReviewSaveKcal(totals.kcal)
                    : l.appMealReviewSave,
                icon: OmeoIcons.check,
                loading: state.saving,
                onPressed: mealType == null || state.saving
                    ? null
                    : () => unawaited(_save(context, ref)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Apports de l'analyse, ou « en cours de calcul » après une correction.
class _Totals extends StatelessWidget {
  const _Totals({required this.totals, required this.pending});

  final Nutrients? totals;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final n = totals;
    if (pending || n == null) {
      return OmeoCard(
        variant: OmeoCardVariant.black,
        child: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              OmeoIcon(OmeoIcons.refresh, color: t.onContrast),
              const SizedBox(width: OmeoTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.appMealReviewPendingTotals,
                      style: text.titleSmall?.copyWith(color: t.onContrast),
                    ),
                    Text(
                      l.appMealReviewPendingHint,
                      style: text.labelSmall?.copyWith(
                        color: t.onContrast.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    final stats = [
      (context.number(n.kcal), l.appMealMacroKcal),
      (l.appMealMacroGrams(n.proteinG), l.appMealMacroProtein),
      (l.appMealMacroGrams(n.carbsG), l.appMealMacroCarbs),
      (l.appMealMacroGrams(n.fatG), l.appMealMacroFat),
    ];
    return OmeoCard(
      variant: OmeoCardVariant.black,
      padding: const EdgeInsets.all(16),
      child: Semantics(
        label: [for (final (v, u) in stats) '$v $u'].join(', '),
        excludeSemantics: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final (value, unit) in stats)
              Column(
                children: [
                  Text(
                    value,
                    style: text.titleLarge?.copyWith(color: t.onContrast),
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
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.item,
    required this.toCheck,
    required this.onToggle,
    required this.onLess,
    required this.onMore,
    required this.onEdit,
  });

  final ReviewItem item;
  final bool toCheck;
  final VoidCallback onToggle;
  final VoidCallback onLess;
  final VoidCallback onMore;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final kcal = item.kcal;
    final subtitle = item.changed || kcal == null
        ? l.appMealReviewItemChanged
        : l.appMealReviewItemKcal(kcal);
    return Opacity(
      opacity: item.included ? 1 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Semantics(
              checked: item.included,
              label: l.appMealReviewInclude(item.label),
              excludeSemantics: true,
              child: InkResponse(
                onTap: onToggle,
                radius: 24,
                child: SizedBox.square(
                  dimension: 44,
                  child: Center(child: SelectionMark(selected: item.included)),
                ),
              ),
            ),
            const SizedBox(width: OmeoTokens.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        item.label,
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (toCheck)
                        OmeoTag(l.appMealReviewToCheck, tone: OmeoTone.warning),
                    ],
                  ),
                  Text(
                    subtitle,
                    style: text.labelSmall?.copyWith(color: t.text2),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: t.surface2,
                borderRadius: BorderRadius.circular(OmeoTokens.rPill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StepButton(
                    icon: OmeoIcons.minus,
                    label: l.appMealReviewLess(item.label),
                    onTap: item.included ? onLess : null,
                  ),
                  InkWell(
                    onTap: item.included ? onEdit : null,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 56,
                        minHeight: 44,
                      ),
                      child: Center(
                        child: Text(
                          l.appMealReviewGrams(item.grams),
                          style: text.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _StepButton(
                    icon: OmeoIcons.plus,
                    label: l.appMealReviewMore(item.label),
                    onTap: item.included ? onMore : null,
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

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final OmeoIcons icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: InkResponse(
      onTap: onTap,
      radius: 22,
      child: SizedBox.square(
        dimension: 44,
        child: Center(child: OmeoIcon(icon, size: 18)),
      ),
    ),
  );
}

/// « Pas satisfait ? » : les autres plats envisagés, avec leur probabilité
/// telle que renvoyée par l'API, puis « Autre chose ». Ton léger.
class NotSatisfiedCard extends StatefulWidget {
  const NotSatisfiedCard({
    required this.alternatives,
    required this.initiallyOpen,
    required this.onAlternative,
    required this.onOther,
    super.key,
  });

  final List<AnalysisAlternative> alternatives;
  final bool initiallyOpen;
  final ValueChanged<String> onAlternative;
  final VoidCallback onOther;

  @override
  State<NotSatisfiedCard> createState() => _NotSatisfiedCardState();
}

class _NotSatisfiedCardState extends State<NotSatisfiedCard> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final count = widget.alternatives.length;
    return OmeoCard(
      padding: const EdgeInsets.all(16),
      child: AnimatedSize(
        duration: reduceMotion ? Duration.zero : OmeoTokens.durationBase,
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              expanded: _open,
              child: InkWell(
                onTap: () => setState(() => _open = !_open),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.appMealReviewNotSatisfied,
                            style: text.titleSmall,
                          ),
                          const SizedBox(height: OmeoTokens.space1),
                          Text(
                            _open || count == 0
                                ? l.appMealReviewNotSatisfiedOpen
                                : l.appMealReviewNotSatisfiedClosed(count),
                            style: text.bodySmall?.copyWith(color: t.text2),
                          ),
                        ],
                      ),
                    ),
                    OmeoIcon(
                      _open ? OmeoIcons.chevD : OmeoIcons.chevR,
                      mirrorInRtl: !_open,
                    ),
                  ],
                ),
              ),
            ),
            if (_open) ...[
              const SizedBox(height: OmeoTokens.space3),
              OmeoList(
                children: [
                  for (final alt in widget.alternatives)
                    if (alt.dish != null)
                      OmeoListTile(
                        leading: DishThumb(url: alt.dish!.image?.url),
                        title: alt.dish!.name,
                        subtitle: alt.dish!.country == null
                            ? null
                            : l.appMealCatalogCountry(alt.dish!.country!),
                        showChevron: false,
                        trailing: Text(
                          l.appMealReviewAlternativePercent(
                            alt.probabilityPercent,
                          ),
                          style: text.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () => widget.onAlternative(alt.dish!.id),
                      ),
                  OmeoListTile(
                    icon: OmeoIcons.search,
                    title: l.appMealReviewOtherDish,
                    subtitle: l.appMealReviewOtherDishHint,
                    onTap: widget.onOther,
                  ),
                ],
              ),
              const SizedBox(height: OmeoTokens.space2),
              Text(
                l.appMealReviewThanks,
                textAlign: TextAlign.center,
                style: text.labelSmall?.copyWith(color: t.text3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ajouter un ingrédient (MEA-06) : recherche dans la base d'aliments,
/// noms locaux compris. Renvoie l'aliment choisi.
class AddFoodSheet extends ConsumerStatefulWidget {
  const AddFoodSheet({super.key});

  @override
  ConsumerState<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends ConsumerState<AddFoodSheet> {
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final results = ref.watch(foodSearchProvider(_query));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (v) {
            _debounce?.cancel();
            _debounce = Timer(
              const Duration(milliseconds: 300),
              () => setState(() => _query = v),
            );
          },
          decoration: InputDecoration(
            hintText: l.appMealAddFoodHint,
            prefixIcon: const Padding(
              padding: EdgeInsetsDirectional.only(start: 14, end: 8),
              child: OmeoIcon(OmeoIcons.search, size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44),
          ),
        ),
        const SizedBox(height: OmeoTokens.space3),
        switch (results) {
          AsyncValue(:final value?) when value.isEmpty && _query.length >= 2 =>
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l.appMealAddFoodEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(color: t.text2),
              ),
            ),
          AsyncValue(:final value?) => OmeoList(
            children: [
              for (final food in value)
                OmeoListTile(
                  title: food.name,
                  subtitle: food.matchedAlias == null
                      ? l.appMealAddFoodLine(
                          food.defaultPortionG ?? 100,
                          food.per100g.kcal,
                        )
                      : l.appMealAddFoodLineAlias(
                          food.matchedAlias!,
                          food.per100g.kcal,
                        ),
                  showChevron: false,
                  trailing: Semantics(
                    label: l.appMealAddFoodAdd(food.name),
                    child: const BadgeIcon(
                      OmeoIcons.plus,
                      size: BadgeSize.small,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(food),
                ),
            ],
          ),
          AsyncValue(:final error?) => Text(failureMessage(l, error)),
          _ => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: OmeoSpinner(size: 28)),
          ),
        },
      ],
    );
  }
}

/// Modifier une quantité (MEA-07) : saisie en grammes avec ± et portions
/// rapides. Renvoie la quantité choisie.
class QuantitySheet extends StatefulWidget {
  const QuantitySheet({required this.initialGrams, super.key});

  final num initialGrams;

  @override
  State<QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<QuantitySheet> {
  late num _grams = widget.initialGrams;

  static const _presets = [50, 100, 150, 200, 300];

  void _set(num value) =>
      setState(() => _grams = value < minGrams ? minGrams : value);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: OmeoTokens.space4),
        Semantics(
          liveRegion: true,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: context.number(_grams),
                  style: text.displayMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: ' ${l.appMealQuantityUnit}',
                  style: text.headlineSmall?.copyWith(color: t.text3),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: OmeoTokens.space6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in _presets)
              OmeoChip(
                label: l.appMealReviewGrams(g),
                selected: _grams == g,
                onTap: () => _set(g),
              ),
          ],
        ),
        const SizedBox(height: OmeoTokens.space6),
        Row(
          children: [
            Expanded(
              child: OmeoButton(
                label: l.appMealQuantityDecrease,
                icon: OmeoIcons.minus,
                variant: OmeoButtonVariant.outline,
                size: OmeoButtonSize.medium,
                onPressed: () => _set(_grams - gramsStep),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OmeoButton(
                label: l.appMealQuantityIncrease,
                icon: OmeoIcons.plus,
                variant: OmeoButtonVariant.outline,
                size: OmeoButtonSize.medium,
                onPressed: () => _set(_grams + gramsStep),
              ),
            ),
          ],
        ),
        const SizedBox(height: OmeoTokens.space3),
        OmeoButton(
          label: l.appMealQuantityConfirm,
          onPressed: () => Navigator.of(context).pop(_grams),
        ),
      ],
    );
  }
}
