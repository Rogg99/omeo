import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/features/meals/application/meal_writer.dart';
import 'package:omeo/features/meals/data/meals_repository.dart';
import 'package:omeo_api/omeo_api.dart';

/// Portions proposées pour un plat du catalogue, en multiples de la portion
/// standard (valeur envoyée telle quelle à l'API).
enum DishPortion {
  half(0.5, 'half'),
  one(1, 'one'),
  oneHalf(1.5, 'one_half'),
  two(2, 'two')
  ;

  const DishPortion(this.value, this.key);
  final num value;

  /// Clé du message de traduction.
  final String key;
}

/// Fiche d'un plat (GET /dishes/{id}).
// Le type d'une famille de providers n'est pas exporté par Riverpod 3.
// ignore: specify_nonobvious_property_types
final dishProvider = FutureProvider.autoDispose.family<DishDetail, String>(
  (ref, id) => ref.watch(mealsRepositoryProvider).getDish(id),
);

/// Type de repas proposé selon l'heure (modifiable par l'utilisateur).
final FutureProvider<MealType> suggestedMealTypeProvider =
    FutureProvider.autoDispose(
      (ref) => ref.watch(mealsRepositoryProvider).suggestMealType(),
    );

/// Écritures autour d'un plat du catalogue.
class DishActions {
  DishActions(this._repo, this._writer);

  final MealsRepository _repo;
  final MealWriter _writer;

  Future<void> setFavorite(String id, {required bool favorite}) =>
      _repo.setDishFavorite(id, favorite: favorite);

  /// Ajoute le plat au journal ; l'API renvoie le jour recalculé et les
  /// points gagnés, ou le repas attend le retour du réseau.
  Future<MealSaveOutcome> addToJournal({
    required String dishId,
    required DishPortion portion,
    required MealType mealType,
  }) => _writer.save(
    MealInput(
      source_: MealInputSource_Enum.dish,
      mealType: mealType,
      dishId: dishId,
      portions: portion.value,
    ),
  );
}

final Provider<DishActions> dishActionsProvider = Provider(
  (ref) => DishActions(
    ref.watch(mealsRepositoryProvider),
    ref.watch(mealWriterProvider),
  ),
);
