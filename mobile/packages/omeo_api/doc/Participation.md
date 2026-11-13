# omeo_api.model.Participation

## Load the model package
```dart
import 'package:omeo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**challenge** | [**ChallengeSummary**](ChallengeSummary.md) |  | 
**status** | **String** |  | 
**startedOn** | [**DateTime**](DateTime.md) |  | 
**endsOn** | [**DateTime**](DateTime.md) |  | [optional] 
**successRatePercent** | **int** |  | 
**streak** | **int** |  | 
**today** | [**ChallengeToday**](ChallengeToday.md) |  | [optional] 
**days** | [**List&lt;ParticipationDaysInner&gt;**](ParticipationDaysInner.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


