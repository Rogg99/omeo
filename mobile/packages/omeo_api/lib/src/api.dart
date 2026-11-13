//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:dio/dio.dart';
import 'package:omeo_api/src/auth/api_key_auth.dart';
import 'package:omeo_api/src/auth/basic_auth.dart';
import 'package:omeo_api/src/auth/bearer_auth.dart';
import 'package:omeo_api/src/auth/oauth.dart';
import 'package:omeo_api/src/api/account_api.dart';
import 'package:omeo_api/src/api/activity_api.dart';
import 'package:omeo_api/src/api/admin_billing_api.dart';
import 'package:omeo_api/src/api/admin_campaigns_api.dart';
import 'package:omeo_api/src/api/admin_content_api.dart';
import 'package:omeo_api/src/api/admin_dashboard_api.dart';
import 'package:omeo_api/src/api/admin_feedback_api.dart';
import 'package:omeo_api/src/api/admin_settings_api.dart';
import 'package:omeo_api/src/api/admin_support_api.dart';
import 'package:omeo_api/src/api/admin_team_api.dart';
import 'package:omeo_api/src/api/admin_users_api.dart';
import 'package:omeo_api/src/api/app_api.dart';
import 'package:omeo_api/src/api/auth_api.dart';
import 'package:omeo_api/src/api/billing_api.dart';
import 'package:omeo_api/src/api/catalog_api.dart';
import 'package:omeo_api/src/api/challenges_api.dart';
import 'package:omeo_api/src/api/content_api.dart';
import 'package:omeo_api/src/api/home_api.dart';
import 'package:omeo_api/src/api/meals_api.dart';
import 'package:omeo_api/src/api/notifications_api.dart';
import 'package:omeo_api/src/api/programs_api.dart';
import 'package:omeo_api/src/api/rewards_api.dart';
import 'package:omeo_api/src/api/support_api.dart';
import 'package:omeo_api/src/api/tracking_api.dart';
import 'package:omeo_api/src/api/training_api.dart';
import 'package:omeo_api/src/api/webhooks_api.dart';

class OmeoApi {
  static const String basePath = r'http://api.localhost/api/v1';

