//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/locale.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'media_subtitles_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MediaSubtitlesInner {
  /// Returns a new [MediaSubtitlesInner] instance.
  MediaSubtitlesInner({this.locale, this.url});

  @JsonKey(name: r'locale', required: false, includeIfNull: false)
  final Locale? locale;

  @JsonKey(name: r'url', required: false, includeIfNull: false)
  final String? url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaSubtitlesInner &&
          other.locale == locale &&
          other.url == url;

  @override
  int get hashCode => locale.hashCode + url.hashCode;

  factory MediaSubtitlesInner.fromJson(Map<String, dynamic> json) =>
      _$MediaSubtitlesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$MediaSubtitlesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
