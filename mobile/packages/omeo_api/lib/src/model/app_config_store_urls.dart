//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_config_store_urls.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppConfigStoreUrls {
  /// Returns a new [AppConfigStoreUrls] instance.
  AppConfigStoreUrls({this.googlePlay, this.appStore});

  @JsonKey(name: r'google_play', required: false, includeIfNull: false)
  final String? googlePlay;

  @JsonKey(name: r'app_store', required: false, includeIfNull: false)
  final String? appStore;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfigStoreUrls &&
          other.googlePlay == googlePlay &&
          other.appStore == appStore;

  @override
  int get hashCode => googlePlay.hashCode + appStore.hashCode;

  factory AppConfigStoreUrls.fromJson(Map<String, dynamic> json) =>
      _$AppConfigStoreUrlsFromJson(json);

  Map<String, dynamic> toJson() => _$AppConfigStoreUrlsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
