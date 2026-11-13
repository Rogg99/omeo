# omeo_api.api.WebhooksApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**appStoreNotification**](WebhooksApi.md#appstorenotification) | **POST** /webhooks/app-store | App Store Server Notifications v2 (JWS vérifié)
[**googlePlayRtdn**](WebhooksApi.md#googleplayrtdn) | **POST** /webhooks/google-play | Real-Time Developer Notifications (Pub/Sub push, jeton OIDC vérifié)
[**paymentProviderWebhook**](WebhooksApi.md#paymentproviderwebhook) | **POST** /webhooks/payments | Événements de l&#39;agrégateur de paiement web (signature HMAC vérifiée)


# **appStoreNotification**
> appStoreNotification(appStoreNotificationRequest)

App Store Server Notifications v2 (JWS vérifié)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getWebhooksApi();
final AppStoreNotificationRequest appStoreNotificationRequest = ; // AppStoreNotificationRequest | 

try {
    api.appStoreNotification(appStoreNotificationRequest);
} on DioException catch (e) {
    print('Exception when calling WebhooksApi->appStoreNotification: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **appStoreNotificationRequest** | [**AppStoreNotificationRequest**](AppStoreNotificationRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **googlePlayRtdn**
> googlePlayRtdn(body)

Real-Time Developer Notifications (Pub/Sub push, jeton OIDC vérifié)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getWebhooksApi();
final Object body = Object; // Object | 

try {
    api.googlePlayRtdn(body);
} on DioException catch (e) {
    print('Exception when calling WebhooksApi->googlePlayRtdn: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **body** | **Object**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **paymentProviderWebhook**
> paymentProviderWebhook(body)

Événements de l'agrégateur de paiement web (signature HMAC vérifiée)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getWebhooksApi();
final Object body = Object; // Object | 

try {
    api.paymentProviderWebhook(body);
} on DioException catch (e) {
    print('Exception when calling WebhooksApi->paymentProviderWebhook: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **body** | **Object**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

