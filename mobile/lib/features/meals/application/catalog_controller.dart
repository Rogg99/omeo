import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/features/meals/data/meals_repository.dart';
import 'package:omeo_api/omeo_api.dart';

/// Pays proposés en filtre du catalogue (codes ISO renvoyés par l'API).
const catalogCountries = ['CM', 'SN', 'CI', 'TG'];

/// Recherche du catalogue : texte saisi et pays filtré.
@immutable
final class CatalogQuery {
  const CatalogQuery({this.text = '', this.country});

  final String text;
  final String? country;

  /// Sans recherche ni filtre, on montre récents et favoris en tête.
  bool get isIdle => text.trim().isEmpty && country == null;

  @override
  bool operator ==(Object other) =>
      other is CatalogQuery && other.text == text && other.country == country;

  @override
  int get hashCode => Object.hash(text, country);
}

class CatalogQueryNotifier extends Notifier<CatalogQuery> {
  @override
  CatalogQuery build() => const CatalogQuery();

  void search(String text) =>
      state = CatalogQuery(text: text, country: state.country);

  void filterCountry(String? country) =>
      state = CatalogQuery(text: state.text, country: country);
}

final NotifierProvider<CatalogQueryNotifier, CatalogQuery>
catalogQueryProvider = NotifierProvider.autoDispose(CatalogQueryNotifier.new);

/// Contenu du catalogue : récents et favoris au repos, sinon les résultats.
typedef CatalogContent = ({
  List<DishSummary> recent,
  List<DishSummary> favorites,
  List<DishSummary>? results,
});

final FutureProvider<CatalogContent> catalogProvider =
    FutureProvider.autoDispose((ref) async {
      final query = ref.watch(catalogQueryProvider);
      final repo = ref.watch(mealsRepositoryProvider);
      if (query.isIdle) {
        final lists = await Future.wait([
          repo.searchDishes(scope: 'recent'),
          repo.searchDishes(scope: 'favorites'),
        ]);
        return (
          recent: lists[0].results,
          favorites: lists[1].results,
          results: null,
        );
      }
      final found = await repo.searchDishes(
        query: query.text.trim().isEmpty ? null : query.text.trim(),
        country: query.country,
      );
      return (
        recent: const <DishSummary>[],
        favorites: const <DishSummary>[],
        results: found.results,
      );
    });
