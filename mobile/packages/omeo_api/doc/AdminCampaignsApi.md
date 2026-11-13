# omeo_api.api.AdminCampaignsApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminCampaignAction**](AdminCampaignsApi.md#admincampaignaction) | **POST** /admin/campaigns/{id}/{action} | Action sur une campagne (programmer, envoyer, annuler…)
[**adminCreateCampaign**](AdminCampaignsApi.md#admincreatecampaign) | **POST** /admin/campaigns | Crée une campagne
[**adminEstimateAudience**](AdminCampaignsApi.md#adminestimateaudience) | **POST** /admin/campaigns/audience | Nombre de destinataires d&#39;un segment (consentement marketing inclus)
[**adminGetCampaign**](AdminCampaignsApi.md#admingetcampaign) | **GET** /admin/campaigns/{id} | Détail d&#39;une campagne
[**adminListCampaigns**](AdminCampaignsApi.md#adminlistcampaigns) | **GET** /admin/campaigns | Campagnes
[**adminUpdateCampaign**](AdminCampaignsApi.md#adminupdatecampaign) | **PATCH** /admin/campaigns/{id} | Modifie une campagne


# **adminCampaignAction**
> Campaign adminCampaignAction(id, action)

Action sur une campagne (programmer, envoyer, annuler…)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminCampaignsApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String action = action_example; // String | 

try {
    final response = api.adminCampaignAction(id, action);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminCampaignsApi->adminCampaignAction: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **action** | **String**|  | 

### Return type

[**Campaign**](Campaign.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminCreateCampaign**
> Campaign adminCreateCampaign(campaignInput)

Crée une campagne

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminCampaignsApi();
final CampaignInput campaignInput = ; // CampaignInput | 

try {
    final response = api.adminCreateCampaign(campaignInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminCampaignsApi->adminCreateCampaign: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **campaignInput** | [**CampaignInput**](CampaignInput.md)|  | 

### Return type

[**Campaign**](Campaign.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminEstimateAudience**
> AdminEstimateAudience200Response adminEstimateAudience(segment)

Nombre de destinataires d'un segment (consentement marketing inclus)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminCampaignsApi();
final Segment segment = ; // Segment | 

try {
    final response = api.adminEstimateAudience(segment);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminCampaignsApi->adminEstimateAudience: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **segment** | [**Segment**](Segment.md)|  | 

### Return type

[**AdminEstimateAudience200Response**](AdminEstimateAudience200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminGetCampaign**
> Campaign adminGetCampaign(id)

Détail d'une campagne

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminCampaignsApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.adminGetCampaign(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminCampaignsApi->adminGetCampaign: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**Campaign**](Campaign.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminListCampaigns**
> AdminListCampaigns200Response adminListCampaigns(page, pageSize)

Campagnes

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminCampaignsApi();
final int page = 56; // int | 
final int pageSize = 56; // int | 

try {
    final response = api.adminListCampaigns(page, pageSize);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminCampaignsApi->adminListCampaigns: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **int**|  | [optional] [default to 1]
 **pageSize** | **int**|  | [optional] [default to 25]

### Return type

[**AdminListCampaigns200Response**](AdminListCampaigns200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminUpdateCampaign**
> Campaign adminUpdateCampaign(id, campaignInput)

Modifie une campagne

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminCampaignsApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final CampaignInput campaignInput = ; // CampaignInput | 

try {
    final response = api.adminUpdateCampaign(id, campaignInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminCampaignsApi->adminUpdateCampaign: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **campaignInput** | [**CampaignInput**](CampaignInput.md)|  | 

### Return type

[**Campaign**](Campaign.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

