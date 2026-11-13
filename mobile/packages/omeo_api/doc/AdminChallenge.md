# omeo_api.model.AdminChallenge

## Load the model package
```dart
import 'package:omeo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **Map&lt;String, String&gt;** | Admin uniquement. Clés = codes de langue. | 
**description** | **Map&lt;String, String&gt;** | Admin uniquement. Clés = codes de langue. | [optional] 
**durationDays** | **int** |  | 
**rule** | [**RuleDef**](RuleDef.md) |  | 
**successThreshold** | **num** |  | [optional] [default to 0.8]
**pointsPerDay** | **int** |  | [optional] 
**pointsCompletion** | **int** |  | [optional] 
**badgeId** | **String** |  | [optional] 
**coverUploadId** | **String** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


