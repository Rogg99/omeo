# omeo_api.api.AppApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getAppConfig**](AppApi.md#getappconfig) | **GET** /app/config | Configuration publique (version minimale, langues, features, villes suggérées)
[**searchCities**](AppApi.md#searchcities) | **GET** /app/cities | Suggestions de villes (onboarding, profil)


# **getAppConfig**
> AppConfig getAppConfig()

Configuration publique (version minimale, langues, features, villes suggérées)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAppApi();

try {
    final response = api.getAppConfig();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AppApi->getAppConfig: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AppConfig**](AppConfig.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchCities**
> SearchCities200Response searchCities(q, country)

Suggestions de villes (onboarding, profil)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAppApi();
final String q = q_example; // String | 
final String country = country_example; // String | 

try {
    final response = api.searchCities(q, country);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AppApi->searchCities: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional] 
 **country** | **String**|  | [optional] 

### Return type

[**SearchCities200Response**](SearchCities200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

