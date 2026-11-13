# omeo_api.model.SubscriptionState

## Load the model package
```dart
import 'package:omeo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**entitlements** | [**Entitlements**](Entitlements.md) |  | 
**subscription** | [**SubscriptionStateSubscription**](SubscriptionStateSubscription.md) |  | [optional] 
**trialDaysLeft** | **int** |  | [optional] 
**grantedDaysLeft** | **int** |  | [optional] 
**quotas** | [**List&lt;Quota&gt;**](Quota.md) |  | 
**canPurchaseInApp** | **bool** |  | 
**canManage** | **String** |  | 
**webCheckoutAllowed** | **bool** | Pays autorisé à renvoyer vers le site | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


