import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/core/api/token_store.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/mock/auth_mock.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/mock_backend_provider.dart';

/// Faux serveur sans latence, pour des tests rapides et déterministes.
MockBackend instantBackend({MockScenario scenario = MockScenario.free}) =>
    MockBackend(scenario: scenario, latency: Duration.zero)
      ..analysisLatency = Duration.zero;

/// Monte un écran avec les dépôts simulés de l'authentification.
Future<ProviderContainer> pumpWithMocks(
  WidgetTester tester,
  Widget child, {
  MockBackend? backend,
  List<Override> overrides = const [],
  Locale locale = const Locale('fr'),
}) async {
  tester.view
    ..physicalSize = const Size(390, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      mockBackendProvider.overrideWithValue(backend ?? instantBackend()),
      tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
      ...authMockOverrides(),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: OmeoTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 1600),
            disableAnimations: true,
          ),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}
