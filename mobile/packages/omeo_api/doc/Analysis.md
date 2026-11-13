# omeo_api.model.Analysis

## Load the model package
```dart
import 'package:omeo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**kind** | **String** |  | 
**status** | **String** |  | 
**failureReason** | **String** |  | [optional] 
**failureMessage** | **String** |  | [optional] 
**photo** | [**Image**](Image.md) |  | [optional] 
**dish** | [**DishSummary**](DishSummary.md) |  | [optional] 
**dishLabel** | **String** |  | [optional] 
**confidence** | **num** |  | [optional] 
**lowConfidence** | **bool** |  | [optional] 
**alternatives** | [**List&lt;AnalysisAlternative&gt;**](AnalysisAlternative.md) | Autres plats envisagés, par probabilité décroissante (rubrique « Pas satisfait ? ») | [optional] 
**items** | [**List&lt;AnalysisItem&gt;**](AnalysisItem.md) |  | [optional] 
**totals** | [**Nutrients**](Nutrients.md) |  | [optional] 
**suggestedMealType** | [**MealType**](MealType.md) |  | [optional] 
**suggestedRecipeId** | **String** |  | [optional] 
**quota** | [**Quota**](Quota.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


