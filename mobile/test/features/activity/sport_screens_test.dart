import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/features/activity/data/activity_repository.dart';
import 'package:omeo/features/activity/data/health_reader.dart';
import 'package:omeo/features/activity/presentation/add_activity_screen.dart';
import 'package:omeo/features/activity/presentation/sport_screen.dart';
import 'package:omeo/features/activity/presentation/week_screen.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/activity_mock_repository.dart';

import 'activity_actions_test.dart' show FakeHealthReader;

final _taps = <String>[];

Widget _app(Widget home, {MockScenario scenario = MockScenario.trial}) =>
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        healthReaderProvider.overrideWithValue(FakeHealthReader()),
        activityRepositoryProvider.overrideWithValue(
          ActivityMockRepository(
            MockBackend(latency: Duration.zero, scenario: scenario),
          ),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: OmeoTheme.light(),
        home: home,
      ),
    );

final SportScreen _sport = SportScreen(
  navigation: (
    onBack: () {},
    onAddActivity: () => _taps.add('add'),
    onWeek: () => _taps.add('week'),
    onWorkout: (w) => _taps.add('workout:${w.name}'),
    onAllWorkouts: () => _taps.add('all'),
  ),
);

void main() {
  setUp(_taps.clear);

  testWidgets('SPO-01 : pas, balance, activités et séances', (tester) async {
    await tester.pumpWidget(_app(_sport));
    await tester.pumpAndSettle();
    expect(find.text('6 420'), findsOneWidget);
    expect(find.text('Course à pied'), findsOneWidget);
    expect(find.text('Manuel'), findsOneWidget);
    expect(find.text('Importe tes pas et tes séances'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Ajouter une activité'));
    await tester.tap(find.text('Semaine'));
    expect(_taps, ['add', 'week']);
  });

  testWidgets('SPO-01 + SPO-03 : connexion puis fusion proposée', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_sport));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Même activité ?'), findsOneWidget);
    await tester.tap(find.text('Garder la séance importée'));
    await tester.pumpAndSettle();
    expect(find.text('Même activité ?'), findsNothing);
    expect(find.text('Manuel'), findsNothing);
  });

  testWidgets('journée vide : invitation à ajouter', (tester) async {
    await tester.pumpWidget(_app(_sport, scenario: MockScenario.emptyDay));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aucune activité aujourd'), findsOneWidget);
  });

  testWidgets('SPO-02 : activité, durée, intensité puis enregistrement', (
    tester,
  ) async {
    var saved = 0;
    await tester.pumpWidget(
      _app(AddActivityScreen(onClose: () {}, onSaved: (_) => saved++)),
    );
    await tester.tap(find.text('Football'));
    await tester.tap(find.bySemanticsLabel('Plus'));
    await tester.tap(find.text('Intense'));
    await tester.pump();
    expect(find.text('35'), findsOneWidget);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(saved, 1);
  });

  testWidgets('SPO-04 : barres de la semaine et accès aux analyses', (
    tester,
  ) async {
    var insights = 0;
    await tester.pumpWidget(
      _app(WeekBalanceScreen(onBack: () {}, onInsights: () => insights++)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mangé'), findsOneWidget);
    expect(find.bySemanticsLabel('Mangé et dépensé, jour par jour'), findsOne);
    await tester.tap(find.text('Analyses de la semaine'));
    expect(insights, 1);
  });

  testWidgets('SPO-05 : constats en Plus', (tester) async {
    await tester.pumpWidget(
      _app(InsightsScreen(onBack: () {}), scenario: MockScenario.plus),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Tu bouges plus le week-end'), findsOneWidget);
  });
}
