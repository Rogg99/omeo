# omeo_api.model.ApprovalRequest

## Load the model package
```dart
import 'package:omeo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**kind** | **String** |  | 
**domain** | **String** |  | 
**status** | **String** |  | 
**summary** | **String** | Résumé lisible de l'action demandée | 
**targetType** | **String** |  | [optional] 
**targetId** | **String** |  | [optional] 
**diff** | **Map&lt;String, Object&gt;** | Avant / après proposés | [optional] 
**reason** | **String** |  | [optional] 
**requestedBy** | **String** |  | 
**decidedBy** | **String** |  | [optional] 
**decisionComment** | **String** |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**decidedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**expiresAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


