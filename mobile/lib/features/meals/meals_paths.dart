/// Chemins du module des repas (liens profonds compris).
abstract final class MealsPaths {
  static const camera = '/meals/camera';
  static const analysis = '/meals/analysis';
  static const catalog = '/meals/catalog';
  static const saved = '/meals/saved';
  static const describe = '/meals/describe';
  static const dish = '/meals/dishes/:id';

  /// Détail d'un repas, ouvert depuis le journal.
  static const meal = '/meals/:id';

  static String mealOf(String id) => '/meals/$id';

  static String dishOf(String id) => '/meals/dishes/$id';
}
