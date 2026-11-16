import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/offline/offline_queue.dart';
import 'package:omeo/core/offline/offline_store.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/features/meals/application/meal_writer.dart';
import 'package:omeo/features/meals/presentation/offline_banner.dart';

Future<MemoryOfflineStore> _pump(
  WidgetTester tester, {
  required bool online,
}) async {
  final store = MemoryOfflineStore();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        offlineStoreProvider.overrideWithValue(store),
        connectivityProvider.overrideWith((ref) => Stream.value(online)),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: OmeoTheme.light(),
        home: const Scaffold(body: OfflineBanner()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

PendingWrite _meal(String id) => PendingWrite(
  id: id,
  kind: mealCreateKind,
  idempotencyKey: id,
  payload: const {},
  createdAt: DateTime(2026),
);

void main() {
  testWidgets('en ligne sans attente : rien', (tester) async {
    await _pump(tester, online: true);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('hors connexion avec 2 repas en attente', (tester) async {
    final store = await _pump(tester, online: false);
    expect(find.text('Hors connexion'), findsOneWidget);
    await store.put(_meal('a'));
    await store.put(_meal('b'));
    await tester.pumpAndSettle();
    expect(
      find.text("Hors connexion · 2 repas en attente d'envoi"),
      findsOneWidget,
    );
  });

  testWidgets('retour du réseau : envoi en cours', (tester) async {
    final store = await _pump(tester, online: true);
    await store.put(_meal('a'));
    await tester.pumpAndSettle();
    expect(find.text('Envoi de 1 repas…'), findsOneWidget);
  });
}
