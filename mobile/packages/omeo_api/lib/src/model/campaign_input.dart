//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/segment.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'campaign_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CampaignInput {
  /// Returns a new [CampaignInput] instance.
  CampaignInput({
    required this.title,

    required this.body,

    this.deeplink,

    this.imageUploadId,

    required this.segment,

    this.scheduledAt,
  });

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final Map<String, String> title;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'body', required: true, includeIfNull: false)
  final Map<String, String> body;

  @JsonKey(name: r'deeplink', required: false, includeIfNull: false)
  final String? deeplink;

  @JsonKey(name: r'image_upload_id', required: false, includeIfNull: false)
  final String? imageUploadId;

  @JsonKey(name: r'segment', required: true, includeIfNull: false)
  final Segment segment;

  @JsonKey(name: r'scheduled_at', required: false, includeIfNull: false)
  final DateTime? scheduledAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampaignInput &&
          other.title == title &&
          other.body == body &&
          other.deeplink == deeplink &&
          other.imageUploadId == imageUploadId &&
          other.segment == segment &&
          other.scheduledAt == scheduledAt;

  @override
  int get hashCode =>
      title.hashCode +
      body.hashCode +
      (deeplink == null ? 0 : deeplink.hashCode) +
      (imageUploadId == null ? 0 : imageUploadId.hashCode) +
      segment.hashCode +
      (scheduledAt == null ? 0 : scheduledAt.hashCode);

  factory CampaignInput.fromJson(Map<String, dynamic> json) =>
      _$CampaignInputFromJson(json);

  Map<String, dynamic> toJson() => _$CampaignInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
