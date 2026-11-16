import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo_api/omeo_api.dart';

/// Activité physique : aperçu du jour, saisie de secours, fusion avec les
/// séances importées, synchronisation santé et analyses croisées.
abstract interface class ActivityRepository {
  /// [date] nulle : aujourd'hui (fuseau envoyé dans X-Timezone).
  Future<ActivityOverview> getOverview({DateTime? date});

  /// L'API estime les calories ; elle peut proposer une fusion.
  Future<ActivityWriteResult> createActivity(
    ActivityInput input, {
    required String idempotencyKey,
  });

  /// Fusionne la saisie manuelle [manualId] dans l'activité importée.
  Future<ActivityWriteResult> mergeActivity(
    String manualId, {
    required String intoId,
  });

  Future<void> deleteActivity(String id);

  /// Enregistre les types de données autorisés par l'utilisateur.
  Future<HealthConnection> setHealthConnection(
    SetHealthConnectionRequest request,
  );

  /// Totaux par jour lus sur l'appareil ; l'API renvoie les jours
  /// recalculés.
  Future<SyncHealth200Response> syncHealth(
    HealthSyncInput input, {
    required String idempotencyKey,
  });

  /// Constats hebdomadaires nutrition × activité (Plus).
  Future<List<Insight>> listInsights();
}

/// Implémentation sur l'API réelle.
final class ActivityApiRepository implements ActivityRepository {
  const ActivityApiRepository(this._api);

  final ActivityApi _api;

  @override
  Future<ActivityOverview> getOverview({DateTime? date}) =>
      guardApi(() => _api.getActivityOverview(date: date));

  @override
  Future<ActivityWriteResult> createActivity(
    ActivityInput input, {
    required String idempotencyKey,
  }) => guardApi(
    () => _api.createActivity(
      idempotencyKey: idempotencyKey,
      activityInput: input,
    ),
  );

  @override
  Future<ActivityWriteResult> mergeActivity(
    String manualId, {
    required String intoId,
  }) => guardApi(
    () => _api.mergeActivity(
      id: manualId,
      mergeActivityRequest: MergeActivityRequest(intoId: intoId),
    ),
  );

  @override
  Future<void> deleteActivity(String id) =>
      guardApi(() => _api.deleteActivity(id: id));

  @override
  Future<HealthConnection> setHealthConnection(
    SetHealthConnectionRequest request,
  ) => guardApi(
    () => _api.setHealthConnection(setHealthConnectionRequest: request),
  );

  @override
  Future<SyncHealth200Response> syncHealth(
    HealthSyncInput input, {
    required String idempotencyKey,
  }) => guardApi(
    () => _api.syncHealth(
      idempotencyKey: idempotencyKey,
      healthSyncInput: input,
    ),
  );

  @override
  Future<List<Insight>> listInsights() async =>
      (await guardApi(_api.listInsights)).results;
}

/// Dépôt de l'activité. Le flavor mock le remplace par sa version simulée.
final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityApiRepository(ref.watch(omeoApiProvider).getActivityApi()),
);
