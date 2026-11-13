# omeo_api.api.AdminDashboardApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminDashboard**](AdminDashboardApi.md#admindashboard) | **GET** /admin/dashboard | Indicateurs (inscriptions, actifs, rétention, conversion, revenus par canal, IA, avis, support)


# **adminDashboard**
> AdminDashboard adminDashboard(from, to, country, locale, platform)

Indicateurs (inscriptions, actifs, rétention, conversion, revenus par canal, IA, avis, support)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminDashboardApi();
final DateTime from = 2013-10-20; // DateTime | 
final DateTime to = 2013-10-20; // DateTime | 
final String country = country_example; // String | 
final Locale locale = ; // Locale | 
final String platform = platform_example; // String | 

try {
    final response = api.adminDashboard(from, to, country, locale, platform);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminDashboardApi->adminDashboard: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **from** | **DateTime**|  | 
 **to** | **DateTime**|  | 
 **country** | **String**|  | [optional] 
 **locale** | [**Locale**](.md)|  | [optional] 
 **platform** | **String**|  | [optional] 

### Return type

[**AdminDashboard**](AdminDashboard.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

