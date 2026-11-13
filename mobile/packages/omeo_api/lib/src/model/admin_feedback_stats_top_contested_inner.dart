//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_feedback_stats_top_contested_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminFeedbackStatsTopContestedInner {
  /// Returns a new [AdminFeedbackStatsTopContestedInner] instance.
  AdminFeedbackStatsTopContestedInner({this.dish, this.negatives});

  @JsonKey(name: r'dish', required: false, includeIfNull: false)
  final String? dish;

  @JsonKey(name: r'negatives', required: false, includeIfNull: false)
  final int? negatives;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminFeedbackStatsTopContestedInner &&
          other.dish == dish &&
          other.negatives == negatives;

  @override
  int get hashCode => dish.hashCode + negatives.hashCode;

  factory AdminFeedbackStatsTopContestedInner.fromJson(
    Map<String, dynamic> json,
  ) => _$AdminFeedbackStatsTopContestedInnerFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AdminFeedbackStatsTopContestedInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
