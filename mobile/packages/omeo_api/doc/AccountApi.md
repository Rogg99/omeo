# omeo_api.api.AccountApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**changeEmail**](AccountApi.md#changeemail) | **POST** /me/email | Change l&#39;email (lien de confirmation envoyé à la nouvelle adresse)
[**changePassword**](AccountApi.md#changepassword) | **POST** /me/password | Change ou définit le mot de passe (révoque les autres sessions)
[**confirmDeletionByEmail**](AccountApi.md#confirmdeletionbyemail) | **POST** /account-deletion/confirm | Confirme la suppression du compte depuis le lien reçu par email
[**createUpload**](AccountApi.md#createupload) | **POST** /me/uploads | Obtient une URL présignée pour téléverser un fichier directement vers le stockage
[**deleteAvatar**](AccountApi.md#deleteavatar) | **DELETE** /me/avatar | Supprime la photo de profil
[**getMe**](AccountApi.md#getme) | **GET** /me | Utilisateur, profil, objectifs, droits et préférences
[**listConsents**](AccountApi.md#listconsents) | **GET** /me/consents | État actuel des consentements et documents à (ré)accepter
[**listDataExports**](AccountApi.md#listdataexports) | **GET** /me/exports | Exports de données demandés
[**listSessions**](AccountApi.md#listsessions) | **GET** /me/sessions | Appareils connectés
[**listSocialAccounts**](AccountApi.md#listsocialaccounts) | **GET** /me/social-accounts | Comptes Google et Apple liés
[**requestAccountDeletion**](AccountApi.md#requestaccountdeletion) | **DELETE** /me | Demande de suppression du compte (purge à J+30)
[**requestDataExport**](AccountApi.md#requestdataexport) | **POST** /me/exports | Demande un export de toutes ses données (lien envoyé par email et notification)
[**requestDeletionByEmail**](AccountApi.md#requestdeletionbyemail) | **POST** /account-deletion | Demande publique de suppression (page web exigée par Google Play)
[**revokeSession**](AccountApi.md#revokesession) | **DELETE** /me/sessions/{id} | Révoque une session
[**setAvatar**](AccountApi.md#setavatar) | **PUT** /me/avatar | Définit la photo de profil
[**updateConsents**](AccountApi.md#updateconsents) | **POST** /me/consents | Accepte ou retire des consentements (ajout seul côté serveur)
[**updateProfile**](AccountApi.md#updateprofile) | **PATCH** /me/profile | Modifie le profil (recalcule les objectifs si nécessaire)


# **changeEmail**
> changeEmail(changeEmailRequest)

Change l'email (lien de confirmation envoyé à la nouvelle adresse)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAccountApi();
final ChangeEmailRequest changeEmailRequest = ; // ChangeEmailRequest | 

try {
    api.changeEmail(changeEmailRequest);
} on DioException catch (e) {
    print('Exception when calling AccountApi->changeEmail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **changeEmailRequest** | [**ChangeEmailRequest**](ChangeEmailRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **changePassword**
> changePassword(changePasswordRequest)

Change ou définit le mot de passe (révoque les autres sessions)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAccountApi();
final ChangePasswordRequest changePasswordRequest = ; // ChangePasswordRequest | 

try {
    api.changePassword(changePasswordRequest);
} on DioException catch (e) {
    print('Exception when calling AccountApi->changePassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **changePasswordRequest** | [**ChangePasswordRequest**](ChangePasswordRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **confirmDeletionByEmail**
> confirmDeletionByEmail(verifyEmailRequest)

Confirme la suppression du compte depuis le lien reçu par email

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAccountApi();
final VerifyEmailRequest verifyEmailRequest = ; // VerifyEmailRequest | 

try {
    api.confirmDeletionByEmail(verifyEmailRequest);
} on DioException catch (e) {
    print('Exception when calling AccountApi->confirmDeletionByEmail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **verifyEmailRequest** | [**VerifyEmailRequest**](VerifyEmailRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createUpload**
> UploadTicket createUpload(idempotencyKey, createUploadRequest)

Obtient une URL présignée pour téléverser un fichier directement vers le stockage

Le client PUT le fichier sur `upload_url` avec les en-têtes fournis, puis référence `id`. L'API vérifie type réel, taille (≤ 8 Mo) et retire les métadonnées EXIF. 

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAccountApi();
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h).
final CreateUploadRequest createUploadRequest = ; // CreateUploadRequest | 

try {
    final response = api.createUpload(idempotencyKey, createUploadRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AccountApi->createUpload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**| UUID v4. Rejouer la même clé renvoie la réponse d'origine (24 h). | 
 **createUploadRequest** | [**CreateUploadRequest**](CreateUploadRequest.md)|  | 

### Return type

[**UploadTicket**](UploadTicket.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteAvatar**
> deleteAvatar()

Supprime la photo de profil

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAccountApi();

try {
    api.deleteAvatar();
} on DioException catch (e) {
    print('Exception when calling AccountApi->deleteAvatar: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMe**
> Me getMe()

Utilisateur, profil, objectifs, droits et préférences

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAccountApi();

try {
    final response = api.getMe();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AccountApi->getMe: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Me**](Me.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listConsents**
> ListConsents200Response listConsents()

État actuel des consentements et documents à (ré)accepter

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAccountApi();

try {
    final response = api.listConsents();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AccountApi->listConsents: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ListConsents200Response**](ListConsents200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listDataExports**
> List<DataExport> listDataExports()

Exports de données demandés

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAccountApi();

try {
    final response = api.listDataExports();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AccountApi->listDataExports: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List&lt;DataExport&gt;**](DataExport.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listSessions**
> List<Session> listSessions()

Appareils connectés

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAccountApi();

try {
    final response = api.listSessions();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AccountApi->listSessions: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List&lt;Session&gt;**](Session.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listSocialAccounts**
> List<ListSocialAccounts200ResponseInner> listSocialAccounts()

Comptes Google et Apple liés

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAccountApi();

try {
    final response = api.listSocialAccounts();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AccountApi->listSocialAccounts: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List&lt;ListSocialAccounts200ResponseInner&gt;**](ListSocialAccounts200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **requestAccountDeletion**
> RequestAccountDeletion200Response requestAccountDeletion(requestAccountDeletionRequest)

Demande de suppression du compte (purge à J+30)

Révoque les sessions. Réponse indique si un abonnement store reste à résilier.

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAccountApi();
final RequestAccountDeletionRequest requestAccountDeletionRequest = ; // RequestAccountDeletionRequest | 

try {
    final response = api.requestAccountDeletion(requestAccountDeletionRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AccountApi->requestAccountDeletion: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestAccountDeletionRequest** | [**RequestAccountDeletionRequest**](RequestAccountDeletionRequest.md)|  | 

### Return type

[**RequestAccountDeletion200Response**](RequestAccountDeletion200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **requestDataExport**
> DataExport requestDataExport()

Demande un export de toutes ses données (lien envoyé par email et notification)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAccountApi();

try {
    final response = api.requestDataExport();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AccountApi->requestDataExport: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DataExport**](DataExport.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **requestDeletionByEmail**
> requestDeletionByEmail(requestDeletionByEmailRequest)

Demande publique de suppression (page web exigée par Google Play)

Envoie un lien de confirmation si le compte existe. Répond toujours 204.

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAccountApi();
final RequestDeletionByEmailRequest requestDeletionByEmailRequest = ; // RequestDeletionByEmailRequest | 

try {
    api.requestDeletionByEmail(requestDeletionByEmailRequest);
} on DioException catch (e) {
    print('Exception when calling AccountApi->requestDeletionByEmail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestDeletionByEmailRequest** | [**RequestDeletionByEmailRequest**](RequestDeletionByEmailRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **revokeSession**
> revokeSession(id)

Révoque une session

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAccountApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.revokeSession(id);
} on DioException catch (e) {
    print('Exception when calling AccountApi->revokeSession: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setAvatar**
> Image setAvatar(setAvatarRequest)

Définit la photo de profil

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAccountApi();
final SetAvatarRequest setAvatarRequest = ; // SetAvatarRequest | 

try {
    final response = api.setAvatar(setAvatarRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AccountApi->setAvatar: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **setAvatarRequest** | [**SetAvatarRequest**](SetAvatarRequest.md)|  | 

### Return type

[**Image**](Image.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateConsents**
> List<ConsentState> updateConsents(updateConsentsRequest)

Accepte ou retire des consentements (ajout seul côté serveur)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAccountApi();
final UpdateConsentsRequest updateConsentsRequest = ; // UpdateConsentsRequest | 

try {
    final response = api.updateConsents(updateConsentsRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AccountApi->updateConsents: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateConsentsRequest** | [**UpdateConsentsRequest**](UpdateConsentsRequest.md)|  | 

### Return type

[**List&lt;ConsentState&gt;**](ConsentState.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateProfile**
> Me updateProfile(profileUpdate)

Modifie le profil (recalcule les objectifs si nécessaire)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAccountApi();
final ProfileUpdate profileUpdate = ; // ProfileUpdate | 

try {
    final response = api.updateProfile(profileUpdate);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AccountApi->updateProfile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **profileUpdate** | [**ProfileUpdate**](ProfileUpdate.md)|  | 

### Return type

[**Me**](Me.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

