# omeo_api.api.ContentApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**favoritePlant**](ContentApi.md#favoriteplant) | **PUT** /plants/{id}/favorite | Ajoute une plante aux favoris
[**favoriteRecipe**](ContentApi.md#favoriterecipe) | **PUT** /recipes/{id}/favorite | Ajoute une recette aux favoris
[**getLegalDocument**](ContentApi.md#getlegaldocument) | **GET** /legal/{kind} | Dernière version publiée (Markdown)
[**getPlant**](ContentApi.md#getplant) | **GET** /plants/{id} | Détail d&#39;une plante
[**getPrevention**](ContentApi.md#getprevention) | **GET** /me/prevention | Conseils déclenchés, état « pas assez de données », bilan hebdo (Plus)
[**getRecipe**](ContentApi.md#getrecipe) | **GET** /recipes/{id} | Détail d&#39;une recette
[**listFaq**](ContentApi.md#listfaq) | **GET** /faq | Questions fréquentes
[**listPlants**](ContentApi.md#listplants) | **GET** /plants | Plantes
[**listRecipes**](ContentApi.md#listrecipes) | **GET** /recipes | Recettes
[**unfavoritePlant**](ContentApi.md#unfavoriteplant) | **DELETE** /plants/{id}/favorite | Retire une plante des favoris
[**unfavoriteRecipe**](ContentApi.md#unfavoriterecipe) | **DELETE** /recipes/{id}/favorite | Retire une recette des favoris
[**updateUserTip**](ContentApi.md#updateusertip) | **PATCH** /me/prevention/tips/{id} | Met à jour un conseil de prévention (lu, masqué)


# **favoritePlant**
> favoritePlant(id)

Ajoute une plante aux favoris

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getContentApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.favoritePlant(id);
} on DioException catch (e) {
    print('Exception when calling ContentApi->favoritePlant: $e\n');
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

# **favoriteRecipe**
> favoriteRecipe(id)

Ajoute une recette aux favoris

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getContentApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.favoriteRecipe(id);
} on DioException catch (e) {
    print('Exception when calling ContentApi->favoriteRecipe: $e\n');
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

# **getLegalDocument**
> LegalDocument getLegalDocument(kind)

Dernière version publiée (Markdown)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getContentApi();
final LegalKind kind = ; // LegalKind | 

try {
    final response = api.getLegalDocument(kind);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->getLegalDocument: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **kind** | [**LegalKind**](.md)|  | 

### Return type

[**LegalDocument**](LegalDocument.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPlant**
> PlantDetail getPlant(id)

Détail d'une plante

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getContentApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getPlant(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->getPlant: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**PlantDetail**](PlantDetail.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPrevention**
> PreventionOverview getPrevention()

Conseils déclenchés, état « pas assez de données », bilan hebdo (Plus)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getContentApi();

try {
    final response = api.getPrevention();
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->getPrevention: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PreventionOverview**](PreventionOverview.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getRecipe**
> RecipeDetail getRecipe(id)

Détail d'une recette

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getContentApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getRecipe(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->getRecipe: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**RecipeDetail**](RecipeDetail.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listFaq**
> List<ListFaq200ResponseInner> listFaq(audience)

Questions fréquentes

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getContentApi();
final String audience = audience_example; // String | 

try {
    final response = api.listFaq(audience);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->listFaq: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **audience** | **String**|  | [optional] 

### Return type

[**List&lt;ListFaq200ResponseInner&gt;**](ListFaq200ResponseInner.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listPlants**
> ListPlants200Response listPlants(q, tag, favorites, cursor, limit)

Plantes

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getContentApi();
final String q = q_example; // String | 
final String tag = tag_example; // String | 
final bool favorites = true; // bool | 
final String cursor = cursor_example; // String | 
final int limit = 56; // int | 

try {
    final response = api.listPlants(q, tag, favorites, cursor, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->listPlants: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional] 
 **tag** | **String**|  | [optional] 
 **favorites** | **bool**|  | [optional] 
 **cursor** | **String**|  | [optional] 
 **limit** | **int**|  | [optional] [default to 20]

### Return type

[**ListPlants200Response**](ListPlants200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listRecipes**
> ListRecipes200Response listRecipes(q, country, goal, tag, maxMinutes, favorites, cursor, limit)

Recettes

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getContentApi();
final String q = q_example; // String | 
final String country = country_example; // String | 
final Goal goal = ; // Goal | 
final List<String> tag = ; // List<String> | 
final int maxMinutes = 56; // int | 
final bool favorites = true; // bool | 
final String cursor = cursor_example; // String | 
final int limit = 56; // int | 

try {
    final response = api.listRecipes(q, country, goal, tag, maxMinutes, favorites, cursor, limit);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->listRecipes: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional] 
 **country** | **String**|  | [optional] 
 **goal** | [**Goal**](.md)|  | [optional] 
 **tag** | [**List&lt;String&gt;**](String.md)|  | [optional] 
 **maxMinutes** | **int**|  | [optional] 
 **favorites** | **bool**|  | [optional] 
 **cursor** | **String**|  | [optional] 
 **limit** | **int**|  | [optional] [default to 20]

### Return type

[**ListRecipes200Response**](ListRecipes200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **unfavoritePlant**
> unfavoritePlant(id)

Retire une plante des favoris

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getContentApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.unfavoritePlant(id);
} on DioException catch (e) {
    print('Exception when calling ContentApi->unfavoritePlant: $e\n');
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

# **unfavoriteRecipe**
> unfavoriteRecipe(id)

Retire une recette des favoris

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getContentApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.unfavoriteRecipe(id);
} on DioException catch (e) {
    print('Exception when calling ContentApi->unfavoriteRecipe: $e\n');
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

# **updateUserTip**
> updateUserTip(id, updateUserTipRequest)

Met à jour un conseil de prévention (lu, masqué)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getContentApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final UpdateUserTipRequest updateUserTipRequest = ; // UpdateUserTipRequest | 

try {
    api.updateUserTip(id, updateUserTipRequest);
} on DioException catch (e) {
    print('Exception when calling ContentApi->updateUserTip: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **updateUserTipRequest** | [**UpdateUserTipRequest**](UpdateUserTipRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

