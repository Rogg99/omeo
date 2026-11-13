# omeo_api.api.AdminSupportApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminGetTicket**](AdminSupportApi.md#admingetticket) | **GET** /admin/tickets/{id} | Détail d&#39;une demande au support
[**adminListReplyTemplates**](AdminSupportApi.md#adminlistreplytemplates) | **GET** /admin/reply-templates | Modèles de réponse du support
[**adminListTickets**](AdminSupportApi.md#adminlisttickets) | **GET** /admin/tickets | File des demandes au support
[**adminReplyTicket**](AdminSupportApi.md#adminreplyticket) | **POST** /admin/tickets/{id}/messages | Réponse (email + notification in-app) ou note interne
[**adminUpdateTicket**](AdminSupportApi.md#adminupdateticket) | **PATCH** /admin/tickets/{id} | Met à jour une demande (assignation, statut)


# **adminGetTicket**
> TicketDetail adminGetTicket(id)

Détail d'une demande au support

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminSupportApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.adminGetTicket(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminSupportApi->adminGetTicket: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**TicketDetail**](TicketDetail.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminListReplyTemplates**
> List<AdminListReplyTemplates200ResponseInner> adminListReplyTemplates()

Modèles de réponse du support

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminSupportApi();

try {
    final response = api.adminListReplyTemplates();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminSupportApi->adminListReplyTemplates: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List&lt;AdminListReplyTemplates200ResponseInner&gt;**](AdminListReplyTemplates200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminListTickets**
> AdminListTickets200Response adminListTickets(status, category, assignee, q, page, pageSize)

File des demandes au support

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminSupportApi();
final TicketStatus status = ; // TicketStatus | 
final TicketCategory category = ; // TicketCategory | 
final String assignee = assignee_example; // String | 
final String q = q_example; // String | 
final int page = 56; // int | 
final int pageSize = 56; // int | 

try {
    final response = api.adminListTickets(status, category, assignee, q, page, pageSize);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminSupportApi->adminListTickets: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | [**TicketStatus**](.md)|  | [optional] 
 **category** | [**TicketCategory**](.md)|  | [optional] 
 **assignee** | **String**|  | [optional] 
 **q** | **String**|  | [optional] 
 **page** | **int**|  | [optional] [default to 1]
 **pageSize** | **int**|  | [optional] [default to 25]

### Return type

[**AdminListTickets200Response**](AdminListTickets200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminReplyTicket**
> TicketDetail adminReplyTicket(id, adminReplyTicketRequest)

Réponse (email + notification in-app) ou note interne

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminSupportApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final AdminReplyTicketRequest adminReplyTicketRequest = ; // AdminReplyTicketRequest | 

try {
    final response = api.adminReplyTicket(id, adminReplyTicketRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminSupportApi->adminReplyTicket: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **adminReplyTicketRequest** | [**AdminReplyTicketRequest**](AdminReplyTicketRequest.md)|  | 

### Return type

[**TicketDetail**](TicketDetail.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminUpdateTicket**
> TicketDetail adminUpdateTicket(id, adminUpdateTicketRequest)

Met à jour une demande (assignation, statut)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminSupportApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final AdminUpdateTicketRequest adminUpdateTicketRequest = ; // AdminUpdateTicketRequest | 

try {
    final response = api.adminUpdateTicket(id, adminUpdateTicketRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminSupportApi->adminUpdateTicket: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **adminUpdateTicketRequest** | [**AdminUpdateTicketRequest**](AdminUpdateTicketRequest.md)|  | 

### Return type

[**TicketDetail**](TicketDetail.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

