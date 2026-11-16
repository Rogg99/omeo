import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/features/training/application/screen_awake.dart';
import 'package:omeo/features/training/application/session_controller.dart';
import 'package:omeo/features/training/application/training_controller.dart';
import 'package:omeo/features/training/data/training_repository.dart';
import 'package:omeo/features/training/presentation/exercise_screen.dart';
import 'package:omeo/features/training/presentation/session_screen.dart';
import 'package:omeo/features/training/presentation/training_catalog_screen.dart';
import 'package:omeo/features/training/presentation/workout_screen.dart';
import 'package:omeo/mock/fixtures/activity_fixtures.dart';
import 'package:omeo/mock/fixtures/training_fixtures.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/training_mock_repository.dart';
import 'package:omeo_api/omeo_api.dart' hide Locale;

final _taps = <String>[];

/// Retire les sous-titres : les tests ne font aucun appel réseau.
Map<String, Object?> _withoutSubtitles(Map<String, Object?> json) {
  final copy = jsonDecode(jsonEncode(json)) as Map<String, Object?>;
  void strip(Object? node) {
    if (node is Map<String, Object?>) {
      node.remove('subtitles');
      node.values.forEach(strip);
    } else if (node is List<Object?>) {
      node.forEach(strip);
    }
  }

  strip(copy);
  return copy;
}

/// Dépôt simulé, sans sous-titres à télécharger.
final class _Repo implements TrainingRepository {
  _Repo(MockScenario scenario)
    : _mock = TrainingMockRepository(
        MockBackend(latency: Duration.zero, scenario: scenario),
      );

  final TrainingMockRepository _mock;

  @override
  Future<List<WorkoutSummary>> listWorkouts(WorkoutFilter filter) =>
      _mock.listWorkouts(filter);

  @override
  Future<WorkoutDetail> getWorkout(String id) async => WorkoutDetail.fromJson(
    _withoutSubtitles((await _mock.getWorkout(id)).toJson()),
  );

  @override
  Future<List<ExerciseSummary>> listExercises(ExerciseFilter filter) =>
      _mock.listExercises(filter);

  @override
  Future<ExerciseDetail> getExercise(String id) async =>
      ExerciseDetail.fromJson(
        _withoutSubtitles((await _mock.getExercise(id)).toJson()),
      );

  @override
  Future<GetWorkoutDownload200Response> getWorkoutDownload(String id) =>
      _mock.getWorkoutDownload(id);

  @override
  Future<CompleteWorkoutSession201Response> completeSession(
    CompleteWorkoutSessionRequest request, {
    required String idempotencyKey,
  }) => _mock.completeSession(request, idempotencyKey: idempotencyKey);
}

final class _NoDownloads implements WorkoutDownloads {
  @override
  Future<File?> localVideo(String exerciseId) async => null;

  @override
  Future<bool> isDownloaded(WorkoutDetail workout) async => false;

  @override
  Future<void> download(String workoutId) async {}
}

final class _Awake implements ScreenAwake {
  bool on = false;

  @override
  Future<void> keepOn() async => on = true;

  @override
  Future<void> release() async => on = false;
}

final class _SilentCues implements SessionCues {
  @override
  Future<void> phaseChanged({required bool sound}) async {}
}

Widget _app(
  Widget home, {
  MockScenario scenario = MockScenario.plus,
  _Awake? awake,
}) => ProviderScope(
  retry: (_, _) => null,
  overrides: [
    trainingRepositoryProvider.overrideWithValue(_Repo(scenario)),
    workoutDownloadsProvider.overrideWithValue(_NoDownloads()),
    screenAwakeProvider.overrideWithValue(awake ?? _Awake()),
    sessionCuesProvider.overrideWithValue(_SilentCues()),
  ],
  child: MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: OmeoTheme.light(),
    home: home,
  ),
);

WorkoutScreen _workout(String id) => WorkoutScreen(
  workoutId: id,
  navigation: (
    onBack: () {},
    onStart: (w) => _taps.add('start:${w.name}'),
    onLocked: () => _taps.add('plus'),
  ),
);

SessionScreen get _session => SessionScreen(
  workoutId: cardioSansMaterielId,
  navigation: (
    onQuit: () => _taps.add('quit'),
    onDone: () => _taps.add('done'),
  ),
);

