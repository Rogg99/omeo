import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo_api/omeo_api.dart';

/// Analyse lue pendant l'interrogation, avec le délai demandé par l'API
/// avant le prochain appel (en-tête Retry-After).
typedef AnalysisPoll = ({Analysis analysis, Duration? retryAfter});

/// Repas : quotas, envoi de photo, analyses, catalogue et enregistrement.
/// Les écritures reçoivent une clé d'idempotence fournie par l'appelant
/// (persistée avec l'élément en file d'attente hors connexion).
abstract interface class MealsRepository {
  Future<List<Quota>> getQuotas();

  /// POST /me/uploads : ticket d'envoi présigné pour une photo JPEG.
  Future<UploadTicket> createPhotoUpload({
    required int size,
    required String idempotencyKey,
  });

  /// PUT présigné : la photo part directement vers le stockage.
  Future<void> uploadPhoto(UploadTicket ticket, Uint8List bytes);

  Future<Analysis> createPhotoAnalysis({
    required String uploadId,
    required String idempotencyKey,
  });

  Future<Analysis> createTextAnalysis({
    required String text,
    required String idempotencyKey,
  });

  Future<AnalysisPoll> getAnalysis(String id);

  /// « Pas satisfait ? » : corrige le plat sans nouvelle analyse ni quota.
  Future<Analysis> selectAnalysisDish({
    required String analysisId,
    required String dishId,
    required String idempotencyKey,
  });

  Future<void> sendFeedback({
    required String analysisId,
    required FeedbackInput feedback,
  });

  Future<MealWriteResult> createMeal({
    required MealInput input,
    required String idempotencyKey,
  });

  Future<Meal> getMeal(String id);

  /// Déplacer (type, jour) ou corriger un repas ; l'API renvoie le jour
  /// recalculé, et l'ancien jour si le repas en change.
  Future<MealWriteResult> updateMeal(String id, MealUpdate update);

  Future<MealWriteResult> duplicateMeal(
    String id, {
    required DuplicateMealRequest target,
    required String idempotencyKey,
  });

  /// Renvoie le jour recalculé sans le repas.
  Future<DaySummary> deleteMeal(String id);

  /// Supprime la photo seulement ; le repas reste au journal.
  Future<void> deleteMealPhoto(String id);

  /// Type de repas proposé selon l'heure locale (X-Timezone).
  Future<MealType> suggestMealType();

  Future<SearchDishes200Response> searchDishes({
    String? query,
    String? country,
    String scope = 'all',
  });

  Future<List<FoodSummary>> searchFoods(String query);

  Future<DishDetail> getDish(String id);

  Future<void> setDishFavorite(String id, {required bool favorite});
}

/// Implémentation sur l'API réelle.
final class MealsApiRepository implements MealsRepository {
  MealsApiRepository(this._api, {Dio? storage}) : _storage = storage ?? Dio();

  final OmeoApi _api;

  /// Client nu pour le PUT présigné : aucun en-tête d'authentification ne
  /// doit partir vers le stockage.
  final Dio _storage;

  MealsApi get _meals => _api.getMealsApi();
  CatalogApi get _catalog => _api.getCatalogApi();

  @override
  Future<List<Quota>> getQuotas() => guardApi(_meals.getQuotas);

  @override
  Future<UploadTicket> createPhotoUpload({
    required int size,
    required String idempotencyKey,
  }) => guardApi(
    () => _api.getAccountApi().createUpload(
      idempotencyKey: idempotencyKey,
      createUploadRequest: CreateUploadRequest(
        kind: CreateUploadRequestKindEnum.mealPhoto,
        contentType: CreateUploadRequestContentTypeEnum.imageSlashJpeg,
        size: size,
      ),
    ),
  );

