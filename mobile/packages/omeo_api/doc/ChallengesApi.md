# omeo_api.api.ChallengesApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**checkChallengeDay**](ChallengesApi.md#checkchallengeday) | **PUT** /me/challenges/{id}/days/{date} | Coche un jour (challenges à validation manuelle uniquement, jour courant ou veille)
[**getChallenge**](ChallengesApi.md#getchallenge) | **GET** /challenges/{id} | Détail d&#39;un challenge
[**getMyChallenge**](ChallengesApi.md#getmychallenge) | **GET** /me/challenges/{id} | Calendrier réussi/raté, série, taux de réussite
[**joinChallenge**](ChallengesApi.md#joinchallenge) | **POST** /challenges/{id}/join | Rejoint un challenge (Free : 1 actif — 429 &#x60;quota_exceeded&#x60;)
[**leaveChallenge**](ChallengesApi.md#leavechallenge) | **DELETE** /me/challenges/{id} | Quitte un challenge
[**listChallenges**](ChallengesApi.md#listchallenges) | **GET** /challenges | Challenges
[**listMyChallenges**](ChallengesApi.md#listmychallenges) | **GET** /me/challenges | Mes challenges


# **checkChallengeDay**
> CheckChallengeDay200Response checkChallengeDay(id, date, checkChallengeDayRequest)

Coche un jour (challenges à validation manuelle uniquement, jour courant ou veille)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getChallengesApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final DateTime date = 2013-10-20; // DateTime | 
final CheckChallengeDayRequest checkChallengeDayRequest = ; // CheckChallengeDayRequest | 

try {
    final response = api.checkChallengeDay(id, date, checkChallengeDayRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ChallengesApi->checkChallengeDay: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **date** | **DateTime**|  | 
 **checkChallengeDayRequest** | [**CheckChallengeDayRequest**](CheckChallengeDayRequest.md)|  | 

### Return type

[**CheckChallengeDay200Response**](CheckChallengeDay200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getChallenge**
> ChallengeSummary getChallenge(id)

Détail d'un challenge

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getChallengesApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getChallenge(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ChallengesApi->getChallenge: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ChallengeSummary**](ChallengeSummary.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyChallenge**
> Participation getMyChallenge(id)

Calendrier réussi/raté, série, taux de réussite

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getChallengesApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getMyChallenge(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ChallengesApi->getMyChallenge: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**Participation**](Participation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **joinChallenge**
> Participation joinChallenge(id)

Rejoint un challenge (Free : 1 actif — 429 `quota_exceeded`)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getChallengesApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.joinChallenge(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ChallengesApi->joinChallenge: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**Participation**](Participation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **leaveChallenge**
> leaveChallenge(id)

Quitte un challenge

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getChallengesApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.leaveChallenge(id);
} on DioException catch (e) {
    print('Exception when calling ChallengesApi->leaveChallenge: $e\n');
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

# **listChallenges**
> List<ChallengeSummary> listChallenges()

Challenges

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getChallengesApi();

try {
    final response = api.listChallenges();
    print(response);
} on DioException catch (e) {
    print('Exception when calling ChallengesApi->listChallenges: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List&lt;ChallengeSummary&gt;**](ChallengeSummary.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMyChallenges**
> List<Participation> listMyChallenges(status)

Mes challenges

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getChallengesApi();
final String status = status_example; // String | 

try {
    final response = api.listMyChallenges(status);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ChallengesApi->listMyChallenges: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | [optional] 

### Return type

[**List&lt;Participation&gt;**](Participation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

