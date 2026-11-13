//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/image.dart';
import 'package:omeo_api/src/model/media_subtitles_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'media.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Media {
  /// Returns a new [Media] instance.
  Media({required this.hlsUrl, this.poster, this.durationS, this.subtitles});

  @JsonKey(name: r'hls_url', required: true, includeIfNull: false)
  final String hlsUrl;

  @JsonKey(name: r'poster', required: false, includeIfNull: false)
  final Image? poster;

  @JsonKey(name: r'duration_s', required: false, includeIfNull: false)
  final int? durationS;

  @JsonKey(name: r'subtitles', required: false, includeIfNull: false)
  final List<MediaSubtitlesInner>? subtitles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Media &&
          other.hlsUrl == hlsUrl &&
          other.poster == poster &&
          other.durationS == durationS &&
          other.subtitles == subtitles;

  @override
  int get hashCode =>
      hlsUrl.hashCode +
      poster.hashCode +
      durationS.hashCode +
      subtitles.hashCode;

  factory Media.fromJson(Map<String, dynamic> json) => _$MediaFromJson(json);

  Map<String, dynamic> toJson() => _$MediaToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
