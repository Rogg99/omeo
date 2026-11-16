import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo_api/omeo_api.dart';

/// Types lus sur l'appareil (lecture seule, jamais d'écriture).
typedef HealthType = SetHealthConnectionRequestGrantedTypesEnum;

/// Autorisation Health Connect / Apple Health de l'appareil, demandée au
/// moment où elle sert (PRO-05). Derrière une interface : la lecture réelle
/// passe par le paquet natif, le flavor mock fournit une fausse.
abstract interface class HealthAccess {
  /// Source disponible sur ce téléphone.
  SetHealthConnectionRequestSource_Enum get source;

  /// Demande l'accès en lecture ; renvoie les types accordés (vide : refus).
  Future<Set<HealthType>> requestRead(Set<HealthType> types);
}

/// Accès santé de l'appareil. `null` tant que l'intégration native n'est
/// pas configurée : la connexion santé est alors masquée.
final Provider<HealthAccess?> healthAccessProvider = Provider((ref) => null);

/// Connexion santé déclarée à l'API (les données lues restent sur
/// l'appareil jusqu'à la synchronisation des totaux par jour).
abstract interface class HealthRepository {
  Future<HealthConnection> connect({
    required SetHealthConnectionRequestSource_Enum source,
    required Set<HealthType> granted,
  });

  /// Les données déjà importées sont conservées.
  Future<void> disconnect();
}

final class HealthApiRepository implements HealthRepository {
  const HealthApiRepository(this._api);

  final ActivityApi _api;

  @override
  Future<HealthConnection> connect({
    required SetHealthConnectionRequestSource_Enum source,
    required Set<HealthType> granted,
  }) => guardApi(
    () => _api.setHealthConnection(
      setHealthConnectionRequest: SetHealthConnectionRequest(
        source_: source,
        grantedTypes: granted.toList(),
      ),
    ),
  );

  @override
  Future<void> disconnect() => guardApi(_api.deleteHealthConnection);
}

final Provider<HealthRepository> healthRepositoryProvider = Provider(
  (ref) => HealthApiRepository(ref.watch(omeoApiProvider).getActivityApi()),
);
