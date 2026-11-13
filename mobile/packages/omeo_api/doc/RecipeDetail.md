# omeo_api.model.RecipeDetail

## Load the model package
```dart
import 'package:omeo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**name** | **String** |  | 
**country** | **String** |  | [optional] 
**image** | [**Image**](Image.md) |  | [optional] 
**totalMinutes** | **int** |  | 
**difficulty** | **String** |  | [optional] 
**kcalPerServing** | **int** |  | [optional] 
**tags** | **List&lt;String&gt;** |  | [optional] 
**tagLabels** | **List&lt;String&gt;** |  | [optional] 
**isFavorite** | **bool** |  | [optional] 
**locked** | **bool** |  | 
**description** | **String** |  | [optional] 
**prepMinutes** | **int** |  | [optional] 
**cookMinutes** | **int** |  | [optional] 
**servings** | **int** |  | 
**ingredients** | [**List&lt;RecipeDetailAllOfIngredients&gt;**](RecipeDetailAllOfIngredients.md) |  | 
**steps** | [**List&lt;RecipeDetailAllOfSteps&gt;**](RecipeDetailAllOfSteps.md) |  | 
**nutrientsPerServing** | [**Nutrients**](Nutrients.md) |  | 
**relatedPlants** | [**List&lt;PlantSummary&gt;**](PlantSummary.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


