# omeo_api.api.AdminSettingsApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminGetSettings**](AdminSettingsApi.md#admingetsettings) | **GET** /admin/settings | Réglages de l&#39;application
[**adminUpdateSettings**](AdminSettingsApi.md#adminupdatesettings) | **PATCH** /admin/settings | Modifie les réglages de l&#39;application


# **adminGetSettings**
> Settings adminGetSettings()

Réglages de l'application

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminSettingsApi();

try {
    final response = api.adminGetSettings();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminSettingsApi->adminGetSettings: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Settings**](Settings.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminUpdateSettings**
> Settings adminUpdateSettings(settings)

Modifie les réglages de l'application

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminSettingsApi();
final Settings settings = ; // Settings | 

try {
    final response = api.adminUpdateSettings(settings);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminSettingsApi->adminUpdateSettings: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **settings** | [**Settings**](Settings.md)|  | 

### Return type

[**Settings**](Settings.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

