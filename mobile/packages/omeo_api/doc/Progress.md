# omeo_api.model.Progress

## Load the model package
```dart
import 'package:omeo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**metric** | **String** |  | 
**range** | **String** |  | 
**unit** | **String** |  | 
**today** | **num** |  | 
**deltaVsYesterday** | **num** |  | [optional] 
**deltaPercent** | **int** |  | [optional] 
**target** | **num** |  | [optional] 
**average** | **num** |  | [optional] 
**empty** | **bool** | Aucun repas encore : afficher l'illustration | [optional] 
**series** | [**List&lt;ProgressSeriesInner&gt;**](ProgressSeriesInner.md) |  | 
**summaryLast7** | [**List&lt;ProgressSummaryLast7Inner&gt;**](ProgressSummaryLast7Inner.md) |  | 
**health** | [**HealthConnection**](HealthConnection.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


