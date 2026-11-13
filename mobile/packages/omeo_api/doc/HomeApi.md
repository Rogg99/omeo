# omeo_api.api.HomeApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getCalendar**](HomeApi.md#getcalendar) | **GET** /me/calendar | État de chaque jour d&#39;un mois (pour le calendrier du journal)
[**getDay**](HomeApi.md#getday) | **GET** /me/days/{date} | Journal d&#39;un jour (objectif, résumé, 4 repas, hydratation, message)
[**getHome**](HomeApi.md#gethome) | **GET** /me/home | Écran d&#39;accueil complet en un seul appel


# **getCalendar**
> List<GetCalendar200ResponseInner> getCalendar(month)

État de chaque jour d'un mois (pour le calendrier du journal)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getHomeApi();
final String month = month_example; // String | 

try {
    final response = api.getCalendar(month);
    print(response);
} on DioException catch (e) {
    print('Exception when calling HomeApi->getCalendar: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **month** | **String**|  | 

### Return type

[**List&lt;GetCalendar200ResponseInner&gt;**](GetCalendar200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDay**
> DayDetail getDay(date)

Journal d'un jour (objectif, résumé, 4 repas, hydratation, message)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getHomeApi();
final DateTime date = 2013-10-20; // DateTime | 

try {
    final response = api.getDay(date);
    print(response);
} on DioException catch (e) {
    print('Exception when calling HomeApi->getDay: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **date** | **DateTime**|  | 

### Return type

[**DayDetail**](DayDetail.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getHome**
> Home getHome(date)

Écran d'accueil complet en un seul appel

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getHomeApi();
final DateTime date = 2013-10-20; // DateTime | Journée locale. Défaut : aujourd'hui

try {
    final response = api.getHome(date);
    print(response);
} on DioException catch (e) {
    print('Exception when calling HomeApi->getHome: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **date** | **DateTime**| Journée locale. Défaut : aujourd'hui | [optional] 

### Return type

[**Home**](Home.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

