# omeo_api.api.NotificationsApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getNotificationPreferences**](NotificationsApi.md#getnotificationpreferences) | **GET** /me/notification-preferences | Préférences de notification
[**listNotifications**](NotificationsApi.md#listnotifications) | **GET** /me/notifications | Mes notifications
[**markNotificationsRead**](NotificationsApi.md#marknotificationsread) | **POST** /me/notifications/read | Marque comme lues (liste d&#39;ids, ou toutes)
[**registerPushDevice**](NotificationsApi.md#registerpushdevice) | **POST** /me/devices | Enregistre ou met à jour le jeton push de l&#39;appareil
[**trackNotificationOpened**](NotificationsApi.md#tracknotificationopened) | **POST** /me/notifications/{id}/opened | Ouverture d&#39;une push (statistiques de campagne)
[**unregisterPushDevice**](NotificationsApi.md#unregisterpushdevice) | **DELETE** /me/devices/{token} | Désenregistre un appareil des notifications push
[**updateNotificationPreferences**](NotificationsApi.md#updatenotificationpreferences) | **PUT** /me/notification-preferences | Modifie les préférences de notification


# **getNotificationPreferences**
> NotificationPreferences getNotificationPreferences()

Préférences de notification

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getNotificationsApi();

try {
    final response = api.getNotificationPreferences();
    print(response);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->getNotificationPreferences: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**NotificationPreferences**](NotificationPreferences.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listNotifications**
> ListNotifications200Response listNotifications(unread, cursor, limit)

Mes notifications

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getNotificationsApi();
final bool unread = true; // bool | 
final String cursor = cursor_example; // String | 
final int limit = 56; // int | 

try {
    final response = api.listNotifications(unread, cursor, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->listNotifications: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **unread** | **bool**|  | [optional] 
 **cursor** | **String**|  | [optional] 
 **limit** | **int**|  | [optional] [default to 20]

### Return type

[**ListNotifications200Response**](ListNotifications200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markNotificationsRead**
> MarkNotificationsRead200Response markNotificationsRead(markNotificationsReadRequest)

Marque comme lues (liste d'ids, ou toutes)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getNotificationsApi();
final MarkNotificationsReadRequest markNotificationsReadRequest = ; // MarkNotificationsReadRequest | 

try {
    final response = api.markNotificationsRead(markNotificationsReadRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->markNotificationsRead: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **markNotificationsReadRequest** | [**MarkNotificationsReadRequest**](MarkNotificationsReadRequest.md)|  | 

### Return type

[**MarkNotificationsRead200Response**](MarkNotificationsRead200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **registerPushDevice**
> registerPushDevice(registerPushDeviceRequest)

Enregistre ou met à jour le jeton push de l'appareil

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getNotificationsApi();
final RegisterPushDeviceRequest registerPushDeviceRequest = ; // RegisterPushDeviceRequest | 

try {
    api.registerPushDevice(registerPushDeviceRequest);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->registerPushDevice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **registerPushDeviceRequest** | [**RegisterPushDeviceRequest**](RegisterPushDeviceRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **trackNotificationOpened**
> trackNotificationOpened(id)

Ouverture d'une push (statistiques de campagne)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getNotificationsApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.trackNotificationOpened(id);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->trackNotificationOpened: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **unregisterPushDevice**
> unregisterPushDevice(token)

Désenregistre un appareil des notifications push

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getNotificationsApi();
final String token = token_example; // String | 

try {
    api.unregisterPushDevice(token);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->unregisterPushDevice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **token** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateNotificationPreferences**
> NotificationPreferences updateNotificationPreferences(notificationPreferences)

Modifie les préférences de notification

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getNotificationsApi();
final NotificationPreferences notificationPreferences = ; // NotificationPreferences | 

try {
    final response = api.updateNotificationPreferences(notificationPreferences);
    print(response);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->updateNotificationPreferences: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notificationPreferences** | [**NotificationPreferences**](NotificationPreferences.md)|  | 

### Return type

[**NotificationPreferences**](NotificationPreferences.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

