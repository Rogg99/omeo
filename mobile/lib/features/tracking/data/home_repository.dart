import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo_api/omeo_api.dart';

/// Accueil : journée résumée, semaine, actions rapides et ce qui est en cours.
abstract interface class HomeRepository {
  /// [date] nulle : aujourd'hui (fuseau envoyé dans X-Timezone).
  Future<Home> getHome({DateTime? date});
}

/// Implémentation sur l'API réelle (GET /me/home).
final class HomeApiRepository implements HomeRepository {
  const HomeApiRepository(this._api);

  final HomeApi _api;

  @override
  Future<Home> getHome({DateTime? date}) =>
      guardApi(() => _api.getHome(date: date));
}

/// Dépôt de l'accueil. Le flavor mock le remplace par sa version simulée.
final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeApiRepository(ref.watch(omeoApiProvider).getHomeApi()),
);
