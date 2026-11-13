# omeo_api.model.MealInput

## Load the model package
```dart
import 'package:omeo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**source_** | **String** |  | 
**mealType** | [**MealType**](MealType.md) |  | 
**date** | [**DateTime**](DateTime.md) |  | [optional] 
**eatenAt** | [**DateTime**](DateTime.md) |  | [optional] 
**analysisId** | **String** | source = photo|text | [optional] 
**dishId** | **String** | source = dish | [optional] 
**recipeId** | **String** | source = recipe|program | [optional] 
**portions** | **num** | dish/recipe : multiple de la portion standard | [optional] 
**items** | [**List&lt;MealItemInput&gt;**](MealItemInput.md) | Ingrédients validés (corrigés) — obligatoire pour photo|text|foods | [optional] 
**keepPhoto** | **bool** |  | [optional] [default to true]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