void main() {
  setUp(_taps.clear);

  testWidgets('EXO-03 puis EXO-01 : séances, puis exercices', (tester) async {
    await tester.pumpWidget(
      _app(
        TrainingCatalogScreen(
          onBack: () {},
          onWorkout: (w) => _taps.add(w.name),
          onExercise: (e) => _taps.add(e.name),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Réveil mobilité'), findsOneWidget);
    await tester.tap(find.text('Renfo du soir'));
    expect(_taps, ['Renfo du soir']);

    await tester.tap(find.text('Exercices').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Squat'));
    expect(_taps.last, 'Squat');
  });

  testWidgets('EXO-02 : fiche d’un exercice', (tester) async {
    await tester.pumpWidget(
      _app(ExerciseScreen(exerciseId: squatId, onBack: () {})),
    );
    await tester.pumpAndSettle();
    expect(find.text('Squat'), findsWidgets);
    expect(find.text('Comment faire'), findsOneWidget);
  });

  testWidgets('EXO-04 : détail, puis Commencer', (tester) async {
    await tester.pumpWidget(_app(_workout(cardioSansMaterielId)));
    await tester.pumpAndSettle();
    expect(find.text('Cardio sans matériel'), findsOneWidget);
    expect(find.text('8 exercices'), findsOneWidget);
    await tester.tap(find.text('Commencer'));
    expect(_taps, ['start:Cardio sans matériel']);
  });

  testWidgets('EXO-04 en Free : séance Plus verrouillée', (tester) async {
    await tester.pumpWidget(
      _app(_workout(cardioSansMaterielId), scenario: MockScenario.free),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer'));
    expect(_taps, ['plus']);
  });

  testWidgets('EXO-05 : minuteur, pause, écran maintenu allumé', (
    tester,
  ) async {
    final awake = _Awake();
    await tester.pumpWidget(_app(_session, awake: awake));
    await tester.pumpAndSettle();
    expect(awake.on, isTrue);
    expect(find.text('Jumping jacks'), findsOneWidget);
    expect(find.text('0:40'), findsOneWidget);
    expect(find.text('Exercice 1 / 8'), findsOneWidget);
    expect(
      find.text('Ensuite : Squat · 15 répétitions'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('0:39'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Pause'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('0:39'), findsOneWidget);
    expect(find.bySemanticsLabel('Reprendre'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    expect(awake.on, isFalse);
  });

  testWidgets('EXO-06 : repos, +10 s, puis exercice en répétitions', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_session));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Exercice suivant'));
    await tester.pump();
    expect(find.text('Repos'), findsOneWidget);
    expect(find.text('0:20'), findsOneWidget);
    expect(find.text('À SUIVRE'), findsOneWidget);

    await tester.tap(find.text('+10 s'));
    await tester.pump();
    expect(find.text('0:30'), findsOneWidget);

    await tester.tap(find.text('Passer'));
    await tester.pump();
    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('15 répétitions'), findsOneWidget);
    expect(find.bySemanticsLabel("C'est fait"), findsOneWidget);
  });

  testWidgets('quitter demande confirmation', (tester) async {
    await tester.pumpWidget(_app(_session));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Quitter la séance'));
    await tester.pumpAndSettle();
    expect(find.text('Quitter la séance ?'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(_taps, isEmpty);

    await tester.tap(find.bySemanticsLabel('Quitter la séance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitter'));
    await tester.pumpAndSettle();
    expect(_taps, ['quit']);
  });

  testWidgets('EXO-07 : récapitulatif renvoyé par l’API', (tester) async {
    await tester.pumpWidget(_app(_session));
    await tester.pumpAndSettle();
    // 8 exercices et 7 repos, passés un à un.
    for (var i = 0; i < 15; i++) {
      final skip = find.text('Passer');
      await tester.tap(
        skip.evaluate().isNotEmpty
            ? skip
            : find.bySemanticsLabel('Exercice suivant'),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('Séance terminée !'), findsOneWidget);
    expect(find.text('196'), findsOneWidget);
    expect(find.textContaining('30'), findsWidgets);

    await tester.tap(find.text('Terminer'));
    expect(_taps, ['done']);
  });

  testWidgets('séance introuvable : état d’erreur', (tester) async {
    await tester.pumpWidget(
      _app(
        SessionScreen(
          workoutId: 'inconnue',
          navigation: (onQuit: () => _taps.add('quit'), onDone: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Cette séance n'a pas pu être chargée"), findsOneWidget);
  });
}
