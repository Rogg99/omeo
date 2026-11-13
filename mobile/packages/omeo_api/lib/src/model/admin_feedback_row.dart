//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/locale.dart';
import 'package:omeo_api/src/model/image.dart';
import 'package:omeo_api/src/model/feedback_reason.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_feedback_row.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminFeedbackRow {
  /// Returns a new [AdminFeedbackRow] instance.
  AdminFeedbackRow({
    required this.id,

    required this.rating,

    this.reason,

    required this.status,

    this.dishLabel,

    this.confidence,

    this.locale,

    this.country,

    this.thumbnail,

    required this.createdAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'rating', required: true, includeIfNull: false)
  final AdminFeedbackRowRatingEnum rating;

  @JsonKey(name: r'reason', required: false, includeIfNull: false)
  final FeedbackReason? reason;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final AdminFeedbackRowStatusEnum status;

  @JsonKey(name: r'dish_label', required: false, includeIfNull: false)
  final String? dishLabel;

  @JsonKey(name: r'confidence', required: false, includeIfNull: false)
  final num? confidence;

  @JsonKey(name: r'locale', required: false, includeIfNull: false)
  final Locale? locale;

  @JsonKey(name: r'country', required: false, includeIfNull: false)
  final String? country;

  @JsonKey(name: r'thumbnail', required: false, includeIfNull: false)
  final Image? thumbnail;

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminFeedbackRow &&
          other.id == id &&
          other.rating == rating &&
          other.reason == reason &&
          other.status == status &&
          other.dishLabel == dishLabel &&
          other.confidence == confidence &&
          other.locale == locale &&
          other.country == country &&
          other.thumbnail == thumbnail &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      id.hashCode +
      rating.hashCode +
      (reason == null ? 0 : reason.hashCode) +
      status.hashCode +
      (dishLabel == null ? 0 : dishLabel.hashCode) +
      (confidence == null ? 0 : confidence.hashCode) +
      locale.hashCode +
      (country == null ? 0 : country.hashCode) +
      (thumbnail == null ? 0 : thumbnail.hashCode) +
      createdAt.hashCode;

  factory AdminFeedbackRow.fromJson(Map<String, dynamic> json) =>
      _$AdminFeedbackRowFromJson(json);

  Map<String, dynamic> toJson() => _$AdminFeedbackRowToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminFeedbackRowRatingEnum {
  @JsonValue(r'up')
  up(r'up'),
  @JsonValue(r'down')
  down(r'down');

  const AdminFeedbackRowRatingEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AdminFeedbackRowStatusEnum {
  @JsonValue(r'new')
  new_(r'new'),
  @JsonValue(r'handled')
  handled(r'handled'),
  @JsonValue(r'ignored')
  ignored(r'ignored');

  const AdminFeedbackRowStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
