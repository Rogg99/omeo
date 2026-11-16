import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/features/activity/data/activity_repository.dart';
import 'package:omeo/features/activity/data/health_reader.dart';
import 'package:omeo_api/omeo_api.dart';
import 'package:uuid/uuid.dart';

/// Aperçu de l'activité du jour (GET /me/activity).
final FutureProvider<ActivityOverview> activityOverviewProvider =
    FutureProvider.autoDispose(
      (ref) => ref.watch(activityRepositoryProvider).getOverview(),
    );

/// Analyses croisées de la semaine (Plus).
final FutureProvider<List<Insight>> insightsProvider =
    FutureProvider.autoDispose(
      (ref) => ref.watch(activityRepositoryProvider).listInsights(),
    );

/// Issue d'une connexion à la source santé.
enum HealthConnectOutcome { connected, denied, needsInstall, unsupported }

/// Connexion et synchronisation santé, saisie manuelle et fusion.
class ActivityActions {
  ActivityActions(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  ActivityRepository get _repo => _ref.read(activityRepositoryProvider);
  HealthReader get _reader => _ref.read(healthReaderProvider);

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiFailure catch (e) {
      _ref.read(globalErrorBusProvider).report(e);
      rethrow;
    }
  }

  /// Demande l'autorisation (au moment où elle sert), l'enregistre, puis
  /// lance une première synchronisation.
  Future<(HealthConnectOutcome, List<MergeSuggestion>)> connect() async {
    switch (await _reader.availability()) {
      case HealthAvailability.needsInstall:
        return (HealthConnectOutcome.needsInstall, const <MergeSuggestion>[]);
      case HealthAvailability.unsupported:
        return (HealthConnectOutcome.unsupported, const <MergeSuggestion>[]);
      case HealthAvailability.available:
        break;
    }
    final granted = await _reader.requestAccess();
    if (granted.isEmpty) {
      return (HealthConnectOutcome.denied, const <MergeSuggestion>[]);
    }
    await _guard(
      () => _repo.setHealthConnection(
        SetHealthConnectionRequest(
          source_: switch (_reader.source) {
            HealthSyncInputSource_Enum.healthConnect =>
              SetHealthConnectionRequestSource_Enum.healthConnect,
            HealthSyncInputSource_Enum.appleHealth =>
              SetHealthConnectionRequestSource_Enum.appleHealth,
          },
          grantedTypes: granted,
        ),
      ),
    );
    return (HealthConnectOutcome.connected, await sync(since: null));
  }

  /// Envoie les totaux lus sur l'appareil depuis la dernière synchronisation
  /// (30 jours au plus) ; renvoie les fusions proposées par l'API.
  Future<List<MergeSuggestion>> sync({required DateTime? since}) async {
    final now = DateTime.now();
    final input = await _reader.read(
      since: since ?? now.subtract(maxSyncWindow),
      until: now,
    );
    final result = await _guard(
      () => _repo.syncHealth(input, idempotencyKey: _uuid.v4()),
    );
    _ref.invalidate(activityOverviewProvider);
    return result.mergeSuggestions;
  }

  /// Saisie de secours ; l'API estime les calories.
  Future<ActivityWriteResult> add(ActivityInput input) async {
    final result = await _guard(
      () => _repo.createActivity(input, idempotencyKey: _uuid.v4()),
    );
    _ref.invalidate(activityOverviewProvider);
    return result;
  }

  /// Garde la séance importée : la saisie manuelle y est fusionnée.
  Future<void> merge(MergeSuggestion suggestion) async {
    await _guard(
      () => _repo.mergeActivity(
        suggestion.manualId,
        intoId: suggestion.importedId,
      ),
    );
    _ref.invalidate(activityOverviewProvider);
  }
}

final Provider<ActivityActions> activityActionsProvider = Provider(
  ActivityActions.new,
);
