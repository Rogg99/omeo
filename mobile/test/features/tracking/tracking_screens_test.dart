import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/offline/offline_queue.dart';
import 'package:omeo/core/offline/offline_store.dart';
import 'package:omeo/features/tracking/application/tracking_controllers.dart';
import 'package:omeo/features/tracking/data/tracking_repository.dart';
import 'package:omeo/features/tracking/presentation/journal_screen.dart';
import 'package:omeo/features/tracking/presentation/progress_screen.dart';
import 'package:omeo/features/tracking/presentation/weight_screen.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/tracking_mock.dart';

import '../auth/auth_test_app.dart';

final List<Override> _overrides = [
  ...trackingMockOverrides(),
  offlineStoreProvider.overrideWithValue(MemoryOfflineStore()),
  connectivityProvider.overrideWith((ref) => Stream.value(true)),
];

void main() {
  group('journal (HIS-01 à HIS-04)', () {
    testWidgets('jour courant : objectif, repas et hydratation', (
      tester,
    ) async {
      final added = <String>[];
      await pumpWithMocks(
        tester,
        Scaffold(
          body: JournalScreen(
            navigation: (
              addMeal: (t) => added.add(t.value),
              openMeal: null,
            ),
          ),
        ),
        overrides: _overrides,
      );
      expect(find.text('Objectif du jour'), findsOne);
      expect(find.text('Bouillie de mil'), findsOne);
      expect(find.text('Hydratation'), findsOne);
      await tester.tap(find.bySemanticsLabel('Ajouter au Dîner'));
      expect(added, ['dinner']);
    });

    testWidgets('hier : journée vide, invitation douce', (tester) async {
      final container = await pumpWithMocks(
        tester,
        Scaffold(
          body: JournalScreen(navigation: (addMeal: (_) {}, openMeal: null)),
        ),
        overrides: _overrides,
      );
      await tester.tap(find.bySemanticsLabel('Jour précédent'));
      await tester.pumpAndSettle();
      expect(find.text('Hier'), findsOne);
      expect(find.text("Rien d'enregistré ce jour-là"), findsOne);
      expect(
        container.read(journalDayProvider),
        DateUtils.dateOnly(DateTime.now()).subtract(const Duration(days: 1)),
      );
    });
  });

  test('eau : mise en attente sans réseau, même clé au rejeu', () async {
    final backend = instantBackend()..setNetworkDown(down: true);
    final store = MemoryOfflineStore();
    final container = ProviderContainer(
      overrides: [
        ..._overrides,
        offlineStoreProvider.overrideWithValue(store),
        trackingRepositoryProvider.overrideWithValue(
          TrackingMockRepository(backend),
        ),
      ],
    );
    addTearDown(container.dispose);
    final outcome = await container
        .read(waterWriterProvider)
        .add(amountMl: 250, date: DateTime.now());
    expect(outcome, isA<TrackingQueued<Object?>>());
    final pending = await store.all();
    expect(pending.single.kind, waterAddKind);
    expect(pending.single.payload['amount_ml'], 250);

    backend.setNetworkDown(down: false);
    await container.read(offlineQueueProvider).replay();
    expect(await store.all(), isEmpty);
  });

  test('erreur de l’API : remontée, rien en attente', () async {
    final backend = instantBackend(scenario: MockScenario.error500);
    final store = MemoryOfflineStore();
    final container = ProviderContainer(
      overrides: [
        ..._overrides,
        offlineStoreProvider.overrideWithValue(store),
        trackingRepositoryProvider.overrideWithValue(
          TrackingMockRepository(backend),
        ),
      ],
    );
    addTearDown(container.dispose);
    await expectLater(
      container
          .read(weightWriterProvider)
          .add(weightKg: 78, date: DateTime.now()),
      throwsA(isA<ProblemFailure>()),
    );
    expect(await store.all(), isEmpty);
  });

  group('progression (PRO-01 à PRO-04)', () {
    Widget screen() => Scaffold(
      body: ProgressScreen(
        navigation: (
          discoverPlus: () {},
          scanMeal: () {},
          connectHealth: () {},
          openWeight: () {},
        ),
      ),
    );

    testWidgets('7 jours : total du jour et onglets', (tester) async {
      await pumpWithMocks(tester, screen(), overrides: _overrides);
      expect(find.text('Calories'), findsWidgets);
      expect(find.text('Sel'), findsWidgets);
      expect(find.textContaining('vs hier'), findsOne);
    });

    testWidgets('Free : 30 jours verrouillés, aperçu et Plus', (tester) async {
      final container = await pumpWithMocks(
        tester,
        screen(),
        overrides: _overrides,
      );
      container
          .read(progressSelectionProvider.notifier)
          .range(
            ProgressRange.month,
          );
      await tester.pumpAndSettle();
      expect(find.text('Ta tendance sur la durée'), findsOne);
      expect(find.text('Découvrir Omeo Plus'), findsOne);
    });

    testWidgets('journée vide : courbes à venir (PRO-04)', (tester) async {
      await pumpWithMocks(
        tester,
        screen(),
        backend: instantBackend(scenario: MockScenario.emptyDay),
        overrides: _overrides,
      );
      expect(find.text('Tes courbes arrivent'), findsOne);
      expect(find.text('Scanner un repas'), findsOne);
    });
  });

  testWidgets('poids (PRO-06) : mesures avec leur source', (tester) async {
    await pumpWithMocks(tester, const WeightScreen(), overrides: _overrides);
    expect(find.text('78,4 kg'), findsWidgets);
    expect(find.textContaining('Saisie manuelle'), findsOne);
    expect(find.textContaining('Health Connect'), findsWidgets);
  });

  testWidgets('nouvelle pesée (PRO-07) : réglage au dixième', (tester) async {
    await pumpWithMocks(
      tester,
      const Scaffold(body: WeighInSheet(initialKg: 78.4)),
      overrides: _overrides,
    );
    expect(find.text('78,4'), findsOne);
    await tester.tap(find.textContaining('0,1').first);
    await tester.pump();
    expect(find.text('78,3'), findsOne);
    expect(find.textContaining('recalculés'), findsOne);
  });
}
