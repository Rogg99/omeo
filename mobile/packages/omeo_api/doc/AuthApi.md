# omeo_api.api.AuthApi

## Load the API package
```dart
import 'package:omeo_api/api.dart';
```

All URIs are relative to *http://api.localhost/api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**forgotPassword**](AuthApi.md#forgotpassword) | **POST** /auth/password/forgot | Envoie un lien de réinitialisation
[**login**](AuthApi.md#login) | **POST** /auth/login | Connexion par email et mot de passe
[**logout**](AuthApi.md#logout) | **POST** /auth/logout | Déconnexion de l&#39;appareil courant (ou de tous)
[**refreshToken**](AuthApi.md#refreshtoken) | **POST** /auth/refresh | Rotation du jeton de rafraîchissement
[**register**](AuthApi.md#register) | **POST** /auth/register | Inscription par email (fin de l&#39;onboarding, étape 9)
[**resendVerificationEmail**](AuthApi.md#resendverificationemail) | **POST** /auth/email/resend | Renvoie l&#39;email de vérification
[**resetPassword**](AuthApi.md#resetpassword) | **POST** /auth/password/reset | Définit un nouveau mot de passe à partir du lien reçu
[**socialAuth**](AuthApi.md#socialauth) | **POST** /auth/social | Connexion ou inscription avec Google ou Apple
[**stepUpMfa**](AuthApi.md#stepupmfa) | **POST** /auth/mfa/step-up | Revalide le TOTP de la session staff (actions sensibles, valable 15 min)
[**verifyEmail**](AuthApi.md#verifyemail) | **POST** /auth/email/verify | Vérifie l&#39;adresse email avec le code reçu
[**verifyMfa**](AuthApi.md#verifymfa) | **POST** /auth/mfa/verify | Second facteur (TOTP ou code de secours) pour les comptes staff


# **forgotPassword**
> forgotPassword(forgotPasswordRequest)

Envoie un lien de réinitialisation

Répond toujours 204, que l'email existe ou non (pas d'énumération).

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAuthApi();
final ForgotPasswordRequest forgotPasswordRequest = ; // ForgotPasswordRequest | 

try {
    api.forgotPassword(forgotPasswordRequest);
} on DioException catch (e) {
    print('Exception when calling AuthApi->forgotPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **forgotPasswordRequest** | [**ForgotPasswordRequest**](ForgotPasswordRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **login**
> AuthResult login(loginRequest)

Connexion par email et mot de passe

Pour un compte staff, renvoie 401 `mfa_required` avec `meta.mfa_token`.

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAuthApi();
final LoginRequest loginRequest = ; // LoginRequest | 

try {
    final response = api.login(loginRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->login: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **loginRequest** | [**LoginRequest**](LoginRequest.md)|  | 

### Return type

[**AuthResult**](AuthResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **logout**
> logout(logoutRequest)

Déconnexion de l'appareil courant (ou de tous)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAuthApi();
final LogoutRequest logoutRequest = ; // LogoutRequest | 

try {
    api.logout(logoutRequest);
} on DioException catch (e) {
    print('Exception when calling AuthApi->logout: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **logoutRequest** | [**LogoutRequest**](LogoutRequest.md)|  | [optional] 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **refreshToken**
> Tokens refreshToken(refreshTokenRequest)

Rotation du jeton de rafraîchissement

Rejouer un refresh déjà utilisé révoque toute la session (détection de vol).

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAuthApi();
final RefreshTokenRequest refreshTokenRequest = ; // RefreshTokenRequest | 

try {
    final response = api.refreshToken(refreshTokenRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->refreshToken: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **refreshTokenRequest** | [**RefreshTokenRequest**](RefreshTokenRequest.md)|  | 

### Return type

[**Tokens**](Tokens.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **register**
> AuthResult register(registerRequest)

Inscription par email (fin de l'onboarding, étape 9)

Crée le compte, le profil (réponses 1 à 8), les consentements, l'essai (3 j ou 7 j avec code valide) et les objectifs. Un code d'invitation invalide ne bloque pas : `invite_code_status` le signale. 

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAuthApi();
final RegisterRequest registerRequest = ; // RegisterRequest | 

try {
    final response = api.register(registerRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->register: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **registerRequest** | [**RegisterRequest**](RegisterRequest.md)|  | 

### Return type

[**AuthResult**](AuthResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resendVerificationEmail**
> resendVerificationEmail()

Renvoie l'email de vérification

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAuthApi();

try {
    api.resendVerificationEmail();
} on DioException catch (e) {
    print('Exception when calling AuthApi->resendVerificationEmail: $e\n');
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

# **resetPassword**
> resetPassword(resetPasswordRequest)

Définit un nouveau mot de passe à partir du lien reçu

Révoque toutes les sessions existantes.

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAuthApi();
final ResetPasswordRequest resetPasswordRequest = ; // ResetPasswordRequest | 

try {
    api.resetPassword(resetPasswordRequest);
} on DioException catch (e) {
    print('Exception when calling AuthApi->resetPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **resetPasswordRequest** | [**ResetPasswordRequest**](ResetPasswordRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **socialAuth**
> AuthResult socialAuth(socialAuthRequest)

Connexion ou inscription avec Google ou Apple

Vérifie l'`id_token` auprès du fournisseur. Si le compte n'existe pas, `profile` et `consents` sont obligatoires (sinon 400 `validation_error`). `created` indique s'il s'agit d'une inscription. 

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAuthApi();
final SocialAuthRequest socialAuthRequest = ; // SocialAuthRequest | 

try {
    final response = api.socialAuth(socialAuthRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->socialAuth: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **socialAuthRequest** | [**SocialAuthRequest**](SocialAuthRequest.md)|  | 

### Return type

[**AuthResult**](AuthResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stepUpMfa**
> StepUpMfa200Response stepUpMfa(stepUpMfaRequest)

Revalide le TOTP de la session staff (actions sensibles, valable 15 min)

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAuthApi();
final StepUpMfaRequest stepUpMfaRequest = ; // StepUpMfaRequest | 

try {
    final response = api.stepUpMfa(stepUpMfaRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->stepUpMfa: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stepUpMfaRequest** | [**StepUpMfaRequest**](StepUpMfaRequest.md)|  | 

### Return type

[**StepUpMfa200Response**](StepUpMfa200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **verifyEmail**
> verifyEmail(verifyEmailRequest)

Vérifie l'adresse email avec le code reçu

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAuthApi();
final VerifyEmailRequest verifyEmailRequest = ; // VerifyEmailRequest | 

try {
    api.verifyEmail(verifyEmailRequest);
} on DioException catch (e) {
    print('Exception when calling AuthApi->verifyEmail: $e\n');
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

# **verifyMfa**
> AuthResult verifyMfa(verifyMfaRequest)

Second facteur (TOTP ou code de secours) pour les comptes staff

### Example
```dart
import 'package:omeo_api/api.dart';

final api = OmeoApi().getAuthApi();
final VerifyMfaRequest verifyMfaRequest = ; // VerifyMfaRequest | 

try {
    final response = api.verifyMfa(verifyMfaRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->verifyMfa: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **verifyMfaRequest** | [**VerifyMfaRequest**](VerifyMfaRequest.md)|  | 

### Return type

[**AuthResult**](AuthResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

