# omeo_api.model.ActivityOverview

## Load the model package
```dart
import 'package:omeo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**date** | [**DateTime**](DateTime.md) |  | 
**steps** | [**Gauge**](Gauge.md) |  | 
**distanceM** | **int** |  | [optional] 
**activeKcal** | **int** |  | [optional] 
**activeMinutes** | **int** |  | [optional] 
**health** | [**HealthConnection**](HealthConnection.md) |  | 
**balanceDay** | [**Balance**](Balance.md) |  | 
**balanceWeek** | [**List&lt;ActivityOverviewBalanceWeekInner&gt;**](ActivityOverviewBalanceWeekInner.md) |  | 
**activities** | [**List&lt;Activity&gt;**](Activity.md) |  | 
**recommendedWorkouts** | [**List&lt;WorkoutSummary&gt;**](WorkoutSummary.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


