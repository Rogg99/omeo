# omeo_api.model.AdminRecipe

## Load the model package
```dart
import 'package:omeo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **Map&lt;String, String&gt;** | Admin uniquement. Clés = codes de langue. | 
**description** | **Map&lt;String, String&gt;** | Admin uniquement. Clés = codes de langue. | [optional] 
**country** | **String** |  | [optional] 
**prepMinutes** | **int** |  | [optional] 
**cookMinutes** | **int** |  | [optional] 
**difficulty** | **String** |  | [optional] 
**servings** | **int** |  | 
**tags** | **List&lt;String&gt;** |  | [optional] 
**goals** | [**List&lt;Goal&gt;**](Goal.md) |  | [optional] 
**isFree** | **bool** |  | [optional] 
**imageUploadId** | **String** |  | [optional] 
**ingredients** | [**List&lt;AdminRecipeIngredientsInner&gt;**](AdminRecipeIngredientsInner.md) |  | 
**steps** | [**List&lt;AdminRecipeStepsInner&gt;**](AdminRecipeStepsInner.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


