# omeo_api.model.AdminFeedbackDetail

## Load the model package
```dart
import 'package:omeo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**rating** | **String** |  | 
**reason** | [**FeedbackReason**](FeedbackReason.md) |  | [optional] 
**status** | **String** |  | 
**dishLabel** | **String** |  | [optional] 
**confidence** | **num** |  | [optional] 
**locale** | [**Locale**](Locale.md) |  | [optional] 
**country** | **String** |  | [optional] 
**thumbnail** | [**Image**](Image.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**photo** | [**Image**](Image.md) |  | [optional] 
**inputText** | **String** |  | [optional] 
**comment** | **String** |  | [optional] 
**model** | **String** |  | [optional] 
**promptVersion** | **String** |  | [optional] 
**aiRaw** | **Map&lt;String, Object&gt;** |  | [optional] 
**aiItems** | [**List&lt;AnalysisItem&gt;**](AnalysisItem.md) |  | [optional] 
**correctedItems** | [**List&lt;AnalysisItem&gt;**](AnalysisItem.md) |  | [optional] 
**handledBy** | **String** |  | [optional] 
**handledAction** | **String** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


