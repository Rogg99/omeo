# omeo_api.api.TrackingApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addWater**](TrackingApi.md#addwater) | **POST** /me/water | Ajoute de l&#39;eau (verre 250 ml, bouteille 500 ml, ou libre). Valeur négative &#x3D; annulation
[**addWeight**](TrackingApi.md#addweight) | **POST** /me/weights | Saisie manuelle (l&#39;emporte sur l&#39;import le même jour). Recalcule les objectifs
[**deleteWeight**](TrackingApi.md#deleteweight) | **DELETE** /me/weights/{id} | Supprime une pesée
[**getProgress**](TrackingApi.md#getprogress) | **GET** /me/progress | Courbe d&#39;un nutriment (7 j en Free ; 30 j, 90 j, 1 an en Plus)
[**getWeights**](TrackingApi.md#getweights) | **GET** /me/weights | Courbe du poids, cible, écart, tendance


# **addWater**
> AddWater201Response addWater(idempotencyKey, addWaterRequest)

Ajoute de l'eau (verre 250 ml, bouteille 500 ml, ou libre). Valeur négative = annulation

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getTrackingApi();
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h).
final AddWaterRequest addWaterRequest = ; // AddWaterRequest | 

try {
    final response = api.addWater(idempotencyKey, addWaterRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling TrackingApi->addWater: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**| UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h). | 
 **addWaterRequest** | [**AddWaterRequest**](AddWaterRequest.md)|  | 

### Return type

[**AddWater201Response**](AddWater201Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **addWeight**
> AddWeight201Response addWeight(idempotencyKey, addWeightRequest)

Saisie manuelle (l'emporte sur l'import le même jour). Recalcule les objectifs

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getTrackingApi();
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h).
final AddWeightRequest addWeightRequest = ; // AddWeightRequest | 

try {
    final response = api.addWeight(idempotencyKey, addWeightRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling TrackingApi->addWeight: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**| UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h). | 
 **addWeightRequest** | [**AddWeightRequest**](AddWeightRequest.md)|  | 

### Return type

[**AddWeight201Response**](AddWeight201Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteWeight**
> WeightOverview deleteWeight(id)

Supprime une pesée

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getTrackingApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.deleteWeight(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling TrackingApi->deleteWeight: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**WeightOverview**](WeightOverview.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getProgress**
> Progress getProgress(metric, range)

Courbe d'un nutriment (7 j en Free ; 30 j, 90 j, 1 an en Plus)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getTrackingApi();
final String metric = metric_example; // String | 
final String range = range_example; // String | 

try {
    final response = api.getProgress(metric, range);
    print(response);
} on DioException catch (e) {
    print('Exception when calling TrackingApi->getProgress: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **metric** | **String**|  | 
 **range** | **String**|  | [optional] [default to '7d']

### Return type

[**Progress**](Progress.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getWeights**
> WeightOverview getWeights(range)

Courbe du poids, cible, écart, tendance

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getTrackingApi();
final String range = range_example; // String | 

try {
    final response = api.getWeights(range);
    print(response);
} on DioException catch (e) {
    print('Exception when calling TrackingApi->getWeights: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **range** | **String**|  | [optional] [default to '90d']

### Return type

[**WeightOverview**](WeightOverview.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

