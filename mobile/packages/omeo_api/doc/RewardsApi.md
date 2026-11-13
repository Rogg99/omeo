# omeo_api.api.RewardsApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getRewards**](RewardsApi.md#getrewards) | **GET** /me/rewards | Écran « Mes récompenses »
[**listBadges**](RewardsApi.md#listbadges) | **GET** /me/badges | Mes badges
[**listPointEvents**](RewardsApi.md#listpointevents) | **GET** /me/points | Historique des points


# **getRewards**
> RewardsOverview getRewards()

Écran « Mes récompenses »

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getRewardsApi();

try {
    final response = api.getRewards();
    print(response);
} on DioException catch (e) {
    print('Exception when calling RewardsApi->getRewards: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**RewardsOverview**](RewardsOverview.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listBadges**
> List<UserBadge> listBadges()

Mes badges

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getRewardsApi();

try {
    final response = api.listBadges();
    print(response);
} on DioException catch (e) {
    print('Exception when calling RewardsApi->listBadges: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List&lt;UserBadge&gt;**](UserBadge.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listPointEvents**
> ListPointEvents200Response listPointEvents(cursor, limit)

Historique des points

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getRewardsApi();
final String cursor = cursor_example; // String | 
final int limit = 56; // int | 

try {
    final response = api.listPointEvents(cursor, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling RewardsApi->listPointEvents: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **cursor** | **String**|  | [optional] 
 **limit** | **int**|  | [optional] [default to 20]

### Return type

[**ListPointEvents200Response**](ListPointEvents200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

