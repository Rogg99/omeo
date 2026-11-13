# omeo_api.api.AdminBillingApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminCreatePromoCode**](AdminBillingApi.md#admincreatepromocode) | **POST** /admin/promo-codes | Crée un code promo
[**adminListPayments**](AdminBillingApi.md#adminlistpayments) | **GET** /admin/payments | Paiements
[**adminListPlans**](AdminBillingApi.md#adminlistplans) | **GET** /admin/plans | Offres
[**adminListPromoCodes**](AdminBillingApi.md#adminlistpromocodes) | **GET** /admin/promo-codes | Codes promo
[**adminListQuotaRules**](AdminBillingApi.md#adminlistquotarules) | **GET** /admin/quotas | Règles de quotas
[**adminListSubscriptions**](AdminBillingApi.md#adminlistsubscriptions) | **GET** /admin/subscriptions | Abonnements
[**adminRefundPayment**](AdminBillingApi.md#adminrefundpayment) | **POST** /admin/payments/{id}/refund | Rembourse un paiement web (les stores remboursent eux-mêmes)
[**adminReplaceQuotaRules**](AdminBillingApi.md#adminreplacequotarules) | **PUT** /admin/quotas | Remplace les règles de quotas
[**adminUpdatePlan**](AdminBillingApi.md#adminupdateplan) | **PATCH** /admin/plans/{code} | Modifie une offre
[**adminUpdatePromoCode**](AdminBillingApi.md#adminupdatepromocode) | **PATCH** /admin/promo-codes/{id} | Modifie un code promo


# **adminCreatePromoCode**
> PromoCode adminCreatePromoCode(promoCode)

Crée un code promo

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminBillingApi();
final PromoCode promoCode = ; // PromoCode | 

try {
    final response = api.adminCreatePromoCode(promoCode);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminBillingApi->adminCreatePromoCode: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **promoCode** | [**PromoCode**](PromoCode.md)|  | 

### Return type

[**PromoCode**](PromoCode.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminListPayments**
> AdminListPayments200Response adminListPayments(status, channel, from, to, page, pageSize)

Paiements

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminBillingApi();
final String status = status_example; // String | 
final Channel channel = ; // Channel | 
final DateTime from = 2013-10-20; // DateTime | 
final DateTime to = 2013-10-20; // DateTime | 
final int page = 56; // int | 
final int pageSize = 56; // int | 

try {
    final response = api.adminListPayments(status, channel, from, to, page, pageSize);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminBillingApi->adminListPayments: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | [optional] 
 **channel** | [**Channel**](.md)|  | [optional] 
 **from** | **DateTime**|  | [optional] 
 **to** | **DateTime**|  | [optional] 
 **page** | **int**|  | [optional] [default to 1]
 **pageSize** | **int**|  | [optional] [default to 25]

### Return type

[**AdminListPayments200Response**](AdminListPayments200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminListPlans**
> List<AdminPlan> adminListPlans()

Offres

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminBillingApi();

try {
    final response = api.adminListPlans();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminBillingApi->adminListPlans: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List&lt;AdminPlan&gt;**](AdminPlan.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminListPromoCodes**
> AdminListPromoCodes200Response adminListPromoCodes(page, pageSize)

Codes promo

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminBillingApi();
final int page = 56; // int | 
final int pageSize = 56; // int | 

try {
    final response = api.adminListPromoCodes(page, pageSize);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminBillingApi->adminListPromoCodes: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **int**|  | [optional] [default to 1]
 **pageSize** | **int**|  | [optional] [default to 25]

### Return type

[**AdminListPromoCodes200Response**](AdminListPromoCodes200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminListQuotaRules**
> List<QuotaRule> adminListQuotaRules()

Règles de quotas

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminBillingApi();

try {
    final response = api.adminListQuotaRules();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminBillingApi->adminListQuotaRules: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List&lt;QuotaRule&gt;**](QuotaRule.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminListSubscriptions**
> AdminListSubscriptions200Response adminListSubscriptions(status, channel, q, page, pageSize)

Abonnements

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminBillingApi();
final SubscriptionStatus status = ; // SubscriptionStatus | 
final Channel channel = ; // Channel | 
final String q = q_example; // String | 
final int page = 56; // int | 
final int pageSize = 56; // int | 

try {
    final response = api.adminListSubscriptions(status, channel, q, page, pageSize);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminBillingApi->adminListSubscriptions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | [**SubscriptionStatus**](.md)|  | [optional] 
 **channel** | [**Channel**](.md)|  | [optional] 
 **q** | **String**|  | [optional] 
 **page** | **int**|  | [optional] [default to 1]
 **pageSize** | **int**|  | [optional] [default to 25]

### Return type

[**AdminListSubscriptions200Response**](AdminListSubscriptions200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminRefundPayment**
> AdminPaymentRow adminRefundPayment(id, adminRefundPaymentRequest)

Rembourse un paiement web (les stores remboursent eux-mêmes)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminBillingApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final AdminRefundPaymentRequest adminRefundPaymentRequest = ; // AdminRefundPaymentRequest | 

try {
    final response = api.adminRefundPayment(id, adminRefundPaymentRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminBillingApi->adminRefundPayment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **adminRefundPaymentRequest** | [**AdminRefundPaymentRequest**](AdminRefundPaymentRequest.md)|  | 

### Return type

[**AdminPaymentRow**](AdminPaymentRow.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminReplaceQuotaRules**
> List<QuotaRule> adminReplaceQuotaRules(quotaRule)

Remplace les règles de quotas

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminBillingApi();
final List<QuotaRule> quotaRule = ; // List<QuotaRule> | 

try {
    final response = api.adminReplaceQuotaRules(quotaRule);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminBillingApi->adminReplaceQuotaRules: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **quotaRule** | [**List&lt;QuotaRule&gt;**](QuotaRule.md)|  | 

### Return type

[**List&lt;QuotaRule&gt;**](QuotaRule.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminUpdatePlan**
> AdminPlan adminUpdatePlan(code, adminPlan)

Modifie une offre

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminBillingApi();
final String code = code_example; // String | 
final AdminPlan adminPlan = ; // AdminPlan | 

try {
    final response = api.adminUpdatePlan(code, adminPlan);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminBillingApi->adminUpdatePlan: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **code** | **String**|  | 
 **adminPlan** | [**AdminPlan**](AdminPlan.md)|  | 

### Return type

[**AdminPlan**](AdminPlan.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminUpdatePromoCode**
> PromoCode adminUpdatePromoCode(id, promoCode)

Modifie un code promo

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAdminBillingApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final PromoCode promoCode = ; // PromoCode | 

try {
    final response = api.adminUpdatePromoCode(id, promoCode);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminBillingApi->adminUpdatePromoCode: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **promoCode** | [**PromoCode**](PromoCode.md)|  | 

### Return type

[**PromoCode**](PromoCode.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

