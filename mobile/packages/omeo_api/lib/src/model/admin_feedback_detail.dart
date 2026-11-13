//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/analysis_item.dart';
import 'package:omeo_api/src/model/locale.dart';
import 'package:omeo_api/src/model/image.dart';
import 'package:omeo_api/src/model/feedback_reason.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_feedback_detail.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminFeedbackDetail {
  /// Returns a new [AdminFeedbackDetail] instance.
  AdminFeedbackDetail({
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

    this.photo,

    this.inputText,

    this.comment,

    this.model,

    this.promptVersion,

    this.aiRaw,

    this.aiItems,

    this.correctedItems,

    this.handledBy,

    this.handledAction,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'rating', required: true, includeIfNull: false)
  final AdminFeedbackDetailRatingEnum rating;

  @JsonKey(name: r'reason', required: false, includeIfNull: false)
  final FeedbackReason? reason;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final AdminFeedbackDetailStatusEnum status;

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

  @JsonKey(name: r'photo', required: false, includeIfNull: false)
  final Image? photo;

  @JsonKey(name: r'input_text', required: false, includeIfNull: false)
  final String? inputText;

  @JsonKey(name: r'comment', required: false, includeIfNull: false)
  final String? comment;

  @JsonKey(name: r'model', required: false, includeIfNull: false)
  final String? model;

  @JsonKey(name: r'prompt_version', required: false, includeIfNull: false)
  final String? promptVersion;

  @JsonKey(name: r'ai_raw', required: false, includeIfNull: false)
  final Map<String, Object>? aiRaw;

  @JsonKey(name: r'ai_items', required: false, includeIfNull: false)
  final List<AnalysisItem>? aiItems;

  @JsonKey(name: r'corrected_items', required: false, includeIfNull: false)
  final List<AnalysisItem>? correctedItems;

  @JsonKey(name: r'handled_by', required: false, includeIfNull: false)
  final String? handledBy;

  @JsonKey(name: r'handled_action', required: false, includeIfNull: false)
  final String? handledAction;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminFeedbackDetail &&
          other.id == id &&
          other.rating == rating &&
          other.reason == reason &&
          other.status == status &&
          other.dishLabel == dishLabel &&
          other.confidence == confidence &&
          other.locale == locale &&
          other.country == country &&
          other.thumbnail == thumbnail &&
          other.createdAt == createdAt &&
          other.photo == photo &&
          other.inputText == inputText &&
          other.comment == comment &&
          other.model == model &&
          other.promptVersion == promptVersion &&
          other.aiRaw == aiRaw &&
          other.aiItems == aiItems &&
          other.correctedItems == correctedItems &&
          other.handledBy == handledBy &&
          other.handledAction == handledAction;

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
      createdAt.hashCode +
      photo.hashCode +
      (inputText == null ? 0 : inputText.hashCode) +
      (comment == null ? 0 : comment.hashCode) +
      model.hashCode +
      promptVersion.hashCode +
      aiRaw.hashCode +
      aiItems.hashCode +
      correctedItems.hashCode +
      (handledBy == null ? 0 : handledBy.hashCode) +
      (handledAction == null ? 0 : handledAction.hashCode);

  factory AdminFeedbackDetail.fromJson(Map<String, dynamic> json) =>
      _$AdminFeedbackDetailFromJson(json);

  Map<String, dynamic> toJson() => _$AdminFeedbackDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminFeedbackDetailRatingEnum {
  @JsonValue(r'up')
  up(r'up'),
  @JsonValue(r'down')
  down(r'down');

  const AdminFeedbackDetailRatingEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AdminFeedbackDetailStatusEnum {
  @JsonValue(r'new')
  new_(r'new'),
  @JsonValue(r'handled')
  handled(r'handled'),
  @JsonValue(r'ignored')
  ignored(r'ignored');

  const AdminFeedbackDetailStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
