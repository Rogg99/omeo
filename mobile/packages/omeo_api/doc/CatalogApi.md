# omeo_api.api.CatalogApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**favoriteDish**](CatalogApi.md#favoritedish) | **PUT** /dishes/{id}/favorite | Ajoute un plat aux favoris
[**getDish**](CatalogApi.md#getdish) | **GET** /dishes/{id} | Détail d&#39;un plat
[**searchDishes**](CatalogApi.md#searchdishes) | **GET** /dishes | Recherche dans le catalogue de plats
[**searchFoods**](CatalogApi.md#searchfoods) | **GET** /foods | Recherche d&#39;aliments (ajout d&#39;ingrédient), noms locaux inclus
[**unfavoriteDish**](CatalogApi.md#unfavoritedish) | **DELETE** /dishes/{id}/favorite | Retire un plat des favoris


# **favoriteDish**
> favoriteDish(id)

Ajoute un plat aux favoris

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getCatalogApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.favoriteDish(id);
} on DioException catch (e) {
    print('Exception when calling CatalogApi->favoriteDish: $e\n');
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

# **getDish**
> DishDetail getDish(id)

Détail d'un plat

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getCatalogApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getDish(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CatalogApi->getDish: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**DishDetail**](DishDetail.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchDishes**
> SearchDishes200Response searchDishes(q, country, scope, cursor, limit)

Recherche dans le catalogue de plats

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getCatalogApi();
final String q = q_example; // String | 
final String country = country_example; // String | 
final String scope = scope_example; // String | 
final String cursor = cursor_example; // String | 
final int limit = 56; // int | 

try {
    final response = api.searchDishes(q, country, scope, cursor, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CatalogApi->searchDishes: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional] 
 **country** | **String**|  | [optional] 
 **scope** | **String**|  | [optional] [default to 'all']
 **cursor** | **String**|  | [optional] 
 **limit** | **int**|  | [optional] [default to 20]

### Return type

[**SearchDishes200Response**](SearchDishes200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchFoods**
> SearchFoods200Response searchFoods(q, limit)

Recherche d'aliments (ajout d'ingrédient), noms locaux inclus

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getCatalogApi();
final String q = q_example; // String | 
final int limit = 56; // int | 

try {
    final response = api.searchFoods(q, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CatalogApi->searchFoods: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | 
 **limit** | **int**|  | [optional] [default to 20]

### Return type

[**SearchFoods200Response**](SearchFoods200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **unfavoriteDish**
> unfavoriteDish(id)

Retire un plat des favoris

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getCatalogApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.unfavoriteDish(id);
} on DioException catch (e) {
    print('Exception when calling CatalogApi->unfavoriteDish: $e\n');
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

