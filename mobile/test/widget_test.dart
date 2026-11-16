import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/app/app.dart';
import 'package:omeo/app/bootstrap.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/core/api/global_errors.dart';
import 'package:omeo/core/config/app_config.dart';
import 'package:omeo/core/offline/offline_queue.dart';
import 'package:omeo/core/offline/offline_store.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/mock_overrides.dart';

Future<ProviderContainer> _pumpMockApp(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(390, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localesTestValue = const [Locale('fr')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      appConfigProvider.overrideWithValue(
        const AppConfig(
          flavor: Flavor.mock,
          dataSource: DataSource.mock,
          apiBaseUrl: '',
        ),
      ),
      ...mockOverrides(),
      // Pas de SQLite dans les tests : file d'attente en mémoire.
      offlineStoreProvider.overrideWithValue(MemoryOfflineStore()),
    ],
  );
  addTearDown(container.dispose);
  container.read(mockBackendProvider).latency = Duration.zero;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MediaQuery(
        data: MediaQueryData(size: Size(390, 2400), disableAnimations: true),
        child: OmeoApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('flavor mock : l’app démarre sur l’accueil simulé', (
    tester,
  ) async {
    await _pumpMockApp(tester);
    expect(find.text('Bonjour, Awa'), findsOneWidget);
  });

  testWidgets('426 : écran de mise à jour bloquant', (tester) async {
    final container = await _pumpMockApp(tester);
    container.read(globalErrorBusProvider).emit(const UpgradeRequired());
    await tester.pumpAndSettle();
    expect(find.text('Une mise à jour est nécessaire'), findsOneWidget);
  });

  testWidgets('compte suspendu : écran dédié', (tester) async {
    final container = await _pumpMockApp(tester);
    container.read(mockBackendProvider).setScenario(MockScenario.suspended);
    container.read(globalErrorBusProvider).emit(const AccountSuspended());
    await tester.pumpAndSettle();
    expect(find.text('Ton compte est suspendu'), findsOneWidget);
  });

  testWidgets(
    'quota épuisé en Free : une seule feuille, date de remise à zéro',
    (
      tester,
    ) async {
      final container = await _pumpMockApp(tester);
      final bus = container.read(globalErrorBusProvider);
      final event = QuotaExceeded(
        canUpgrade: true,
        resetsAt: DateTime.utc(2026, 11, 10, 12),
      );
      bus
        ..emit(event)
        ..emit(event);
      await tester.pumpAndSettle();
      expect(find.text('Limite atteinte'), findsOneWidget);
      expect(find.textContaining('10 novembre'), findsOneWidget);
      await tester.tap(find.text('Compris'));
      await tester.pumpAndSettle();
      expect(find.text('Limite atteinte'), findsNothing);
    },
  );

  test('le thème expose les tokens du mode clair', () {
    expect(
      OmeoTheme.light().extension<OmeoColors>()!.tokens.primary,
      OmeoTokens.light.primary,
    );
  });
}
