# omeo_api.api.ActivityApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createActivity**](ActivityApi.md#createactivity) | **POST** /me/activities | Saisie manuelle (secours). Calories estimées par l&#39;API
[**deleteActivity**](ActivityApi.md#deleteactivity) | **DELETE** /me/activities/{id} | Supprime une activité
[**deleteHealthConnection**](ActivityApi.md#deletehealthconnection) | **DELETE** /me/health/connection | Déconnexion (les données déjà importées sont conservées)
[**getActivityOverview**](ActivityApi.md#getactivityoverview) | **GET** /me/activity | Écran Sport — pas, distance, calories, balance du jour et de la semaine, séances
[**listActivities**](ActivityApi.md#listactivities) | **GET** /me/activities | Activités physiques
[**listInsights**](ActivityApi.md#listinsights) | **GET** /me/insights | Analyses croisées nutrition × activité (Plus)
[**mergeActivity**](ActivityApi.md#mergeactivity) | **POST** /me/activities/{id}/merge | Fusionne une saisie manuelle dans une séance importée qui la recouvre
[**setHealthConnection**](ActivityApi.md#sethealthconnection) | **PUT** /me/health/connection | Déclare la connexion à Health Connect / Apple Health et les types autorisés
[**syncHealth**](ActivityApi.md#synchealth) | **POST** /me/health/sync | Envoie les totaux par jour, séances et pesées lus sur l&#39;appareil (upsert idempotent)
[**updateActivity**](ActivityApi.md#updateactivity) | **PATCH** /me/activities/{id} | Modifie une activité manuelle


# **createActivity**
> ActivityWriteResult createActivity(idempotencyKey, activityInput)

Saisie manuelle (secours). Calories estimées par l'API

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getActivityApi();
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h).
final ActivityInput activityInput = ; // ActivityInput | 

try {
    final response = api.createActivity(idempotencyKey, activityInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ActivityApi->createActivity: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**| UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h). | 
 **activityInput** | [**ActivityInput**](ActivityInput.md)|  | 

### Return type

[**ActivityWriteResult**](ActivityWriteResult.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteActivity**
> DeleteMeal200Response deleteActivity(id)

Supprime une activité

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getActivityApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.deleteActivity(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ActivityApi->deleteActivity: $e\n');
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

# **deleteHealthConnection**
> deleteHealthConnection()

Déconnexion (les données déjà importées sont conservées)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getActivityApi();

try {
    api.deleteHealthConnection();
} on DioException catch (e) {
    print('Exception when calling ActivityApi->deleteHealthConnection: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getActivityOverview**
> ActivityOverview getActivityOverview(date)

Écran Sport — pas, distance, calories, balance du jour et de la semaine, séances

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getActivityApi();
final DateTime date = 2013-10-20; // DateTime | Journée locale. Défaut : aujourd'hui

try {
    final response = api.getActivityOverview(date);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ActivityApi->getActivityOverview: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **date** | **DateTime**| Journée locale. Défaut : aujourd'hui | [optional] 

### Return type

[**ActivityOverview**](ActivityOverview.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listActivities**
> ListActivities200Response listActivities(from, to, cursor, limit)

Activités physiques

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getActivityApi();
final DateTime from = 2013-10-20; // DateTime | 
final DateTime to = 2013-10-20; // DateTime | 
final String cursor = cursor_example; // String | 
final int limit = 56; // int | 

try {
    final response = api.listActivities(from, to, cursor, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ActivityApi->listActivities: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **from** | **DateTime**|  | [optional] 
 **to** | **DateTime**|  | [optional] 
 **cursor** | **String**|  | [optional] 
 **limit** | **int**|  | [optional] [default to 20]

### Return type

[**ListActivities200Response**](ListActivities200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listInsights**
> ListInsights200Response listInsights(cursor)

Analyses croisées nutrition × activité (Plus)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getActivityApi();
final String cursor = cursor_example; // String | 

try {
    final response = api.listInsights(cursor);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ActivityApi->listInsights: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **cursor** | **String**|  | [optional] 

### Return type

[**ListInsights200Response**](ListInsights200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mergeActivity**
> ActivityWriteResult mergeActivity(id, mergeActivityRequest)

Fusionne une saisie manuelle dans une séance importée qui la recouvre

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getActivityApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final MergeActivityRequest mergeActivityRequest = ; // MergeActivityRequest | 

try {
    final response = api.mergeActivity(id, mergeActivityRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ActivityApi->mergeActivity: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **mergeActivityRequest** | [**MergeActivityRequest**](MergeActivityRequest.md)|  | 

### Return type

[**ActivityWriteResult**](ActivityWriteResult.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setHealthConnection**
> HealthConnection setHealthConnection(setHealthConnectionRequest)

Déclare la connexion à Health Connect / Apple Health et les types autorisés

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getActivityApi();
final SetHealthConnectionRequest setHealthConnectionRequest = ; // SetHealthConnectionRequest | 

try {
    final response = api.setHealthConnection(setHealthConnectionRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ActivityApi->setHealthConnection: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **setHealthConnectionRequest** | [**SetHealthConnectionRequest**](SetHealthConnectionRequest.md)|  | 

### Return type

[**HealthConnection**](HealthConnection.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **syncHealth**
> SyncHealth200Response syncHealth(idempotencyKey, healthSyncInput)

Envoie les totaux par jour, séances et pesées lus sur l'appareil (upsert idempotent)

Le mobile ne lit que les jours modifiés depuis `last_sync_at` (maximum 30 jours en arrière). L'API recalcule balance, objectifs, points et challenges des jours concernés. 

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getActivityApi();
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h).
final HealthSyncInput healthSyncInput = ; // HealthSyncInput | 

try {
    final response = api.syncHealth(idempotencyKey, healthSyncInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ActivityApi->syncHealth: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**| UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h). | 
 **healthSyncInput** | [**HealthSyncInput**](HealthSyncInput.md)|  | 

### Return type

[**SyncHealth200Response**](SyncHealth200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateActivity**
> ActivityWriteResult updateActivity(id, activityInput)

Modifie une activité manuelle

Seules les activités manuelles sont modifiables.

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getActivityApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final ActivityInput activityInput = ; // ActivityInput | 

try {
    final response = api.updateActivity(id, activityInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ActivityApi->updateActivity: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **activityInput** | [**ActivityInput**](ActivityInput.md)|  | 

### Return type

[**ActivityWriteResult**](ActivityWriteResult.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

