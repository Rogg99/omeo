# omeo_api.model.AdminContentItem

## Load the model package
```dart
import 'package:omeo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**type** | [**ContentTypeName**](ContentTypeName.md) |  | 
**title** | **String** |  | 
**status** | [**ContentStatus**](ContentStatus.md) |  | 
**missingLocales** | [**List&lt;Locale&gt;**](Locale.md) |  | 
**thumbnail** | [**Image**](Image.md) |  | [optional] 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**updatedBy** | **String** |  | [optional] 
**version** | **int** |  | 
**data** | **Map&lt;String, Object&gt;** |  | 
**computed** | **Map&lt;String, Object&gt;** | Valeurs calculées (nutriments, durée…), lecture seule | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


