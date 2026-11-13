# omeo_api.model.RegisterRequest

## Load the model package
```dart
import 'package:omeo_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**email** | **String** |  | 
**password** | **String** | ≥ 10 caractères, minuscule, majuscule, chiffre, caractère spécial (vérifié par l'API) | 
**inviteCode** | **String** |  | [optional] 
**profile** | [**OnboardingProfile**](OnboardingProfile.md) |  | 
**consents** | [**List&lt;ConsentInput&gt;**](ConsentInput.md) |  | 
**device** | [**DeviceInfo**](DeviceInfo.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


