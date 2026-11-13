# omeo_api.model.AdminUserDetail

## Load the model package
```dart
import 'package:omeo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**email** | **String** |  | 
**name** | **String** |  | 
**country** | **String** |  | [optional] 
**locale** | [**Locale**](Locale.md) |  | [optional] 
**tier** | [**PlanTier**](PlanTier.md) |  | 
**status** | **String** |  | 
**platform** | **String** |  | [optional] 
**lastSeenAt** | [**DateTime**](DateTime.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**emailVerified** | **bool** |  | [optional] 
**goals** | [**List&lt;Goal&gt;**](Goal.md) |  | [optional] 
**healthMasked** | **bool** | Toujours true : les données de santé restent masquées dans cette vue | [optional] 
**subscription** | [**SubscriptionState**](SubscriptionState.md) |  | [optional] 
**payments** | [**List&lt;Payment&gt;**](Payment.md) |  | [optional] 
**referral** | [**ReferralOverview**](ReferralOverview.md) |  | [optional] 
**sessions** | [**List&lt;Session&gt;**](Session.md) |  | [optional] 
**consents** | [**List&lt;ConsentState&gt;**](ConsentState.md) |  | [optional] 
**tickets** | [**List&lt;TicketSummary&gt;**](TicketSummary.md) |  | [optional] 
**stats** | [**AdminUserDetailAllOfStats**](AdminUserDetailAllOfStats.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


