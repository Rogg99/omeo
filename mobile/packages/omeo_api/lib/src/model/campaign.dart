//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/segment.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'campaign.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Campaign {
  /// Returns a new [Campaign] instance.
  Campaign({
    required this.title,

    required this.body,

    this.deeplink,

    this.imageUploadId,

    required this.segment,

    this.scheduledAt,

    required this.id,

    required this.status,

    this.audienceCount,

    this.sentCount,

    this.openedCount,

    this.openRate,

    this.createdBy,

    this.createdAt,
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

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final CampaignStatusEnum status;

  @JsonKey(name: r'audience_count', required: false, includeIfNull: false)
  final int? audienceCount;

  @JsonKey(name: r'sent_count', required: false, includeIfNull: false)
  final int? sentCount;

  @JsonKey(name: r'opened_count', required: false, includeIfNull: false)
  final int? openedCount;

  @JsonKey(name: r'open_rate', required: false, includeIfNull: false)
  final num? openRate;

  @JsonKey(name: r'created_by', required: false, includeIfNull: false)
  final String? createdBy;

  @JsonKey(name: r'created_at', required: false, includeIfNull: false)
  final DateTime? createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Campaign &&
          other.title == title &&
          other.body == body &&
          other.deeplink == deeplink &&
          other.imageUploadId == imageUploadId &&
          other.segment == segment &&
          other.scheduledAt == scheduledAt &&
          other.id == id &&
          other.status == status &&
          other.audienceCount == audienceCount &&
          other.sentCount == sentCount &&
          other.openedCount == openedCount &&
          other.openRate == openRate &&
          other.createdBy == createdBy &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      title.hashCode +
      body.hashCode +
      (deeplink == null ? 0 : deeplink.hashCode) +
      (imageUploadId == null ? 0 : imageUploadId.hashCode) +
      segment.hashCode +
      (scheduledAt == null ? 0 : scheduledAt.hashCode) +
      id.hashCode +
      status.hashCode +
      audienceCount.hashCode +
      sentCount.hashCode +
      openedCount.hashCode +
      (openRate == null ? 0 : openRate.hashCode) +
      createdBy.hashCode +
      createdAt.hashCode;

  factory Campaign.fromJson(Map<String, dynamic> json) =>
      _$CampaignFromJson(json);

  Map<String, dynamic> toJson() => _$CampaignToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CampaignStatusEnum {
  @JsonValue(r'draft')
  draft(r'draft'),
  @JsonValue(r'scheduled')
  scheduled(r'scheduled'),
  @JsonValue(r'sending')
  sending(r'sending'),
  @JsonValue(r'sent')
  sent(r'sent'),
  @JsonValue(r'canceled')
  canceled(r'canceled');

  const CampaignStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
