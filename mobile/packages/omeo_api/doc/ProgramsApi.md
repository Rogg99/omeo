# omeo_api.api.ProgramsApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**checkProgramTask**](ProgramsApi.md#checkprogramtask) | **PUT** /me/program/tasks/{id} | Coche ou décoche une tâche manuelle du jour
[**enrollProgram**](ProgramsApi.md#enrollprogram) | **POST** /programs/{id}/enroll | Commence un programme (Plus). &#x60;replace&#x3D;true&#x60; requis si un autre est actif
[**getActiveProgram**](ProgramsApi.md#getactiveprogram) | **GET** /me/program | Programme actif — jour courant, semaine, avancement
[**getProgram**](ProgramsApi.md#getprogram) | **GET** /programs/{id} | Détail d&#39;un programme
[**listPrograms**](ProgramsApi.md#listprograms) | **GET** /programs | Programmes
[**quitProgram**](ProgramsApi.md#quitprogram) | **DELETE** /me/program | Quitte le programme en cours


# **checkProgramTask**
> CheckProgramTask200Response checkProgramTask(id, checkProgramTaskRequest)

Coche ou décoche une tâche manuelle du jour

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getProgramsApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final CheckProgramTaskRequest checkProgramTaskRequest = ; // CheckProgramTaskRequest | 

try {
    final response = api.checkProgramTask(id, checkProgramTaskRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ProgramsApi->checkProgramTask: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **checkProgramTaskRequest** | [**CheckProgramTaskRequest**](CheckProgramTaskRequest.md)|  | 

### Return type

[**CheckProgramTask200Response**](CheckProgramTask200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **enrollProgram**
> Enrollment enrollProgram(id, enrollProgramRequest)

Commence un programme (Plus). `replace=true` requis si un autre est actif

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getProgramsApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final EnrollProgramRequest enrollProgramRequest = ; // EnrollProgramRequest | 

try {
    final response = api.enrollProgram(id, enrollProgramRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ProgramsApi->enrollProgram: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **enrollProgramRequest** | [**EnrollProgramRequest**](EnrollProgramRequest.md)|  | [optional] 

### Return type

[**Enrollment**](Enrollment.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getActiveProgram**
> Enrollment getActiveProgram(date)

Programme actif — jour courant, semaine, avancement

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getProgramsApi();
final DateTime date = 2013-10-20; // DateTime | Journée locale. Défaut : aujourd'hui

try {
    final response = api.getActiveProgram(date);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ProgramsApi->getActiveProgram: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **date** | **DateTime**| Journée locale. Défaut : aujourd'hui | [optional] 

### Return type

[**Enrollment**](Enrollment.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getProgram**
> ProgramDetail getProgram(id)

Détail d'un programme

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getProgramsApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getProgram(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ProgramsApi->getProgram: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ProgramDetail**](ProgramDetail.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listPrograms**
> List<ProgramSummary> listPrograms(goal)

Programmes

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getProgramsApi();
final Goal goal = ; // Goal | 

try {
    final response = api.listPrograms(goal);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ProgramsApi->listPrograms: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **goal** | [**Goal**](.md)|  | [optional] 

### Return type

[**List&lt;ProgramSummary&gt;**](ProgramSummary.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **quitProgram**
> quitProgram()

Quitte le programme en cours

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getProgramsApi();

try {
    api.quitProgram();
} on DioException catch (e) {
    print('Exception when calling ProgramsApi->quitProgram: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