  @override
  Future<void> uploadPhoto(UploadTicket ticket, Uint8List bytes) async {
    try {
      await _storage.request<void>(
        ticket.uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          method: ticket.method.value,
          headers: {
            ...ticket.headers,
            Headers.contentLengthHeader: bytes.length,
          },
        ),
      );
    } on DioException catch (e) {
      throw failureFromDio(e);
    }
  }

  // Le client généré fusionne mal le oneOf de POST /me/analyses : le corps
  // est envoyé avec les modèles de chaque variante, sur le client configuré
  // (mêmes intercepteurs, même désérialisation).
  Future<Analysis> _postAnalysis(
    Map<String, dynamic> body,
    String idempotencyKey,
  ) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/me/analyses',
        data: body,
        options: Options(
          headers: {'Idempotency-Key': idempotencyKey},
          extra: {
            'secure': [
              {'type': 'http', 'scheme': 'bearer', 'name': 'bearer'},
            ],
          },
        ),
      );
      return Analysis.fromJson(response.data!);
    } on DioException catch (e) {
      throw failureFromDio(e);
    }
  }

  @override
  Future<Analysis> createPhotoAnalysis({
    required String uploadId,
    required String idempotencyKey,
  }) => _postAnalysis(
    PhotoAnalysisInput(
      kind: PhotoAnalysisInputKindEnum.photo,
      uploadId: uploadId,
    ).toJson(),
    idempotencyKey,
  );

  @override
  Future<Analysis> createTextAnalysis({
    required String text,
    required String idempotencyKey,
  }) => _postAnalysis(
    TextAnalysisInput(
      kind: TextAnalysisInputKindEnum.text,
      text: text,
    ).toJson(),
    idempotencyKey,
  );

  @override
  Future<AnalysisPoll> getAnalysis(String id) async {
    try {
      final response = await _meals.getAnalysis(id: id);
      final retry = int.tryParse(
        response.headers.value('retry-after') ?? '',
      );
      return (
        analysis: response.data!,
        retryAfter: retry == null ? null : Duration(seconds: retry),
      );
    } on DioException catch (e) {
      throw failureFromDio(e);
    }
  }

  @override
  Future<Analysis> selectAnalysisDish({
    required String analysisId,
    required String dishId,
    required String idempotencyKey,
  }) => guardApi(
    () => _meals.selectAnalysisDish(
      id: analysisId,
      idempotencyKey: idempotencyKey,
      selectAnalysisDishRequest: SelectAnalysisDishRequest(dishId: dishId),
    ),
  );

  @override
  Future<void> sendFeedback({
    required String analysisId,
    required FeedbackInput feedback,
  }) => guardApi(
    () => _meals.putAnalysisFeedback(id: analysisId, feedbackInput: feedback),
  );

  @override
  Future<MealWriteResult> createMeal({
    required MealInput input,
    required String idempotencyKey,
  }) => guardApi(
    () => _meals.createMeal(idempotencyKey: idempotencyKey, mealInput: input),
  );

  @override
  Future<Meal> getMeal(String id) => guardApi(() => _meals.getMeal(id: id));

  @override
  Future<MealWriteResult> updateMeal(String id, MealUpdate update) =>
      guardApi(() => _meals.updateMeal(id: id, mealUpdate: update));

  @override
  Future<MealWriteResult> duplicateMeal(
    String id, {
    required DuplicateMealRequest target,
    required String idempotencyKey,
  }) => guardApi(
    () => _meals.duplicateMeal(
      id: id,
      idempotencyKey: idempotencyKey,
      duplicateMealRequest: target,
    ),
  );

  @override
  Future<DaySummary> deleteMeal(String id) async =>
      (await guardApi(() => _meals.deleteMeal(id: id))).day;

  @override
  Future<void> deleteMealPhoto(String id) =>
      guardApi(() => _meals.deleteMealPhoto(id: id));

  @override
  Future<MealType> suggestMealType() async =>
      (await guardApi(_meals.suggestMealType)).mealType;

  @override
  Future<SearchDishes200Response> searchDishes({
    String? query,
    String? country,
    String scope = 'all',
  }) => guardApi(
    () => _catalog.searchDishes(q: query, country: country, scope: scope),
  );

  @override
  Future<List<FoodSummary>> searchFoods(String query) async =>
      (await guardApi(() => _catalog.searchFoods(q: query))).results;

  @override
  Future<DishDetail> getDish(String id) =>
      guardApi(() => _catalog.getDish(id: id));

  @override
  Future<void> setDishFavorite(String id, {required bool favorite}) => guardApi(
    () => favorite
        ? _catalog.favoriteDish(id: id)
        : _catalog.unfavoriteDish(id: id),
  );
}

/// Dépôt des repas. Le flavor mock le remplace par sa version simulée.
final mealsRepositoryProvider = Provider<MealsRepository>(
  (ref) => MealsApiRepository(ref.watch(omeoApiProvider)),
);
