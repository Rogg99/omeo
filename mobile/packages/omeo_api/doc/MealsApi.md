# omeo_api.api.MealsApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createAnalysis**](MealsApi.md#createanalysis) | **POST** /me/analyses | Lance une analyse IA (photo ou texte)
[**createMeal**](MealsApi.md#createmeal) | **POST** /me/meals | Enregistre un repas (depuis une analyse, un plat, une recette, ou des aliments)
[**deleteMeal**](MealsApi.md#deletemeal) | **DELETE** /me/meals/{id} | Supprime un repas
[**deleteMealPhoto**](MealsApi.md#deletemealphoto) | **DELETE** /me/meals/{id}/photo | Supprime la photo d&#39;un repas
[**duplicateMeal**](MealsApi.md#duplicatemeal) | **POST** /me/meals/{id}/duplicate | Duplique un repas
[**getAnalysis**](MealsApi.md#getanalysis) | **GET** /me/analyses/{id} | État et résultat d&#39;une analyse
[**getMeal**](MealsApi.md#getmeal) | **GET** /me/meals/{id} | Détail d&#39;un repas
[**getQuotas**](MealsApi.md#getquotas) | **GET** /me/quotas | Quotas restants (affichés avant chaque photo)
[**listMeals**](MealsApi.md#listmeals) | **GET** /me/meals | Repas d&#39;un jour ou d&#39;une période
[**putAnalysisFeedback**](MealsApi.md#putanalysisfeedback) | **PUT** /me/analyses/{id}/feedback | Avis 👍/👎 sur une analyse (crée ou remplace)
[**selectAnalysisDish**](MealsApi.md#selectanalysisdish) | **POST** /me/analyses/{id}/dish | Remplace le plat détecté par un plat du catalogue (« Pas satisfait ? »)
[**suggestMealType**](MealsApi.md#suggestmealtype) | **GET** /me/meal-type-suggestion | Type de repas proposé selon l&#39;heure locale
[**updateMeal**](MealsApi.md#updatemeal) | **PATCH** /me/meals/{id} | Modifie les aliments, le type de repas, ou déplace vers un autre jour


# **createAnalysis**
> Analysis createAnalysis(idempotencyKey, createAnalysisRequest)

Lance une analyse IA (photo ou texte)

Décompte le quota dans la même transaction (remboursé si l'analyse échoue). Texte libre / vocal = Plus uniquement (403 `plan_required`). Saisie vocale transcrite sur l'appareil. 

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getMealsApi();
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h).
final CreateAnalysisRequest createAnalysisRequest = ; // CreateAnalysisRequest | 

try {
    final response = api.createAnalysis(idempotencyKey, createAnalysisRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MealsApi->createAnalysis: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**| UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h). | 
 **createAnalysisRequest** | [**CreateAnalysisRequest**](CreateAnalysisRequest.md)|  | 

### Return type

[**Analysis**](Analysis.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createMeal**
> MealWriteResult createMeal(idempotencyKey, mealInput)

Enregistre un repas (depuis une analyse, un plat, une recette, ou des aliments)

Les valeurs nutritionnelles sont calculées depuis la base d'aliments, jamais depuis l'IA.

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getMealsApi();
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h).
final MealInput mealInput = ; // MealInput | 

try {
    final response = api.createMeal(idempotencyKey, mealInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MealsApi->createMeal: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**| UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h). | 
 **mealInput** | [**MealInput**](MealInput.md)|  | 

### Return type

[**MealWriteResult**](MealWriteResult.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteMeal**
> DeleteMeal200Response deleteMeal(id)

Supprime un repas

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getMealsApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.deleteMeal(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MealsApi->deleteMeal: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**DeleteMeal200Response**](DeleteMeal200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteMealPhoto**
> deleteMealPhoto(id)

Supprime la photo d'un repas

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getMealsApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.deleteMealPhoto(id);
} on DioException catch (e) {
    print('Exception when calling MealsApi->deleteMealPhoto: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **duplicateMeal**
> MealWriteResult duplicateMeal(id, idempotencyKey, duplicateMealRequest)

Duplique un repas

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getMealsApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h).
final DuplicateMealRequest duplicateMealRequest = ; // DuplicateMealRequest | 

try {
    final response = api.duplicateMeal(id, idempotencyKey, duplicateMealRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MealsApi->duplicateMeal: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **idempotencyKey** | **String**| UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h). | 
 **duplicateMealRequest** | [**DuplicateMealRequest**](DuplicateMealRequest.md)|  | 

### Return type

[**MealWriteResult**](MealWriteResult.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAnalysis**
> Analysis getAnalysis(id)

État et résultat d'une analyse

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getMealsApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getAnalysis(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MealsApi->getAnalysis: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**Analysis**](Analysis.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMeal**
> Meal getMeal(id)

Détail d'un repas

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getMealsApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getMeal(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MealsApi->getMeal: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**Meal**](Meal.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getQuotas**
> List<Quota> getQuotas()

Quotas restants (affichés avant chaque photo)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getMealsApi();

try {
    final response = api.getQuotas();
    print(response);
} on DioException catch (e) {
    print('Exception when calling MealsApi->getQuotas: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List&lt;Quota&gt;**](Quota.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMeals**
> ListMeals200Response listMeals(date, from, to, cursor, limit)

Repas d'un jour ou d'une période

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getMealsApi();
final DateTime date = 2013-10-20; // DateTime | 
final DateTime from = 2013-10-20; // DateTime | 
final DateTime to = 2013-10-20; // DateTime | 
final String cursor = cursor_example; // String | 
final int limit = 56; // int | 

try {
    final response = api.listMeals(date, from, to, cursor, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MealsApi->listMeals: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **date** | **DateTime**|  | [optional] 
 **from** | **DateTime**|  | [optional] 
 **to** | **DateTime**|  | [optional] 
 **cursor** | **String**|  | [optional] 
 **limit** | **int**|  | [optional] [default to 20]

### Return type

[**ListMeals200Response**](ListMeals200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **putAnalysisFeedback**
> PutAnalysisFeedback200Response putAnalysisFeedback(id, feedbackInput)

Avis 👍/👎 sur une analyse (crée ou remplace)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getMealsApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final FeedbackInput feedbackInput = ; // FeedbackInput | 

try {
    final response = api.putAnalysisFeedback(id, feedbackInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MealsApi->putAnalysisFeedback: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **feedbackInput** | [**FeedbackInput**](FeedbackInput.md)|  | 

### Return type

[**PutAnalysisFeedback200Response**](PutAnalysisFeedback200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **selectAnalysisDish**
> Analysis selectAnalysisDish(id, idempotencyKey, selectAnalysisDishRequest)

Remplace le plat détecté par un plat du catalogue (« Pas satisfait ? »)

Le plat vient d'une alternative de l'analyse ou de la recherche de plats. L'API recharge sa composition type, recalcule `items` et `totals`, et enregistre l'avis `wrong_dish`. Aucun appel à l'IA, aucun décompte de quota. 409 `conflict` si l'analyse n'est pas `succeeded` ou est déjà liée à un repas. 

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getMealsApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h).
final SelectAnalysisDishRequest selectAnalysisDishRequest = ; // SelectAnalysisDishRequest | 

try {
    final response = api.selectAnalysisDish(id, idempotencyKey, selectAnalysisDishRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MealsApi->selectAnalysisDish: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **idempotencyKey** | **String**| UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h). | 
 **selectAnalysisDishRequest** | [**SelectAnalysisDishRequest**](SelectAnalysisDishRequest.md)|  | 

### Return type

[**Analysis**](Analysis.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **suggestMealType**
> DuplicateMealRequest suggestMealType()

Type de repas proposé selon l'heure locale

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getMealsApi();

try {
    final response = api.suggestMealType();
    print(response);
} on DioException catch (e) {
    print('Exception when calling MealsApi->suggestMealType: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DuplicateMealRequest**](DuplicateMealRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateMeal**
> MealWriteResult updateMeal(id, mealUpdate)

Modifie les aliments, le type de repas, ou déplace vers un autre jour

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getMealsApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final MealUpdate mealUpdate = ; // MealUpdate | 

try {
    final response = api.updateMeal(id, mealUpdate);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MealsApi->updateMeal: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **mealUpdate** | [**MealUpdate**](MealUpdate.md)|  | 

### Return type

[**MealWriteResult**](MealWriteResult.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

