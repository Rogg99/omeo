import 'dart:async';

import 'package:omeo/core/api/api_failure.dart';

/// Scénarios du panneau de développement (socle commun, « mock réaliste »).
enum MockScenario {
  trial,
  free,
  plus,
  quotaExhausted,
  emptyDay,
  firstLaunch,
  error401,
  error403PlanRequired,
  error426,
  error429,
  error500,
  offline,
  suspended,
}

/// Faux serveur en mémoire : latence, scénario, coupure réseau et état de la
/// session. N'existe que dans le flavor mock (lib/mock/ n'est importé que par
/// main_mock.dart).
class MockBackend {
  MockBackend({
    this.scenario = MockScenario.trial,
    this.latency = const Duration(milliseconds: 300),
  });

  MockScenario scenario;

  /// Latence simulée des appels (300 ms par défaut).
  Duration latency;

  /// Latence des analyses IA (plus de 3 s, états queued puis processing).
  Duration analysisLatency = const Duration(milliseconds: 3200);

  /// Coupure réseau simulée, indépendante du scénario.
  bool networkDown = false;

  /// Écritures de la session, par dépôt (remises à zéro par [reset]).
  final Map<String, Object?> state = {};

  final _changes = StreamController<void>.broadcast();

  /// Notifie les écrans quand le scénario ou l'état change.
  Stream<void> get changes => _changes.stream;

  void reset() {
    state.clear();
    networkDown = false;
    _changes.add(null);
  }

  void setScenario(MockScenario value) {
    scenario = value;
    state.clear();
    _changes.add(null);
  }

  void setNetworkDown({required bool down}) {
    networkDown = down;
    _changes.add(null);
  }

  bool get isOffline => networkDown || scenario == MockScenario.offline;

  /// Simule un appel : latence, réseau, erreurs du scénario, puis [body].
  Future<T> call<T>(FutureOr<T> Function() body, {Duration? delay}) async {
    await Future<void>.delayed(delay ?? latency);
    if (isOffline) throw const NetworkFailure();
    final failure = _scenarioFailure();
    if (failure != null) throw failure;
    return body();
  }

  ProblemFailure? _scenarioFailure() => switch (scenario) {
    MockScenario.error401 => const ProblemFailure(
      status: 401,
      code: ProblemCodes.notAuthenticated,
    ),
    MockScenario.error403PlanRequired => const ProblemFailure(
      status: 403,
      code: ProblemCodes.planRequired,
      meta: {'feature': 'insights'},
    ),
    MockScenario.error426 => const ProblemFailure(
      status: 426,
      code: ProblemCodes.upgradeRequired,
    ),
    MockScenario.error429 => ProblemFailure(
      status: 429,
      code: ProblemCodes.quotaExceeded,
      meta: {
        'feature': 'photo_analysis',
        'resets_at': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 6))
            .toIso8601String(),
        'upgrade': true,
      },
    ),
    MockScenario.error500 => const ProblemFailure(
      status: 500,
      code: 'server_error',
    ),
    MockScenario.suspended => const ProblemFailure(
      status: 403,
      code: ProblemCodes.accountSuspended,
      meta: {'support_url': 'https://my-omeo.app/support'},
    ),
    _ => null,
  };

  Future<void> dispose() => _changes.close();
}
