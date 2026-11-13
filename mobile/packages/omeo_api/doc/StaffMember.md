# omeo_api.model.StaffMember

## Load the model package
```dart
import 'package:omeo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**email** | **String** |  | 
**name** | **String** |  | [optional] 
**roles** | [**List&lt;StaffRole&gt;**](StaffRole.md) |  | 
**permissions** | **List&lt;String&gt;** | Permissions effectives (docs/technique/controle-acces.md), ex. users.view, billing.refund | [optional] 
**mfaVerifiedUntil** | [**DateTime**](DateTime.md) | Fin de validité du step-up | [optional] 
**pendingApprovals** | **int** | Demandes en attente que la personne peut valider | [optional] 
**mfaEnabled** | **bool** |  | 
**active** | **bool** |  | 
**lastLoginAt** | [**DateTime**](DateTime.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


