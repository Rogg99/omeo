# omeo_api.api.BillingApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**checkInviteCode**](BillingApi.md#checkinvitecode) | **POST** /referral/check | Vérifie un code d&#39;invitation avant l&#39;inscription
[**checkPromoCode**](BillingApi.md#checkpromocode) | **POST** /me/billing/promo-check | Vérifie un code promo
[**createBillingPortal**](BillingApi.md#createbillingportal) | **POST** /me/billing/portal | Lien vers le portail de l&#39;agrégateur (moyen de paiement, résiliation) — abonnement web
[**createWebCheckout**](BillingApi.md#createwebcheckout) | **POST** /me/billing/checkout | Session de paiement web (carte, Apple Pay, Google Pay via l&#39;agrégateur)
[**getReferral**](BillingApi.md#getreferral) | **GET** /me/referral | Code, lien de partage, filleuls validés, jours gagnés sur 35
[**getSubscription**](BillingApi.md#getsubscription) | **GET** /me/subscription | Droits effectifs, abonnement courant, canal, quotas, actions possibles
[**listPayments**](BillingApi.md#listpayments) | **GET** /me/payments | Mes paiements
[**listPlans**](BillingApi.md#listplans) | **GET** /billing/plans | Offres et prix (USD), avantages, quotas par offre — app, site, page Tarifs
[**restorePurchases**](BillingApi.md#restorepurchases) | **POST** /me/subscription/restore | Restaure les achats du store
[**verifyStorePurchase**](BillingApi.md#verifystorepurchase) | **POST** /me/subscription/verify | Vérifie un achat Google Play / App Store auprès du store et l&#39;attache au compte


# **checkInviteCode**
> CheckInviteCode200Response checkInviteCode(checkInviteCodeRequest)

Vérifie un code d'invitation avant l'inscription

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getBillingApi();
final CheckInviteCodeRequest checkInviteCodeRequest = ; // CheckInviteCodeRequest | 

try {
    final response = api.checkInviteCode(checkInviteCodeRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling BillingApi->checkInviteCode: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **checkInviteCodeRequest** | [**CheckInviteCodeRequest**](CheckInviteCodeRequest.md)|  | 

### Return type

[**CheckInviteCode200Response**](CheckInviteCode200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **checkPromoCode**
> CheckPromoCode200Response checkPromoCode(checkPromoCodeRequest)

Vérifie un code promo

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getBillingApi();
final CheckPromoCodeRequest checkPromoCodeRequest = ; // CheckPromoCodeRequest | 

try {
    final response = api.checkPromoCode(checkPromoCodeRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling BillingApi->checkPromoCode: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **checkPromoCodeRequest** | [**CheckPromoCodeRequest**](CheckPromoCodeRequest.md)|  | 

### Return type

[**CheckPromoCode200Response**](CheckPromoCode200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createBillingPortal**
> CreateBillingPortal201Response createBillingPortal(createBillingPortalRequest)

Lien vers le portail de l'agrégateur (moyen de paiement, résiliation) — abonnement web

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getBillingApi();
final CreateBillingPortalRequest createBillingPortalRequest = ; // CreateBillingPortalRequest | 

try {
    final response = api.createBillingPortal(createBillingPortalRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling BillingApi->createBillingPortal: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createBillingPortalRequest** | [**CreateBillingPortalRequest**](CreateBillingPortalRequest.md)|  | 

### Return type

[**CreateBillingPortal201Response**](CreateBillingPortal201Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createWebCheckout**
> CreateWebCheckout201Response createWebCheckout(idempotencyKey, createWebCheckoutRequest)

Session de paiement web (carte, Apple Pay, Google Pay via l'agrégateur)

Refusé (409) si un abonnement store est actif. Le site redirige vers `checkout_url`.

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getBillingApi();
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h).
final CreateWebCheckoutRequest createWebCheckoutRequest = ; // CreateWebCheckoutRequest | 

try {
    final response = api.createWebCheckout(idempotencyKey, createWebCheckoutRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling BillingApi->createWebCheckout: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**| UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h). | 
 **createWebCheckoutRequest** | [**CreateWebCheckoutRequest**](CreateWebCheckoutRequest.md)|  | 

### Return type

[**CreateWebCheckout201Response**](CreateWebCheckout201Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getReferral**
> ReferralOverview getReferral()

Code, lien de partage, filleuls validés, jours gagnés sur 35

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getBillingApi();

try {
    final response = api.getReferral();
    print(response);
} on DioException catch (e) {
    print('Exception when calling BillingApi->getReferral: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ReferralOverview**](ReferralOverview.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getSubscription**
> SubscriptionState getSubscription()

Droits effectifs, abonnement courant, canal, quotas, actions possibles

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getBillingApi();

try {
    final response = api.getSubscription();
    print(response);
} on DioException catch (e) {
    print('Exception when calling BillingApi->getSubscription: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**SubscriptionState**](SubscriptionState.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listPayments**
> ListPayments200Response listPayments(cursor)

Mes paiements

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getBillingApi();
final String cursor = cursor_example; // String | 

try {
    final response = api.listPayments(cursor);
    print(response);
} on DioException catch (e) {
    print('Exception when calling BillingApi->listPayments: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **cursor** | **String**|  | [optional] 

### Return type

[**ListPayments200Response**](ListPayments200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listPlans**
> PlanCatalog listPlans()

Offres et prix (USD), avantages, quotas par offre — app, site, page Tarifs

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getBillingApi();

try {
    final response = api.listPlans();
    print(response);
} on DioException catch (e) {
    print('Exception when calling BillingApi->listPlans: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PlanCatalog**](PlanCatalog.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **restorePurchases**
> SubscriptionState restorePurchases(restorePurchasesRequest)

Restaure les achats du store

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getBillingApi();
final RestorePurchasesRequest restorePurchasesRequest = ; // RestorePurchasesRequest | 

try {
    final response = api.restorePurchases(restorePurchasesRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling BillingApi->restorePurchases: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **restorePurchasesRequest** | [**RestorePurchasesRequest**](RestorePurchasesRequest.md)|  | 

### Return type

[**SubscriptionState**](SubscriptionState.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **verifyStorePurchase**
> SubscriptionState verifyStorePurchase(idempotencyKey, verifyStorePurchaseRequest)

Vérifie un achat Google Play / App Store auprès du store et l'attache au compte

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getBillingApi();
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h).
final VerifyStorePurchaseRequest verifyStorePurchaseRequest = ; // VerifyStorePurchaseRequest | 

try {
    final response = api.verifyStorePurchase(idempotencyKey, verifyStorePurchaseRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling BillingApi->verifyStorePurchase: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**| UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h). | 
 **verifyStorePurchaseRequest** | [**VerifyStorePurchaseRequest**](VerifyStorePurchaseRequest.md)|  | 

### Return type

[**SubscriptionState**](SubscriptionState.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

