import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/features/meals/application/meal_writer.dart';
import 'package:omeo/features/meals/data/meals_repository.dart';
import 'package:omeo_api/omeo_api.dart';
import 'package:uuid/uuid.dart';

/// Pas d'ajustement d'une quantité avec les boutons ±, en grammes.
const gramsStep = 10;

/// Quantité minimale d'un ingrédient, en grammes.
const minGrams = 5;

/// Sous ce seuil de confiance renvoyé par l'API, un ingrédient d'une analyse
/// à faible confiance est marqué « À vérifier ». Réglage d'affichage, à
/// confirmer avec le produit.
const reviewConfidenceThreshold = 0.5;

/// Ingrédient en cours de vérification.
@immutable
final class ReviewItem {
  const ReviewItem({
    required this.foodId,
    required this.label,
    required this.grams,
    required this.included,
    required this.originalGrams,
    this.kcal,
    this.confidence,
    this.added = false,
  });

  factory ReviewItem.fromAnalysis(AnalysisItem item) => ReviewItem(
    foodId: item.foodId,
    label: item.label,
    grams: item.grams,
    originalGrams: item.grams,
    included: true,
    kcal: item.nutrients?.kcal,
    confidence: item.confidence,
  );

  final String foodId;
  final String label;
  final num grams;
  final num originalGrams;
  final bool included;

  /// Apport renvoyé par l'API pour la quantité d'origine ; inconnu dès que
  /// la quantité change (l'API le recalculera à l'enregistrement).
  final int? kcal;
  final num? confidence;

  /// Ajouté par l'utilisateur (absent de l'analyse).
  final bool added;

  bool get changed => added || !included || grams != originalGrams;

  ReviewItem copyWith({num? grams, bool? included}) => ReviewItem(
    foodId: foodId,
    label: label,
    grams: grams ?? this.grams,
    originalGrams: originalGrams,
    included: included ?? this.included,
    kcal: kcal,
    confidence: confidence,
    added: added,
  );
}

/// Brouillon du repas à vérifier (MEA-04, MEA-05).
@immutable
final class ReviewState {
  const ReviewState({
    required this.analysis,
    required this.items,
    required this.mealType,
    this.saving = false,
  });

  final Analysis analysis;
  final List<ReviewItem> items;
  final MealType? mealType;
  final bool saving;

  /// Nombre de corrections, jointes à un avis négatif.
  int get corrections => items.where((i) => i.changed).length;

  /// Après une correction, les totaux de l'analyse ne sont plus à jour :
  /// l'API les recalcule à l'enregistrement (D1).
  bool get totalsPending => corrections > 0;

  ReviewState copyWith({
    Analysis? analysis,
    List<ReviewItem>? items,
    MealType? mealType,
    bool? saving,
  }) => ReviewState(
    analysis: analysis ?? this.analysis,
    items: items ?? this.items,
    mealType: mealType ?? this.mealType,
    saving: saving ?? this.saving,
  );
}

/// Vérification d'une analyse : décocher, ajuster les quantités, ajouter un
/// ingrédient, corriger le plat, choisir le type de repas, enregistrer.
class ReviewController extends Notifier<ReviewState> {
  ReviewController(this._initial);

  final Analysis _initial;
  static const _uuid = Uuid();

  @override
  ReviewState build() => ReviewState(
    analysis: _initial,
    items: [
      for (final i in _initial.items ?? const <AnalysisItem>[])
        ReviewItem.fromAnalysis(i),
    ],
    mealType: _initial.suggestedMealType,
  );

  void toggle(int index) => _update(
    index,
    (i) => i.copyWith(included: !i.included),
  );

  void setGrams(int index, num grams) => _update(
    index,
    (i) => i.copyWith(grams: grams < minGrams ? minGrams : grams),
  );

  void step(int index, {required bool up}) => _update(
    index,
    (i) => i.copyWith(
      grams: up
          ? i.grams + gramsStep
          : (i.grams - gramsStep < minGrams ? minGrams : i.grams - gramsStep),
    ),
  );

  void addFood(FoodSummary food) => state = state.copyWith(
    items: [
      ...state.items,
      ReviewItem(
        foodId: food.id,
        label: food.name,
        grams: food.defaultPortionG ?? 100,
        originalGrams: food.defaultPortionG ?? 100,
        included: true,
        added: true,
      ),
    ],
  );

  void selectMealType(MealType type) => state = state.copyWith(mealType: type);

  void _update(int index, ReviewItem Function(ReviewItem) change) {
    final items = [...state.items];
    items[index] = change(items[index]);
    state = state.copyWith(items: items);
  }

  /// « Pas satisfait ? » : remplace le plat sans nouvelle analyse ni quota.
  /// Les corrections faites sont perdues : la composition est rechargée.
  Future<void> selectDish(String dishId) async {
    try {
      final analysis = await ref
          .read(mealsRepositoryProvider)
          .selectAnalysisDish(
            analysisId: state.analysis.id,
            dishId: dishId,
            idempotencyKey: _uuid.v4(),
          );
      state = ReviewState(
        analysis: analysis,
        items: [
          for (final i in analysis.items ?? const <AnalysisItem>[])
            ReviewItem.fromAnalysis(i),
        ],
        mealType: state.mealType,
      );
    } on ApiFailure catch (e) {
      ref.read(globalErrorBusProvider).report(e);
      rethrow;
    }
  }

  /// Enregistre le repas : les quantités corrigées sont envoyées, l'API
  /// recalcule les apports.
  Future<MealSaveOutcome> save() async {
    final type = state.mealType;
    if (type == null) throw StateError('Type de repas manquant.');
    state = state.copyWith(saving: true);
    try {
      final a = state.analysis;
      return await ref
          .read(mealWriterProvider)
          .save(
            MealInput(
              source_: a.kind == AnalysisKindEnum.text
                  ? MealInputSource_Enum.text
                  : MealInputSource_Enum.photo,
              mealType: type,
              analysisId: a.id,
              items: state.totalsPending
                  ? [
                      for (final i in state.items)
                        if (i.included)
                          MealItemInput(foodId: i.foodId, grams: i.grams),
                    ]
                  : null,
            ),
          );
    } on ApiFailure catch (e) {
      ref.read(globalErrorBusProvider).report(e);
      rethrow;
    } finally {
      state = state.copyWith(saving: false);
    }
  }
}

/// Vérification de l'analyse affichée (une par écran).
// Le type d'une famille de providers n'est pas exporté par Riverpod 3.
// ignore: specify_nonobvious_property_types
final reviewControllerProvider = NotifierProvider.autoDispose
    .family<ReviewController, ReviewState, Analysis>(ReviewController.new);

/// Recherche d'aliments à ajouter (MEA-06), noms locaux compris.
// ignore: specify_nonobvious_property_types
final foodSearchProvider = FutureProvider.autoDispose
    .family<List<FoodSummary>, String>(
      (ref, query) => query.trim().length < 2
          ? Future.value(const <FoodSummary>[])
          : ref.watch(mealsRepositoryProvider).searchFoods(query.trim()),
    );
