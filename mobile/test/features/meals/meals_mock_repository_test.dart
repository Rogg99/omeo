import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/mock/fixtures/meals_fixtures.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo/mock/repositories/meals_mock_repository.dart';
import 'package:omeo_api/omeo_api.dart';

void main() {
  late MockBackend backend;
  late MealsMockRepository repo;

  setUp(() {
    backend = MockBackend(latency: Duration.zero)
      ..analysisLatency = Duration.zero;
    repo = MealsMockRepository(backend);
  });

  test("l'analyse photo passe à succeeded et décompte le quota", () async {
    final created = await repo.createPhotoAnalysis(
      uploadId: 'u',
      idempotencyKey: 'k',
    );
    expect(created.status, AnalysisStatusEnum.queued);
    final poll = await repo.getAnalysis(created.id);
    expect(poll.analysis.status, AnalysisStatusEnum.succeeded);
    expect(poll.analysis.alternatives, hasLength(3));
    final quotas = await repo.getQuotas();
    expect(quotas.first.remaining, 1);
  });

  test('quota épuisé : 429 quota_exceeded avec proposition de Plus', () {
    backend.scenario = MockScenario.quotaExhausted;
    expect(
      repo.createPhotoAnalysis(uploadId: 'u', idempotencyKey: 'k'),
      throwsA(
        isA<ProblemFailure>()
            .having((f) => f.code, 'code', ProblemCodes.quotaExceeded)
            .having((f) => f.meta['upgrade'], 'upgrade', true),
      ),
    );
  });

  test('la saisie texte demande Plus en Free', () {
    backend.scenario = MockScenario.free;
    expect(
      repo.createTextAnalysis(text: 'ndolé', idempotencyKey: 'k'),
      throwsA(
        isA<ProblemFailure>().having(
          (f) => f.code,
          'code',
          ProblemCodes.planRequired,
        ),
      ),
    );
  });

  test('choisir un autre plat remplace le plat sans alternatives', () async {
    final a = await repo.createPhotoAnalysis(
      uploadId: 'u',
      idempotencyKey: 'k',
    );
    final corrected = await repo.selectAnalysisDish(
      analysisId: a.id,
      dishId: yassaPoissonId,
      idempotencyKey: 'k2',
    );
    expect(corrected.dish?.name, 'Yassa poisson');
    expect(corrected.alternatives, isEmpty);
  });

  test("la même clé d'idempotence renvoie le même repas", () async {
    final input = MealInput(
      source_: MealInputSource_Enum.dish,
      mealType: MealType.lunch,
      dishId: ndoleId,
      portions: 1,
    );
    final first = await repo.createMeal(input: input, idempotencyKey: 'same');
    final again = await repo.createMeal(input: input, idempotencyKey: 'same');
    expect(again.meal.id, first.meal.id);
    expect(first.meal.title, 'Ndolé');
  });

  test('favoris du catalogue', () async {
    await repo.setDishFavorite(ndoleId, favorite: true);
    final favs = await repo.searchDishes(scope: 'favorites');
    expect(favs.results.map((d) => d.id), contains(ndoleId));
  });
}
