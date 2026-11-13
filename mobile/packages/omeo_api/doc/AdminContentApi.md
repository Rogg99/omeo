# omeo_api.api.AdminContentApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminCreateContent**](AdminContentApi.md#admincreatecontent) | **POST** /admin/content/{type} | Crée un contenu en brouillon
[**adminCreateMediaUpload**](AdminContentApi.md#admincreatemediaupload) | **POST** /admin/media | URL présignée pour image, vidéo (transcodée en HLS par une tâche) ou sous-titres VTT
[**adminDeleteContent**](AdminContentApi.md#admindeletecontent) | **DELETE** /admin/content/{type}/{id} | Supprime un brouillon jamais publié (sinon archiver)
[**adminGetContent**](AdminContentApi.md#admingetcontent) | **GET** /admin/content/{type}/{id} | Détail d&#39;un contenu
[**adminListContent**](AdminContentApi.md#adminlistcontent) | **GET** /admin/content/{type} | Liste des contenus d&#39;un type
[**adminListRevisions**](AdminContentApi.md#adminlistrevisions) | **GET** /admin/content/{type}/{id}/revisions | Historique des versions d&#39;un contenu
[**adminMachineTranslate**](AdminContentApi.md#adminmachinetranslate) | **POST** /admin/content/{type}/{id}/translate | Propose une traduction IA des champs manquants (à relire, non publiée)
[**adminTransitionContent**](AdminContentApi.md#admintransitioncontent) | **POST** /admin/content/{type}/{id}/transition | brouillon → relecture → publié → archivé
[**adminTranslationCoverage**](AdminContentApi.md#admintranslationcoverage) | **GET** /admin/translations | Couverture des traductions par type de contenu et langue
[**adminUpdateContent**](AdminContentApi.md#adminupdatecontent) | **PATCH** /admin/content/{type}/{id} | Modifie (verrou optimiste via &#x60;version&#x60;)


# **adminCreateContent**
> AdminContentItem adminCreateContent(type, adminContentPayload)

Crée un contenu en brouillon

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminContentApi();
final ContentTypeName type = ; // ContentTypeName | 
final AdminContentPayload adminContentPayload = ; // AdminContentPayload | 

try {
    final response = api.adminCreateContent(type, adminContentPayload);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminContentApi->adminCreateContent: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | [**ContentTypeName**](.md)|  | 
 **adminContentPayload** | [**AdminContentPayload**](AdminContentPayload.md)|  | 

### Return type

[**AdminContentItem**](AdminContentItem.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminCreateMediaUpload**
> UploadTicket adminCreateMediaUpload(adminCreateMediaUploadRequest)

URL présignée pour image, vidéo (transcodée en HLS par une tâche) ou sous-titres VTT

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminContentApi();
final AdminCreateMediaUploadRequest adminCreateMediaUploadRequest = ; // AdminCreateMediaUploadRequest | 

try {
    final response = api.adminCreateMediaUpload(adminCreateMediaUploadRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminContentApi->adminCreateMediaUpload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **adminCreateMediaUploadRequest** | [**AdminCreateMediaUploadRequest**](AdminCreateMediaUploadRequest.md)|  | 

### Return type

[**UploadTicket**](UploadTicket.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminDeleteContent**
> adminDeleteContent(type, id)

Supprime un brouillon jamais publié (sinon archiver)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminContentApi();
final ContentTypeName type = ; // ContentTypeName | 
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.adminDeleteContent(type, id);
} on DioException catch (e) {
    print('Exception when calling AdminContentApi->adminDeleteContent: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | [**ContentTypeName**](.md)|  | 
 **id** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminGetContent**
> AdminContentItem adminGetContent(type, id)

Détail d'un contenu

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminContentApi();
final ContentTypeName type = ; // ContentTypeName | 
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.adminGetContent(type, id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminContentApi->adminGetContent: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | [**ContentTypeName**](.md)|  | 
 **id** | **String**|  | 

### Return type

[**AdminContentItem**](AdminContentItem.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminListContent**
> AdminListContent200Response adminListContent(type, q, status, missingLocale, page, pageSize, ordering)

Liste des contenus d'un type

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminContentApi();
final ContentTypeName type = ; // ContentTypeName | 
final String q = q_example; // String | 
final ContentStatus status = ; // ContentStatus | 
final Locale missingLocale = ; // Locale | 
final int page = 56; // int | 
final int pageSize = 56; // int | 
final String ordering = ordering_example; // String | 

try {
    final response = api.adminListContent(type, q, status, missingLocale, page, pageSize, ordering);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminContentApi->adminListContent: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | [**ContentTypeName**](.md)|  | 
 **q** | **String**|  | [optional] 
 **status** | [**ContentStatus**](.md)|  | [optional] 
 **missingLocale** | [**Locale**](.md)|  | [optional] 
 **page** | **int**|  | [optional] [default to 1]
 **pageSize** | **int**|  | [optional] [default to 25]
 **ordering** | **String**|  | [optional] 

### Return type

[**AdminListContent200Response**](AdminListContent200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminListRevisions**
> List<AdminListRevisions200ResponseInner> adminListRevisions(type, id)

Historique des versions d'un contenu

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminContentApi();
final ContentTypeName type = ; // ContentTypeName | 
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.adminListRevisions(type, id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminContentApi->adminListRevisions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | [**ContentTypeName**](.md)|  | 
 **id** | **String**|  | 

### Return type

[**List&lt;AdminListRevisions200ResponseInner&gt;**](AdminListRevisions200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminMachineTranslate**
> Map<String, Map<String, String>> adminMachineTranslate(type, id, adminMachineTranslateRequest)

Propose une traduction IA des champs manquants (à relire, non publiée)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminContentApi();
final ContentTypeName type = ; // ContentTypeName | 
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final AdminMachineTranslateRequest adminMachineTranslateRequest = ; // AdminMachineTranslateRequest | 

try {
    final response = api.adminMachineTranslate(type, id, adminMachineTranslateRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminContentApi->adminMachineTranslate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | [**ContentTypeName**](.md)|  | 
 **id** | **String**|  | 
 **adminMachineTranslateRequest** | [**AdminMachineTranslateRequest**](AdminMachineTranslateRequest.md)|  | 

### Return type

[**Map&lt;String, Map&lt;String, String&gt;&gt;**](Map.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminTransitionContent**
> AdminContentItem adminTransitionContent(type, id, adminTransitionContentRequest)

brouillon → relecture → publié → archivé

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminContentApi();
final ContentTypeName type = ; // ContentTypeName | 
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final AdminTransitionContentRequest adminTransitionContentRequest = ; // AdminTransitionContentRequest | 

try {
    final response = api.adminTransitionContent(type, id, adminTransitionContentRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminContentApi->adminTransitionContent: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | [**ContentTypeName**](.md)|  | 
 **id** | **String**|  | 
 **adminTransitionContentRequest** | [**AdminTransitionContentRequest**](AdminTransitionContentRequest.md)|  | 

### Return type

[**AdminContentItem**](AdminContentItem.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminTranslationCoverage**
> List<AdminTranslationCoverage200ResponseInner> adminTranslationCoverage()

Couverture des traductions par type de contenu et langue

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminContentApi();

try {
    final response = api.adminTranslationCoverage();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminContentApi->adminTranslationCoverage: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List&lt;AdminTranslationCoverage200ResponseInner&gt;**](AdminTranslationCoverage200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminUpdateContent**
> AdminContentItem adminUpdateContent(type, id, adminContentPayload)

Modifie (verrou optimiste via `version`)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminContentApi();
final ContentTypeName type = ; // ContentTypeName | 
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final AdminContentPayload adminContentPayload = ; // AdminContentPayload | 

try {
    final response = api.adminUpdateContent(type, id, adminContentPayload);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminContentApi->adminUpdateContent: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | [**ContentTypeName**](.md)|  | 
 **id** | **String**|  | 
 **adminContentPayload** | [**AdminContentPayload**](AdminContentPayload.md)|  | 

### Return type

[**AdminContentItem**](AdminContentItem.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

