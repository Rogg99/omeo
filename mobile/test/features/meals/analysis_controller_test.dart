import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/features/meals/application/analysis_controller.dart';
import 'package:omeo/features/meals/data/meals_repository.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/meals_mock_repository.dart';

ProviderContainer _container(MockBackend backend) {
  final c = ProviderContainer(
    overrides: [
      mealsRepositoryProvider.overrideWithValue(MealsMockRepository(backend)),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('photo : compression, envoi, analyse réussie', () async {
    final backend = MockBackend(latency: Duration.zero)
      ..analysisLatency = Duration.zero;
    final c = _container(backend);
    final sub = c.listen(analysisControllerProvider, (_, _) {});
    final photo = img.encodePng(img.Image(width: 2000, height: 1500));
    await c.read(analysisControllerProvider.notifier).analyzePhoto(photo);
    final state = sub.read();
    expect(state, isA<AnalysisDone>());
    expect((state as AnalysisDone).unusable, isFalse);
  });

  test('texte « flou » en Plus : photo inexploitable (MEA-08)', () async {
    final backend = MockBackend(
      latency: Duration.zero,
      scenario: MockScenario.plus,
    )..analysisLatency = Duration.zero;
    final c = _container(backend);
    final sub = c.listen(analysisControllerProvider, (_, _) {});
    await c.read(analysisControllerProvider.notifier).analyzeText('flou');
    expect((sub.read() as AnalysisDone).unusable, isTrue);
  });

  test('saisie texte en Free : erreur plan_required', () async {
    final backend = MockBackend(
      latency: Duration.zero,
      scenario: MockScenario.free,
    );
    final c = _container(backend);
    final sub = c.listen(analysisControllerProvider, (_, _) {});
    await c.read(analysisControllerProvider.notifier).analyzeText('ndolé');
    final state = sub.read() as AnalysisError;
    expect((state.failure as ProblemFailure).code, ProblemCodes.planRequired);
  });
}
