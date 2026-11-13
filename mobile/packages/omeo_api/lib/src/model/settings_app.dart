//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/locale.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_app.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SettingsApp {
  /// Returns a new [SettingsApp] instance.
  SettingsApp({
    this.minVersionAndroid,

    this.minVersionIos,

    this.minAge,

    this.activeLocales,

    this.features,

    this.webCheckoutCountries,
  });

  @JsonKey(name: r'min_version_android', required: false, includeIfNull: false)
  final String? minVersionAndroid;

  @JsonKey(name: r'min_version_ios', required: false, includeIfNull: false)
  final String? minVersionIos;

  @JsonKey(name: r'min_age', required: false, includeIfNull: false)
  final int? minAge;

  @JsonKey(name: r'active_locales', required: false, includeIfNull: false)
  final List<Locale>? activeLocales;

  @JsonKey(name: r'features', required: false, includeIfNull: false)
  final Map<String, bool>? features;

  @JsonKey(
    name: r'web_checkout_countries',
    required: false,
    includeIfNull: false,
  )
  final List<String>? webCheckoutCountries;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsApp &&
          other.minVersionAndroid == minVersionAndroid &&
          other.minVersionIos == minVersionIos &&
          other.minAge == minAge &&
          other.activeLocales == activeLocales &&
          other.features == features &&
          other.webCheckoutCountries == webCheckoutCountries;

  @override
  int get hashCode =>
      minVersionAndroid.hashCode +
      minVersionIos.hashCode +
      minAge.hashCode +
      activeLocales.hashCode +
      features.hashCode +
      webCheckoutCountries.hashCode;

  factory SettingsApp.fromJson(Map<String, dynamic> json) =>
      _$SettingsAppFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsAppToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
