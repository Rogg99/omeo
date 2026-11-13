# omeo_api.api.TrainingApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**completeWorkoutSession**](TrainingApi.md#completeworkoutsession) | **POST** /me/workout-sessions | Enregistre une séance terminée (ou partielle). Calories et points calculés par l&#39;API
[**getExercise**](TrainingApi.md#getexercise) | **GET** /exercises/{id} | Détail d&#39;un exercice
[**getWorkout**](TrainingApi.md#getworkout) | **GET** /workouts/{id} | Séance complète avec ses étapes (vidéos HLS + sous-titres)
[**getWorkoutDownload**](TrainingApi.md#getworkoutdownload) | **GET** /workouts/{id}/download | URL signées des médias MP4 pour usage hors connexion (Plus)
[**listExercises**](TrainingApi.md#listexercises) | **GET** /exercises | Catalogue d&#39;exercices
[**listWorkouts**](TrainingApi.md#listworkouts) | **GET** /workouts | Séances


# **completeWorkoutSession**
> CompleteWorkoutSession201Response completeWorkoutSession(idempotencyKey, completeWorkoutSessionRequest)

Enregistre une séance terminée (ou partielle). Calories et points calculés par l'API

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getTrainingApi();
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h).
final CompleteWorkoutSessionRequest completeWorkoutSessionRequest = ; // CompleteWorkoutSessionRequest | 

try {
    final response = api.completeWorkoutSession(idempotencyKey, completeWorkoutSessionRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling TrainingApi->completeWorkoutSession: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**| UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h). | 
 **completeWorkoutSessionRequest** | [**CompleteWorkoutSessionRequest**](CompleteWorkoutSessionRequest.md)|  | 

### Return type

[**CompleteWorkoutSession201Response**](CompleteWorkoutSession201Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getExercise**
> ExerciseDetail getExercise(id)

Détail d'un exercice

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getTrainingApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getExercise(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling TrainingApi->getExercise: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ExerciseDetail**](ExerciseDetail.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getWorkout**
> WorkoutDetail getWorkout(id)

Séance complète avec ses étapes (vidéos HLS + sous-titres)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getTrainingApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getWorkout(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling TrainingApi->getWorkout: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**WorkoutDetail**](WorkoutDetail.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getWorkoutDownload**
> GetWorkoutDownload200Response getWorkoutDownload(id)

URL signées des médias MP4 pour usage hors connexion (Plus)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getTrainingApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getWorkoutDownload(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling TrainingApi->getWorkoutDownload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**GetWorkoutDownload200Response**](GetWorkoutDownload200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listExercises**
> ListExercises200Response listExercises(q, muscle, level, equipment, cursor, limit)

Catalogue d'exercices

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getTrainingApi();
final String q = q_example; // String | 
final String muscle = muscle_example; // String | 
final Level level = ; // Level | 
final String equipment = equipment_example; // String | 
final String cursor = cursor_example; // String | 
final int limit = 56; // int | 

try {
    final response = api.listExercises(q, muscle, level, equipment, cursor, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling TrainingApi->listExercises: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional] 
 **muscle** | **String**|  | [optional] 
 **level** | [**Level**](.md)|  | [optional] 
 **equipment** | **String**|  | [optional] 
 **cursor** | **String**|  | [optional] 
 **limit** | **int**|  | [optional] [default to 20]

### Return type

[**ListExercises200Response**](ListExercises200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listWorkouts**
> ListWorkouts200Response listWorkouts(goal, level, maxMinutes, cursor, limit)

Séances

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getTrainingApi();
final String goal = goal_example; // String | 
final Level level = ; // Level | 
final int maxMinutes = 56; // int | 
final String cursor = cursor_example; // String | 
final int limit = 56; // int | 

try {
    final response = api.listWorkouts(goal, level, maxMinutes, cursor, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling TrainingApi->listWorkouts: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **goal** | **String**|  | [optional] 
 **level** | [**Level**](.md)|  | [optional] 
 **maxMinutes** | **int**|  | [optional] 
 **cursor** | **String**|  | [optional] 
 **limit** | **int**|  | [optional] [default to 20]

### Return type

[**ListWorkouts200Response**](ListWorkouts200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

