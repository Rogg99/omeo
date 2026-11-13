# omeo_api.api.SupportApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createTicket**](SupportApi.md#createticket) | **POST** /support/tickets | Demande de support (app connectée, ou formulaire de contact web avec captcha)
[**getMyTicket**](SupportApi.md#getmyticket) | **GET** /me/tickets/{id} | Fil de la demande (sans les notes internes)
[**listMyTickets**](SupportApi.md#listmytickets) | **GET** /me/tickets | Mes demandes au support


# **createTicket**
> CreateTicket201Response createTicket(idempotencyKey, ticketInput)

Demande de support (app connectée, ou formulaire de contact web avec captcha)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getSupportApi();
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h).
final TicketInput ticketInput = ; // TicketInput | 

try {
    final response = api.createTicket(idempotencyKey, ticketInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling SupportApi->createTicket: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**| UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h). | 
 **ticketInput** | [**TicketInput**](TicketInput.md)|  | 

### Return type

[**CreateTicket201Response**](CreateTicket201Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyTicket**
> TicketDetail getMyTicket(id)

Fil de la demande (sans les notes internes)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getSupportApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getMyTicket(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling SupportApi->getMyTicket: $e\n');
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

# **listMyTickets**
> List<TicketSummary> listMyTickets()

Mes demandes au support

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getSupportApi();

try {
    final response = api.listMyTickets();
    print(response);
} on DioException catch (e) {
    print('Exception when calling SupportApi->listMyTickets: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List&lt;TicketSummary&gt;**](TicketSummary.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

