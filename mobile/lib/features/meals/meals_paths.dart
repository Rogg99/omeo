/// Chemins du module des repas (liens profonds compris).
abstract final class MealsPaths {
  static const camera = '/meals/camera';
  static const analysis = '/meals/analysis';
  static const catalog = '/meals/catalog';
  static const saved = '/meals/saved';
  static const dish = '/meals/dishes/:id';

  static String dishOf(String id) => '/meals/dishes/$id';
}
