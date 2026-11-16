import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/features/meals/data/meals_repository.dart';
import 'package:omeo/features/meals/data/speech_transcriber.dart';
import 'package:omeo/features/meals/presentation/describe_meal_screen.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/meals_mock_repository.dart';

/// Transcription de test : renvoie une phrase fixe, ou un refus.
class _FakeTranscriber implements SpeechTranscriber {
  _FakeTranscriber({this.problem});

  final TranscriberUnavailable? problem;
  void Function()? _stopped;

  @override
  Future<TranscriberUnavailable?> prepare() async => problem;

  @override
  Future<void> start({
    required String localeTag,
    required void Function(String text) onText,
    required void Function(double level) onLevel,
    required void Function() onStopped,
  }) async {
    _stopped = onStopped;
    onLevel(0.5);
    onText('Une assiette de ndolé avec deux plantains frits');
  }

  @override
  Future<void> stop() async => _stopped?.call();
}

Widget _app(SpeechTranscriber speech, ValueChanged<String> onAnalyze) =>
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        speechTranscriberProvider.overrideWithValue(speech),
        mealsRepositoryProvider.overrideWithValue(
          MealsMockRepository(
            MockBackend(latency: Duration.zero, scenario: MockScenario.plus),
          ),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: OmeoTheme.light(),
        home: DescribeMealScreen(onClose: () {}, onAnalyze: onAnalyze),
      ),
    );

void main() {
  testWidgets('dictée : transcription en direct puis analyse', (
    tester,
  ) async {
    final analyzed = <String>[];
    await tester.pumpWidget(_app(_FakeTranscriber(), analyzed.add));
    await tester.pumpAndSettle();
    expect(find.text('7 saisies restantes ce mois-ci'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Parler'));
    await tester.pumpAndSettle();
    expect(
      find.text('Une assiette de ndolé avec deux plantains frits'),
      findsOneWidget,
    );
    expect(find.text('Analyser'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Arrêter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analyser'));
    expect(analyzed, ['Une assiette de ndolé avec deux plantains frits']);
  });

  testWidgets('micro refusé : bascule sur le texte avec explication', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_FakeTranscriber(problem: TranscriberUnavailable.denied), (_) {}),
    );
    await tester.tap(find.bySemanticsLabel('Parler'));
    await tester.pumpAndSettle();
    expect(find.textContaining("Le micro n'est pas autorisé"), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('texte : un exemple remplit la saisie', (tester) async {
    final analyzed = <String>[];
    await tester.pumpWidget(_app(_FakeTranscriber(), analyzed.add));
    await tester.tap(find.text('Texte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Garba au thon'));
    await tester.pump();
    await tester.tap(find.text('Analyser'));
    expect(analyzed, ['Garba au thon']);
  });
}
