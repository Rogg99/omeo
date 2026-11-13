# omeo_api.api.AdminUsersApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminGetUser**](AdminUsersApi.md#admingetuser) | **GET** /admin/users/{id} | Fiche utilisateur (données santé masquées)
[**adminListUsers**](AdminUsersApi.md#adminlistusers) | **GET** /admin/users | Liste des utilisateurs
[**adminRevealUserHealth**](AdminUsersApi.md#adminrevealuserhealth) | **GET** /admin/users/{id}/health | Révèle les données de santé (consultation journalisée, motif obligatoire)
[**adminUserAction**](AdminUsersApi.md#adminuseraction) | **POST** /admin/users/{id}/actions | Action sur un compte (journalisée)


# **adminGetUser**
> AdminUserDetail adminGetUser(id)

Fiche utilisateur (données santé masquées)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminUsersApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.adminGetUser(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminUsersApi->adminGetUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**AdminUserDetail**](AdminUserDetail.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminListUsers**
> AdminListUsers200Response adminListUsers(q, plan, status, country, page, pageSize, ordering)

Liste des utilisateurs

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminUsersApi();
final String q = q_example; // String | 
final PlanTier plan = ; // PlanTier | 
final String status = status_example; // String | 
final String country = country_example; // String | 
final int page = 56; // int | 
final int pageSize = 56; // int | 
final String ordering = ordering_example; // String | 

try {
    final response = api.adminListUsers(q, plan, status, country, page, pageSize, ordering);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminUsersApi->adminListUsers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional] 
 **plan** | [**PlanTier**](.md)|  | [optional] 
 **status** | **String**|  | [optional] 
 **country** | **String**|  | [optional] 
 **page** | **int**|  | [optional] [default to 1]
 **pageSize** | **int**|  | [optional] [default to 25]
 **ordering** | **String**|  | [optional] 

### Return type

[**AdminListUsers200Response**](AdminListUsers200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminRevealUserHealth**
> AdminUserHealth adminRevealUserHealth(id, reason)

Révèle les données de santé (consultation journalisée, motif obligatoire)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminUsersApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String reason = reason_example; // String | 

try {
    final response = api.adminRevealUserHealth(id, reason);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminUsersApi->adminRevealUserHealth: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **reason** | **String**|  | 

### Return type

[**AdminUserHealth**](AdminUserHealth.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminUserAction**
> AdminUserDetail adminUserAction(id, adminUserActionInput)

Action sur un compte (journalisée)

Rôles par action — support : resend_verification, send_password_reset, extend_trial ; finance : grant_plus_days, reset_quota ; superadmin : tout, dont suspend, reactivate, export_data, delete_data. 

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminUsersApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final AdminUserActionInput adminUserActionInput = ; // AdminUserActionInput | 

try {
    final response = api.adminUserAction(id, adminUserActionInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminUsersApi->adminUserAction: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **adminUserActionInput** | [**AdminUserActionInput**](AdminUserActionInput.md)|  | 

### Return type

[**AdminUserDetail**](AdminUserDetail.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

