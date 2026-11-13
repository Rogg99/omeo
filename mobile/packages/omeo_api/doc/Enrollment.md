# omeo_api.model.Enrollment

## Load the model package
```dart
import 'package:omeo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**program** | [**ProgramSummary**](ProgramSummary.md) |  | 
**status** | **String** |  | 
**startedOn** | [**DateTime**](DateTime.md) |  | 
**dayIndex** | **int** |  | 
**percent** | **int** |  | 
**assiduityPercent** | **int** |  | [optional] 
**today** | [**ProgramDayView**](ProgramDayView.md) |  | 
**week** | [**List&lt;ProgramDayView&gt;**](ProgramDayView.md) |  | 
**report** | **Object** | Bilan final (poids, assiduité) si terminé | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


