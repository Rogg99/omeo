import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/formatters.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/meals/application/dish_controller.dart';
import 'package:omeo/features/meals/application/meal_writer.dart';
import 'package:omeo/features/meals/presentation/catalog_screen.dart';
import 'package:omeo/features/meals/presentation/meal_type_chips.dart';
import 'package:omeo_api/omeo_api.dart'
    show DishDetail, MealType, MealWriteResult, Nutrients;

/// Destinations de la fiche d'un plat, fournies par le routeur.
typedef DishNavigation = ({
  VoidCallback onClose,
  ValueChanged<MealWriteResult> onSaved,
  VoidCallback onQueued,
  ValueChanged<String>? openRecipe,
});

/// Plat du catalogue (MEA-14) : portion modifiable, apports par portion tels
/// que renvoyés par l'API, type de repas et lien vers la recette.
class DishScreen extends ConsumerStatefulWidget {
  const DishScreen({required this.dishId, required this.navigation, super.key});

  final String dishId;
  final DishNavigation navigation;

  @override
  ConsumerState<DishScreen> createState() => _DishScreenState();
}

class _DishScreenState extends ConsumerState<DishScreen> {
  DishPortion _portion = DishPortion.one;
  MealType? _mealType;
  bool? _favorite;
  bool _saving = false;

  Future<void> _toggleFavorite(DishDetail dish) async {
    final next = !(_favorite ?? dish.isFavorite ?? false);
    setState(() => _favorite = next);
    unawaited(HapticFeedback.selectionClick());
    try {
      await ref.read(dishActionsProvider).setFavorite(dish.id, favorite: next);
    } on ApiFailure catch (e) {
      ref.read(globalErrorBusProvider).report(e);
      if (mounted) setState(() => _favorite = !next);
    }
  }

  Future<void> _save(MealType type) async {
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(dishActionsProvider)
          .addToJournal(
            dishId: widget.dishId,
            portion: _portion,
            mealType: type,
          );
      unawaited(HapticFeedback.mediumImpact());
      switch (result) {
        case MealSaved(:final result):
          widget.navigation.onSaved(result);
        case MealQueued():
          widget.navigation.onQueued();
      }
    } on ApiFailure catch (e) {
      ref.read(globalErrorBusProvider).report(e);
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failureMessage(l, e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dish = ref.watch(dishProvider(widget.dishId));
    final suggested = ref.watch(suggestedMealTypeProvider).value;
    final mealType = _mealType ?? suggested;

    return Scaffold(
      body: switch (dish) {
        AsyncValue(:final value?) => _DishContent(
          dish: value,
          portion: _portion,
          mealType: mealType,
          favorite: _favorite ?? value.isFavorite ?? false,
          onClose: widget.navigation.onClose,
          onPortion: (p) => setState(() => _portion = p),
          onMealType: (t) => setState(() => _mealType = t),
          onFavorite: () => unawaited(_toggleFavorite(value)),
          onRecipe:
              value.recipeId == null || widget.navigation.openRecipe == null
              ? null
              : () => widget.navigation.openRecipe!(value.recipeId!),
        ),
        AsyncValue(:final error?) => SafeArea(
          child: Column(
            children: [
              OmeoTopBar(
                title: '',
                backLabel: l.commonActionClose,
                close: true,
                onBack: widget.navigation.onClose,
              ),
              Expanded(
                child: EmptyState(
                  icon: OmeoIcons.alert,
                  title: l.appMealDishErrorTitle,
                  message: failureMessage(l, error),
                  actionLabel: l.commonActionRetry,
                  onAction: () => ref.invalidate(dishProvider(widget.dishId)),
                ),
              ),
            ],
          ),
        ),
        _ => const Center(child: OmeoSpinner()),
      },
      bottomNavigationBar: dish.hasValue
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: OmeoButton(
                label: mealType == null
                    ? l.commonStateLoading
                    : l.appMealDishAddTo(mealType.value),
                loading: _saving,
                onPressed: mealType == null || _saving
                    ? null
                    : () => unawaited(_save(mealType)),
              ),
            )
          : null,
    );
  }
}

class _DishContent extends StatelessWidget {
  const _DishContent({
    required this.dish,
    required this.portion,
    required this.mealType,
    required this.favorite,
    required this.onClose,
    required this.onPortion,
    required this.onMealType,
    required this.onFavorite,
    required this.onRecipe,
  });

