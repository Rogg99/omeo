import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/features/activity/application/activity_controller.dart';
import 'package:omeo/features/activity/data/activity_repository.dart';
import 'package:omeo/features/activity/data/health_reader.dart';
import 'package:omeo/mock/fixtures/activity_fixtures.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/activity_mock_repository.dart';
import 'package:omeo_api/omeo_api.dart';

/// Lecteur santé de test : disponibilité et accord réglables.
class FakeHealthReader implements HealthReader {
  FakeHealthReader({
    this.status = HealthAvailability.available,
    this.grant = true,
  });

  final HealthAvailability status;
  final bool grant;
  DateTime? readSince;

  @override
  HealthSyncInputSource_Enum get source =>
      HealthSyncInputSource_Enum.healthConnect;

  @override
  Future<HealthAvailability> availability() async => status;

  @override
  Future<void> install() async {}

  @override
  Future<List<SetHealthConnectionRequestGrantedTypesEnum>>
  requestAccess() async =>
      grant ? [SetHealthConnectionRequestGrantedTypesEnum.steps] : const [];

  @override
  Future<HealthSyncInput> read({
    required DateTime since,
    DateTime? until,
  }) async {
    readSince = since;
    return HealthSyncInput(
      source_: source,
      days: [
        HealthSyncInputDaysInner(date: DateTime(2026, 11, 16), steps: 6420),
      ],
    );
  }
}

ProviderContainer _container(HealthReader reader) {
  final c = ProviderContainer(
    overrides: [
      healthReaderProvider.overrideWithValue(reader),
      activityRepositoryProvider.overrideWithValue(
        ActivityMockRepository(MockBackend(latency: Duration.zero)),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('autorisation refusée : rien n’est envoyé', () async {
    final reader = FakeHealthReader(grant: false);
    final c = _container(reader);
    final (outcome, _) = await c.read(activityActionsProvider).connect();
    expect(outcome, HealthConnectOutcome.denied);
    expect(reader.readSince, isNull);
  });

  test('Health Connect à installer', () async {
    final c = _container(
      FakeHealthReader(status: HealthAvailability.needsInstall),
    );
    final (outcome, _) = await c.read(activityActionsProvider).connect();
    expect(outcome, HealthConnectOutcome.needsInstall);
  });

  test('connexion : première lecture sur 30 jours, fusion proposée', () async {
    final reader = FakeHealthReader();
    final c = _container(reader);
    final (outcome, suggestions) = await c
        .read(activityActionsProvider)
        .connect();
    expect(outcome, HealthConnectOutcome.connected);
    final window = DateTime.now().difference(reader.readSince!);
    expect(window.inDays, maxSyncWindow.inDays);
    expect(suggestions.single.manualId, footballId);

    await c.read(activityActionsProvider).merge(suggestions.single);
    final overview = await c.read(activityOverviewProvider.future);
    expect(overview.activities.map((a) => a.id), isNot(contains(footballId)));
  });
}
