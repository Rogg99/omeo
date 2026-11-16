import 'dart:typed_data';

import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/features/meals/data/meals_repository.dart';
import 'package:omeo/mock/fixtures/meals_fixtures.dart';
import 'package:omeo/mock/mock_backend.dart';
import 'package:omeo_api/omeo_api.dart';
import 'package:uuid/uuid.dart';

/// État de session des repas simulés, conservé dans [MockBackend.state].
final class _MealsState {
  int photoRemaining = 2;
  int analysesCount = 0;
  final Map<String, ({DateTime at, Analysis Function(String) build})> analyses =
      {};
  final Set<String> favorites = {pouletYassaId, fonioLegumesId, sauceGomboId};
  final Map<String, MealWriteResult> writes = {};
}

/// Repas simulés : la photo prise est réelle, seuls l'envoi et l'analyse IA
/// sont simulés. Chaque troisième analyse a une confiance faible (MEA-05),
/// et le texte « flou » donne une photo inexploitable (MEA-08).
final class MealsMockRepository implements MealsRepository {
  MealsMockRepository(this._backend);

  final MockBackend _backend;
  static const _uuid = Uuid();

  _MealsState get _s =>
      (_backend.state['meals'] ??= _MealsState()) as _MealsState;

  bool get _plus => _backend.scenario == MockScenario.plus;

  int get _remaining => switch (_backend.scenario) {
    MockScenario.quotaExhausted => 0,
    MockScenario.plus => 100,
    _ => _s.photoRemaining,
  };

  ProblemFailure _quotaExceeded() => ProblemFailure(
    status: 429,
    code: ProblemCodes.quotaExceeded,
    meta: {
      'feature': 'photo_analysis',
      'resets_at': DateTime.now()
          .toUtc()
          .add(const Duration(hours: 6))
          .toIso8601String(),
      'upgrade': !_plus,
    },
  );

  @override
  Future<List<Quota>> getQuotas() => _backend.call(
    () => quotasFixture(photoRemaining: _remaining, plus: _plus),
  );

  @override
  Future<UploadTicket> createPhotoUpload({
    required int size,
    required String idempotencyKey,
  }) => _backend.call(
    () => UploadTicket.fromJson({
      'id': _uuid.v4(),
      'upload_url': 'https://storage.mock.omeo/uploads/${_uuid.v4()}',
      'method': 'PUT',
      'headers': {'Content-Type': 'image/jpeg'},
      'expires_at': DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 15))
          .toIso8601String(),
    }),
  );

  @override
  Future<void> uploadPhoto(UploadTicket ticket, Uint8List bytes) =>
      _backend.call(() {});

  Analysis _register({required String kind, bool failed = false}) {
    if (_remaining <= 0) throw _quotaExceeded();
    final id = _uuid.v4();
    final at = DateTime.now();
    _s.analysesCount++;
    final low = _s.analysesCount % 3 == 2;
    // L'analyse inexploitable n'est pas décomptée (MEA-08).
    if (!failed && _backend.scenario != MockScenario.plus) _s.photoRemaining--;
    final remaining = _remaining;
    _s.analyses[id] = (
      at: at,
      build: (status) => analysisFixture(
        id: id,
        status: status,
        kind: kind,
        createdAt: at,
        lowConfidence: low,
        failed: failed && status == 'succeeded',
        photoRemaining: remaining,
      ),
    );
    return _s.analyses[id]!.build('queued');
  }

  @override
  Future<Analysis> createPhotoAnalysis({
    required String uploadId,
    required String idempotencyKey,
  }) => _backend.call(() => _register(kind: 'photo'));

  @override
  Future<Analysis> createTextAnalysis({
    required String text,
    required String idempotencyKey,
  }) => _backend.call(() {
    if (!_plus) {
      throw const ProblemFailure(
        status: 403,
        code: ProblemCodes.planRequired,
        meta: {'feature': 'text_analysis'},
      );
    }
    return _register(kind: 'text', failed: text.contains('flou'));
  });

  @override
  Future<AnalysisPoll> getAnalysis(String id) => _backend.call(() {
    final entry = _s.analyses[id];
    if (entry == null) {
      throw const ProblemFailure(status: 404, code: 'not_found');
    }
    final elapsed = DateTime.now().difference(entry.at);
    final total = _backend.analysisLatency;
    final status = elapsed < total * 0.25
        ? 'queued'
        : elapsed < total
        ? 'processing'
        : 'succeeded';
    return (
      analysis: entry.build(status),
      retryAfter: status == 'succeeded' ? null : const Duration(seconds: 1),
    );
  });

  @override
  Future<Analysis> selectAnalysisDish({
    required String analysisId,
    required String dishId,
    required String idempotencyKey,
  }) => _backend.call(() {
    final entry = _s.analyses[analysisId]!;
    final corrected = analysisFixture(
      id: analysisId,
      status: 'succeeded',
      createdAt: entry.at,
      selectedDishId: dishId,
      photoRemaining: _remaining,
    );
    _s.analyses[analysisId] = (at: entry.at, build: (_) => corrected);
    return corrected;
  });

  @override
  Future<void> sendFeedback({
    required String analysisId,
    required FeedbackInput feedback,
  }) => _backend.call(() {});

  @override
  Future<MealWriteResult> createMeal({
    required MealInput input,
    required String idempotencyKey,
  }) => _backend.call(
    () => _s.writes[idempotencyKey] ??= mealWriteFixture(
      mealId: _uuid.v4(),
      input: input,
      title: input.dishId == null
          ? 'Thiéboudienne'
          : dishSummary(input.dishId!).name,
      now: DateTime.now(),
    ),
  );

  @override
  Future<MealType> suggestMealType() => _backend.call(() {
    final hour = DateTime.now().hour;
    return switch (hour) {
      < 11 => MealType.breakfast,
      < 15 => MealType.lunch,
      < 18 => MealType.snack,
      _ => MealType.dinner,
    };
  });

  @override
  Future<SearchDishes200Response> searchDishes({
    String? query,
    String? country,
    String scope = 'all',
  }) => _backend.call(() {
    final result = dishSearchFixture(
      query: query,
      country: country,
      scope: scope == 'favorites' ? 'all' : scope,
    );
    return SearchDishes200Response(
      nextCursor: null,
      results: [
        for (final d in result.results)
          if (scope != 'favorites' || _s.favorites.contains(d.id))
            DishSummary.fromJson({
              ...d.toJson(),
              'is_favorite': _s.favorites.contains(d.id),
            }),
      ],
    );
  });

  @override
  Future<List<FoodSummary>> searchFoods(String query) =>
      _backend.call(() => foodSearchFixture(query));

  @override
  Future<DishDetail> getDish(String id) => _backend.call(
    () => dishDetailFixture(id, favorite: _s.favorites.contains(id)),
  );

  @override
  Future<void> setDishFavorite(String id, {required bool favorite}) =>
      _backend.call(() {
        favorite ? _s.favorites.add(id) : _s.favorites.remove(id);
      });
}