  final DishDetail dish;
  final DishPortion portion;
  final MealType? mealType;
  final bool favorite;
  final VoidCallback onClose;
  final ValueChanged<DishPortion> onPortion;
  final ValueChanged<MealType> onMealType;
  final VoidCallback onFavorite;
  final VoidCallback? onRecipe;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final aliases = dish.aliases ?? const <String>[];
    final country = dish.country;
    final subtitle = [
      if (country != null) l.appMealCatalogCountry(country),
      if (aliases.isNotEmpty) l.appMealDishAka(aliases.join(', ')),
    ].join(' · ');
    final grams = dish.standardPortionG;
    final nutrients = dish.nutrientsPerPortion;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Semantics(
                image: true,
                label: l.appMealDishPhotoLabel(dish.name),
                child: SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: dish.image == null
                      ? ColoredBox(color: t.primarySoft)
                      : Image.network(
                          dish.image!.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              ColoredBox(color: t.primarySoft),
                        ),
                ),
              ),
              PositionedDirectional(
                top: MediaQuery.paddingOf(context).top + 12,
                start: 16,
                child: OmeoIconButton(
                  icon: OmeoIcons.x,
                  semanticLabel: l.commonActionClose,
                  onPressed: onClose,
                ),
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverList.list(
            children: [
              Transform.translate(
                offset: const Offset(0, -28),
                child: OmeoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    dish.name,
                                    style: text.headlineMedium,
                                  ),
                                ),
                                if (subtitle.isNotEmpty)
                                  Text(
                                    country == null
                                        ? subtitle
                                        : '${countryFlag(country)} $subtitle',
                                    style: text.bodySmall?.copyWith(
                                      color: t.text2,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          OmeoIconButton(
                            icon: OmeoIcons.heart,
                            semanticLabel: favorite
                                ? l.appMealDishFavoriteRemove
                                : l.appMealDishFavoriteAdd,
                            ghost: !favorite,
                            onPressed: onFavorite,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Eyebrow(l.appMealDishPortion),
                      const SizedBox(height: OmeoTokens.space2),
                      OmeoSegmented<DishPortion>(
                        segments: [
                          for (final p in DishPortion.values)
                            (value: p, label: l.appMealDishPortionValue(p.key)),
                        ],
                        selected: portion,
                        onChanged: onPortion,
                      ),
                      if (grams != null) ...[
                        const SizedBox(height: OmeoTokens.space2),
                        Text(
                          l.appMealDishPortionWeight(grams),
                          style: text.labelSmall?.copyWith(color: t.text3),
                        ),
                      ],
                      if (nutrients != null) ...[
                        const SizedBox(height: OmeoTokens.space4),
                        NutrientStats(
                          nutrients: nutrients,
                          caption: l.appMealDishPerPortion,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SectionTitle(l.appMealDishMealType),
              const SizedBox(height: OmeoTokens.space3),
              MealTypeChips(selected: mealType, onChanged: onMealType),
              if (onRecipe != null) ...[
                const SizedBox(height: OmeoTokens.space4),
                OmeoButton(
                  label: l.appMealDishRecipe,
                  variant: OmeoButtonVariant.outline,
                  size: OmeoButtonSize.medium,
                  icon: OmeoIcons.book,
                  onPressed: onRecipe,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Les quatre apports d'une portion ou d'un repas, tels que renvoyés par
/// l'API (aucun calcul).
class NutrientStats extends StatelessWidget {
  const NutrientStats({required this.nutrients, super.key, this.caption});

  final Nutrients nutrients;

  /// Précision lue par les lecteurs d'écran (« pour 1 assiette »).
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final stats = [
      (context.number(nutrients.kcal), l.appMealMacroKcal),
      (l.appMealMacroGrams(nutrients.proteinG), l.appMealMacroProtein),
      (l.appMealMacroGrams(nutrients.carbsG), l.appMealMacroCarbs),
      (l.appMealMacroGrams(nutrients.fatG), l.appMealMacroFat),
    ];
    return Semantics(
      label: [
        ?caption,
        for (final (value, unit) in stats) '$value $unit',
      ].join(', '),
      excludeSemantics: true,
      child: Row(
        children: [
          for (final (i, (value, unit)) in stats.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: t.surface2,
                  borderRadius: BorderRadius.circular(OmeoTokens.rMd),
                ),
                child: Column(
                  children: [
                    Text(value, style: text.titleMedium),
                    Text(
                      unit,
                      style: text.labelSmall?.copyWith(color: t.text2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
