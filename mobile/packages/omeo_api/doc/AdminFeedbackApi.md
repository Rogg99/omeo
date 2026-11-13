# omeo_api.api.AdminFeedbackApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminFeedbackStats**](AdminFeedbackApi.md#adminfeedbackstats) | **GET** /admin/feedback/stats | Fiabilité perçue par plat et par pays, plats les plus contestés
[**adminGetFeedback**](AdminFeedbackApi.md#admingetfeedback) | **GET** /admin/feedback/{id} | Photo, réponse IA d&#39;origine, version corrigée, commentaire
[**adminListFeedback**](AdminFeedbackApi.md#adminlistfeedback) | **GET** /admin/feedback | Avis sur les analyses
[**adminResolveFeedback**](AdminFeedbackApi.md#adminresolvefeedback) | **POST** /admin/feedback/{id}/resolve | Traite un avis sur une analyse


# **adminFeedbackStats**
> AdminFeedbackStats adminFeedbackStats(from, to)

Fiabilité perçue par plat et par pays, plats les plus contestés

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminFeedbackApi();
final DateTime from = 2013-10-20; // DateTime | 
final DateTime to = 2013-10-20; // DateTime | 

try {
    final response = api.adminFeedbackStats(from, to);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminFeedbackApi->adminFeedbackStats: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **from** | **DateTime**|  | [optional] 
 **to** | **DateTime**|  | [optional] 

### Return type

[**AdminFeedbackStats**](AdminFeedbackStats.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminGetFeedback**
> AdminFeedbackDetail adminGetFeedback(id)

Photo, réponse IA d'origine, version corrigée, commentaire

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminFeedbackApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.adminGetFeedback(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminFeedbackApi->adminGetFeedback: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**AdminFeedbackDetail**](AdminFeedbackDetail.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminListFeedback**
> AdminListFeedback200Response adminListFeedback(rating, reason, status, dishId, maxConfidence, locale, from, to, page, pageSize)

Avis sur les analyses

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminFeedbackApi();
final String rating = rating_example; // String | 
final FeedbackReason reason = ; // FeedbackReason | 
final String status = status_example; // String | 
final String dishId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final num maxConfidence = 8.14; // num | 
final Locale locale = ; // Locale | 
final DateTime from = 2013-10-20; // DateTime | 
final DateTime to = 2013-10-20; // DateTime | 
final int page = 56; // int | 
final int pageSize = 56; // int | 

try {
    final response = api.adminListFeedback(rating, reason, status, dishId, maxConfidence, locale, from, to, page, pageSize);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminFeedbackApi->adminListFeedback: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **rating** | **String**|  | [optional] 
 **reason** | [**FeedbackReason**](.md)|  | [optional] 
 **status** | **String**|  | [optional] 
 **dishId** | **String**|  | [optional] 
 **maxConfidence** | **num**|  | [optional] 
 **locale** | [**Locale**](.md)|  | [optional] 
 **from** | **DateTime**|  | [optional] 
 **to** | **DateTime**|  | [optional] 
 **page** | **int**|  | [optional] [default to 1]
 **pageSize** | **int**|  | [optional] [default to 25]

### Return type

[**AdminListFeedback200Response**](AdminListFeedback200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminResolveFeedback**
> AdminResolveFeedback200Response adminResolveFeedback(id, adminResolveFeedbackRequest)

Traite un avis sur une analyse

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminFeedbackApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final AdminResolveFeedbackRequest adminResolveFeedbackRequest = ; // AdminResolveFeedbackRequest | 

try {
    final response = api.adminResolveFeedback(id, adminResolveFeedbackRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminFeedbackApi->adminResolveFeedback: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **adminResolveFeedbackRequest** | [**AdminResolveFeedbackRequest**](AdminResolveFeedbackRequest.md)|  | 

### Return type

[**AdminResolveFeedback200Response**](AdminResolveFeedback200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

