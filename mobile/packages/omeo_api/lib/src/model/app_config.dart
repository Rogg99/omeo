//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/app_config_trial_days.dart';
import 'package:omeo_api/src/model/locale.dart';
import 'package:omeo_api/src/model/app_config_store_urls.dart';
import 'package:omeo_api/src/model/app_config_min_version.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_config.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppConfig {
  /// Returns a new [AppConfig] instance.
  AppConfig({
    required this.minVersion,

    required this.latestVersion,

    required this.locales,

    required this.features,

    this.webCheckoutCountries,

    this.minAge,

    this.trialDays,

    required this.quotasDisplay,

    required this.legalVersions,

    this.supportEmail,

    this.storeUrls,
  });

  @JsonKey(name: r'min_version', required: true, includeIfNull: false)
  final AppConfigMinVersion minVersion;

  @JsonKey(name: r'latest_version', required: true, includeIfNull: false)
  final AppConfigMinVersion latestVersion;

  @JsonKey(name: r'locales', required: true, includeIfNull: false)
  final List<Locale> locales;

  @JsonKey(name: r'features', required: true, includeIfNull: false)
  final Map<String, bool> features;

  @JsonKey(
    name: r'web_checkout_countries',
    required: false,
    includeIfNull: false,
  )
  final List<String>? webCheckoutCountries;

  @JsonKey(name: r'min_age', required: false, includeIfNull: false)
  final int? minAge;

  @JsonKey(name: r'trial_days', required: false, includeIfNull: false)
  final AppConfigTrialDays? trialDays;

  @JsonKey(name: r'quotas_display', required: true, includeIfNull: false)
  final Map<String, Object> quotasDisplay;

  @JsonKey(name: r'legal_versions', required: true, includeIfNull: false)
  final Map<String, int> legalVersions;

  @JsonKey(name: r'support_email', required: false, includeIfNull: false)
  final String? supportEmail;

  @JsonKey(name: r'store_urls', required: false, includeIfNull: false)
  final AppConfigStoreUrls? storeUrls;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfig &&
          other.minVersion == minVersion &&
          other.latestVersion == latestVersion &&
          other.locales == locales &&
          other.features == features &&
          other.webCheckoutCountries == webCheckoutCountries &&
          other.minAge == minAge &&
          other.trialDays == trialDays &&
          other.quotasDisplay == quotasDisplay &&
          other.legalVersions == legalVersions &&
          other.supportEmail == supportEmail &&
          other.storeUrls == storeUrls;

  @override
  int get hashCode =>
      minVersion.hashCode +
      latestVersion.hashCode +
      locales.hashCode +
      features.hashCode +
      webCheckoutCountries.hashCode +
      minAge.hashCode +
      trialDays.hashCode +
      quotasDisplay.hashCode +
      legalVersions.hashCode +
      supportEmail.hashCode +
      storeUrls.hashCode;

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AppConfigToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
