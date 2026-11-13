# omeo_api.api.AdminTeamApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminCancelApproval**](AdminTeamApi.md#admincancelapproval) | **POST** /admin/approvals/{id}/cancel | Annule sa propre demande en attente
[**adminDecideApproval**](AdminTeamApi.md#admindecideapproval) | **POST** /admin/approvals/{id}/decision | Approuve (applique l&#39;action) ou rejette — jamais sa propre demande
[**adminGetMe**](AdminTeamApi.md#admingetme) | **GET** /admin/me | Membre de l&#39;équipe connecté, rôles et permissions (pour filtrer le menu)
[**adminInviteStaff**](AdminTeamApi.md#admininvitestaff) | **POST** /admin/team | Invite un membre (email d&#39;invitation, 2FA à configurer à la première connexion)
[**adminListApprovals**](AdminTeamApi.md#adminlistapprovals) | **GET** /admin/approvals | Demandes à valider (filtrées sur les domaines de la personne) et demandes émises
[**adminListAudit**](AdminTeamApi.md#adminlistaudit) | **GET** /admin/audit | Journal d&#39;audit
[**adminListTeam**](AdminTeamApi.md#adminlistteam) | **GET** /admin/team | Membres de l&#39;équipe
[**adminSetupMfa**](AdminTeamApi.md#adminsetupmfa) | **POST** /admin/mfa/setup | Génère le secret TOTP (QR) puis le confirme avec un code
[**adminUpdateStaff**](AdminTeamApi.md#adminupdatestaff) | **PATCH** /admin/team/{id} | Modifie un membre de l&#39;équipe (rôle, état)


# **adminCancelApproval**
> ApprovalRequest adminCancelApproval(id)

Annule sa propre demande en attente

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminTeamApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.adminCancelApproval(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminTeamApi->adminCancelApproval: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ApprovalRequest**](ApprovalRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminDecideApproval**
> ApprovalRequest adminDecideApproval(id, adminDecideApprovalRequest)

Approuve (applique l'action) ou rejette — jamais sa propre demande

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminTeamApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final AdminDecideApprovalRequest adminDecideApprovalRequest = ; // AdminDecideApprovalRequest | 

try {
    final response = api.adminDecideApproval(id, adminDecideApprovalRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminTeamApi->adminDecideApproval: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **adminDecideApprovalRequest** | [**AdminDecideApprovalRequest**](AdminDecideApprovalRequest.md)|  | 

### Return type

[**ApprovalRequest**](ApprovalRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminGetMe**
> StaffMember adminGetMe()

Membre de l'équipe connecté, rôles et permissions (pour filtrer le menu)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminTeamApi();

try {
    final response = api.adminGetMe();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminTeamApi->adminGetMe: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**StaffMember**](StaffMember.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminInviteStaff**
> StaffMember adminInviteStaff(adminInviteStaffRequest)

Invite un membre (email d'invitation, 2FA à configurer à la première connexion)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminTeamApi();
final AdminInviteStaffRequest adminInviteStaffRequest = ; // AdminInviteStaffRequest | 

try {
    final response = api.adminInviteStaff(adminInviteStaffRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminTeamApi->adminInviteStaff: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **adminInviteStaffRequest** | [**AdminInviteStaffRequest**](AdminInviteStaffRequest.md)|  | 

### Return type

[**StaffMember**](StaffMember.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminListApprovals**
> AdminListApprovals200Response adminListApprovals(status, mine, page, pageSize)

Demandes à valider (filtrées sur les domaines de la personne) et demandes émises

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminTeamApi();
final String status = status_example; // String | 
final bool mine = true; // bool | Demandes que j'ai émises
final int page = 56; // int | 
final int pageSize = 56; // int | 

try {
    final response = api.adminListApprovals(status, mine, page, pageSize);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminTeamApi->adminListApprovals: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | [optional] 
 **mine** | **bool**| Demandes que j'ai émises | [optional] 
 **page** | **int**|  | [optional] [default to 1]
 **pageSize** | **int**|  | [optional] [default to 25]

### Return type

[**AdminListApprovals200Response**](AdminListApprovals200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminListAudit**
> AdminListAudit200Response adminListAudit(actorId, action, targetType, targetId, from, to, page, pageSize)

Journal d'audit

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminTeamApi();
final String actorId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String action = action_example; // String | 
final String targetType = targetType_example; // String | 
final String targetId = targetId_example; // String | 
final DateTime from = 2013-10-20; // DateTime | 
final DateTime to = 2013-10-20; // DateTime | 
final int page = 56; // int | 
final int pageSize = 56; // int | 

try {
    final response = api.adminListAudit(actorId, action, targetType, targetId, from, to, page, pageSize);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminTeamApi->adminListAudit: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **actorId** | **String**|  | [optional] 
 **action** | **String**|  | [optional] 
 **targetType** | **String**|  | [optional] 
 **targetId** | **String**|  | [optional] 
 **from** | **DateTime**|  | [optional] 
 **to** | **DateTime**|  | [optional] 
 **page** | **int**|  | [optional] [default to 1]
 **pageSize** | **int**|  | [optional] [default to 25]

### Return type

[**AdminListAudit200Response**](AdminListAudit200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminListTeam**
> List<StaffMember> adminListTeam()

Membres de l'équipe

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminTeamApi();

try {
    final response = api.adminListTeam();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminTeamApi->adminListTeam: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List&lt;StaffMember&gt;**](StaffMember.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminSetupMfa**
> AdminSetupMfa200Response adminSetupMfa(adminSetupMfaRequest)

Génère le secret TOTP (QR) puis le confirme avec un code

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminTeamApi();
final AdminSetupMfaRequest adminSetupMfaRequest = ; // AdminSetupMfaRequest | 

try {
    final response = api.adminSetupMfa(adminSetupMfaRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminTeamApi->adminSetupMfa: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **adminSetupMfaRequest** | [**AdminSetupMfaRequest**](AdminSetupMfaRequest.md)|  | [optional] 

### Return type

[**AdminSetupMfa200Response**](AdminSetupMfa200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminUpdateStaff**
> StaffMember adminUpdateStaff(id, adminUpdateStaffRequest)

Modifie un membre de l'équipe (rôle, état)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminTeamApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final AdminUpdateStaffRequest adminUpdateStaffRequest = ; // AdminUpdateStaffRequest | 

try {
    final response = api.adminUpdateStaff(id, adminUpdateStaffRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminTeamApi->adminUpdateStaff: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **adminUpdateStaffRequest** | [**AdminUpdateStaffRequest**](AdminUpdateStaffRequest.md)|  | 

### Return type

[**StaffMember**](StaffMember.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

