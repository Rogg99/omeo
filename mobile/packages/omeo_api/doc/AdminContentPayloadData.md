# omeo_api.model.AdminContentPayloadData

## Load the model package
```dart
import 'package:omeo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **Map&lt;String, String&gt;** | Admin uniquement. Clés = codes de langue. | 
**aliases** | **List&lt;String&gt;** |  | [optional] 
**category** | **String** |  | 
**kcal** | **num** |  | 
**proteinG** | **num** |  | 
**carbsG** | **num** |  | 
**sugarsG** | **num** |  | [optional] 
**fatG** | **num** |  | 
**saturatedFatG** | **num** |  | [optional] 
**fiberG** | **num** |  | [optional] 
**saltG** | **num** |  | [optional] 
**defaultPortionG** | **num** |  | [optional] 
**source_** | **String** |  | [optional] 
**country** | **String** |  | 
**standardPortionG** | **num** |  | 
**imageUploadId** | **String** |  | [optional] 
**recipeId** | **String** |  | [optional] 
**components** | [**List&lt;MealItemInput&gt;**](MealItemInput.md) |  | 
**description** | **Map&lt;String, String&gt;** | Admin uniquement. Clés = codes de langue. | [optional] 
**prepMinutes** | **int** |  | [optional] 
**cookMinutes** | **int** |  | [optional] 
**difficulty** | **String** |  | [optional] 
**servings** | **int** |  | 
**tags** | **List&lt;String&gt;** |  | [optional] 
**goals** | [**List&lt;Goal&gt;**](Goal.md) |  | [optional] 
**isFree** | **bool** |  | [optional] 
**ingredients** | [**List&lt;AdminRecipeIngredientsInner&gt;**](AdminRecipeIngredientsInner.md) |  | 
**steps** | [**List&lt;AdminWorkoutStepsInner&gt;**](AdminWorkoutStepsInner.md) |  | 
**commonName** | **Map&lt;String, String&gt;** | Admin uniquement. Clés = codes de langue. | 
**scientificName** | **String** |  | 
**traditionalUse** | **Map&lt;String, String&gt;** | Admin uniquement. Clés = codes de langue. | 
**nutritionalBenefits** | **Map&lt;String, String&gt;** | Admin uniquement. Clés = codes de langue. | 
**precautions** | **Map&lt;String, String&gt;** | Admin uniquement. Clés = codes de langue. | 
**contraindications** | **List&lt;String&gt;** |  | [optional] 
**relatedRecipeIds** | **List&lt;String&gt;** |  | [optional] 
**instructions** | **Map&lt;String, String&gt;** | Admin uniquement. Clés = codes de langue. | 
**muscles** | **List&lt;String&gt;** |  | [optional] 
**level** | [**Level**](Level.md) |  | 
**equipment** | **List&lt;String&gt;** |  | [optional] 
**met** | **num** |  | 
**videoUploadId** | **String** |  | [optional] 
**subtitleUploadIds** | **Map&lt;String, String&gt;** |  | [optional] 
**goal** | [**Goal**](Goal.md) |  | 
**coverUploadId** | **String** |  | [optional] 
**weeks** | **int** |  | 
**points** | **int** |  | 
**badgeId** | **String** |  | [optional] 
**days** | [**List&lt;AdminProgramDaysInner&gt;**](AdminProgramDaysInner.md) |  | 
**durationDays** | **int** |  | 
**rule** | [**RuleDef**](RuleDef.md) |  | 
**successThreshold** | **num** |  | [optional] [default to 0.8]
**pointsPerDay** | **int** |  | [optional] 
**pointsCompletion** | **int** |  | [optional] 
**code** | **String** |  | 
**family** | **String** |  | 
**condition** | **Map&lt;String, Object&gt;** |  | 
**bonusPoints** | **int** |  | [optional] 
**iconUploadId** | **String** |  | [optional] 
**rank** | **int** |  | 
**minPoints** | **int** |  | 
**action** | **String** |  | 
**cap** | **int** |  | [optional] 
**capPeriod** | **String** |  | [optional] 
**topic** | **String** |  | 
**title** | **Map&lt;String, String&gt;** | Admin uniquement. Clés = codes de langue. | 
**body** | **Map&lt;String, String&gt;** | Admin uniquement. Clés = codes de langue. | 
**trigger** | **Map&lt;String, Object&gt;** |  | 
**tier** | **String** |  | 
**relatedPlantIds** | **List&lt;String&gt;** |  | [optional] 
**question** | **Map&lt;String, String&gt;** | Admin uniquement. Clés = codes de langue. | 
**answer** | **Map&lt;String, String&gt;** | Admin uniquement. Clés = codes de langue. | 
**order** | **int** |  | [optional] 
**audience** | **String** |  | [optional] 
**kind** | [**LegalKind**](LegalKind.md) |  | 
**requiresReaccept** | **bool** |  | [optional] 
**timezone** | **String** |  | 
**isSuggested** | **bool** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