  final Dio dio;
  OmeoApi({Dio? dio, String? basePathOverride, List<Interceptor>? interceptors})
    : this.dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: basePathOverride ?? basePath,
              connectTimeout: const Duration(milliseconds: 5000),
              receiveTimeout: const Duration(milliseconds: 3000),
            ),
          ) {
    if (interceptors == null) {
      this.dio.interceptors.addAll([
        OAuthInterceptor(),
        BasicAuthInterceptor(),
        BearerAuthInterceptor(),
        ApiKeyAuthInterceptor(),
      ]);
    } else {
      this.dio.interceptors.addAll(interceptors);
    }
  }

  void setOAuthToken(String name, String token) {
    if (this.dio.interceptors.any((i) => i is OAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is OAuthInterceptor)
                  as OAuthInterceptor)
              .tokens[name] =
          token;
    }
  }

  /// Removes the OAuth token associated with the given [name].
  ///
  /// If no [OAuthInterceptor] is registered or no token exists for the given
  /// [name], this method has no effect.
  void removeOAuthToken(String name) {
    if (this.dio.interceptors.any((i) => i is OAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is OAuthInterceptor)
              as OAuthInterceptor)
          .tokens
          .remove(name);
    }
  }

  void setBearerAuth(String name, String token) {
    if (this.dio.interceptors.any((i) => i is BearerAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BearerAuthInterceptor)
                  as BearerAuthInterceptor)
              .tokens[name] =
          token;
    }
  }

  /// Removes the bearer authentication token associated with the given [name].
  ///
  /// If no [BearerAuthInterceptor] is registered or no token exists for the
  /// given [name], this method has no effect.
  void removeBearerAuth(String name) {
    if (this.dio.interceptors.any((i) => i is BearerAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BearerAuthInterceptor)
              as BearerAuthInterceptor)
          .tokens
          .remove(name);
    }
  }

  void setBasicAuth(String name, String username, String password) {
    if (this.dio.interceptors.any((i) => i is BasicAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BasicAuthInterceptor)
              as BasicAuthInterceptor)
          .authInfo[name] = BasicAuthInfo(
        username,
        password,
      );
    }
  }

  /// Removes the basic authentication credentials associated with the given [name].
  ///
  /// If no [BasicAuthInterceptor] is registered or no credentials exist for the
  /// given [name], this method has no effect.
  void removeBasicAuth(String name) {
    if (this.dio.interceptors.any((i) => i is BasicAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BasicAuthInterceptor)
              as BasicAuthInterceptor)
          .authInfo
          .remove(name);
    }
  }

  void setApiKey(String name, String apiKey) {
    if (this.dio.interceptors.any((i) => i is ApiKeyAuthInterceptor)) {
      (this.dio.interceptors.firstWhere(
                    (element) => element is ApiKeyAuthInterceptor,
                  )
                  as ApiKeyAuthInterceptor)
              .apiKeys[name] =
          apiKey;
    }
  }

  /// Removes the API key associated with the given [name].
  ///
  /// If no [ApiKeyAuthInterceptor] is registered or no API key exists for the
  /// given [name], this method has no effect.
  void removeApiKey(String name) {
    if (this.dio.interceptors.any((i) => i is ApiKeyAuthInterceptor)) {
      (this.dio.interceptors.firstWhere(
                (element) => element is ApiKeyAuthInterceptor,
              )
              as ApiKeyAuthInterceptor)
          .apiKeys
          .remove(name);
    }
  }

  /// Get AccountApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AccountApi getAccountApi() {
    return AccountApi(dio);
  }

  /// Get ActivityApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ActivityApi getActivityApi() {
    return ActivityApi(dio);
  }

  /// Get AdminBillingApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminBillingApi getAdminBillingApi() {
    return AdminBillingApi(dio);
  }

  /// Get AdminCampaignsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminCampaignsApi getAdminCampaignsApi() {
    return AdminCampaignsApi(dio);
  }

  /// Get AdminContentApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminContentApi getAdminContentApi() {
    return AdminContentApi(dio);
  }

  /// Get AdminDashboardApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminDashboardApi getAdminDashboardApi() {
    return AdminDashboardApi(dio);
  }

  /// Get AdminFeedbackApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminFeedbackApi getAdminFeedbackApi() {
    return AdminFeedbackApi(dio);
  }

  /// Get AdminSettingsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminSettingsApi getAdminSettingsApi() {
    return AdminSettingsApi(dio);
  }

  /// Get AdminSupportApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminSupportApi getAdminSupportApi() {
    return AdminSupportApi(dio);
  }

  /// Get AdminTeamApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminTeamApi getAdminTeamApi() {
    return AdminTeamApi(dio);
  }

  /// Get AdminUsersApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminUsersApi getAdminUsersApi() {
    return AdminUsersApi(dio);
  }

  /// Get AppApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AppApi getAppApi() {
    return AppApi(dio);
  }

  /// Get AuthApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AuthApi getAuthApi() {
    return AuthApi(dio);
  }

  /// Get BillingApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  BillingApi getBillingApi() {
    return BillingApi(dio);
  }

  /// Get CatalogApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  CatalogApi getCatalogApi() {
    return CatalogApi(dio);
  }

  /// Get ChallengesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ChallengesApi getChallengesApi() {
    return ChallengesApi(dio);
  }

  /// Get ContentApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ContentApi getContentApi() {
    return ContentApi(dio);
  }

  /// Get HomeApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  HomeApi getHomeApi() {
    return HomeApi(dio);
  }

  /// Get MealsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  MealsApi getMealsApi() {
    return MealsApi(dio);
  }

  /// Get NotificationsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  NotificationsApi getNotificationsApi() {
    return NotificationsApi(dio);
  }

  /// Get ProgramsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ProgramsApi getProgramsApi() {
    return ProgramsApi(dio);
  }

  /// Get RewardsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  RewardsApi getRewardsApi() {
    return RewardsApi(dio);
  }

  /// Get SupportApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  SupportApi getSupportApi() {
    return SupportApi(dio);
  }

  /// Get TrackingApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  TrackingApi getTrackingApi() {
    return TrackingApi(dio);
  }

  /// Get TrainingApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  TrainingApi getTrainingApi() {
    return TrainingApi(dio);
  }

  /// Get WebhooksApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  WebhooksApi getWebhooksApi() {
    return WebhooksApi(dio);
  }
}
