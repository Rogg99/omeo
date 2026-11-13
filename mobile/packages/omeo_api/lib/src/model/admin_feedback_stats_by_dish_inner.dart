//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_feedback_stats_by_dish_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminFeedbackStatsByDishInner {
  /// Returns a new [AdminFeedbackStatsByDishInner] instance.
  AdminFeedbackStatsByDishInner({
    this.dishId,

    this.dish,

    this.total,

    this.negativeRate,
  });

  @JsonKey(name: r'dish_id', required: false, includeIfNull: false)
  final String? dishId;

  @JsonKey(name: r'dish', required: false, includeIfNull: false)
  final String? dish;

  @JsonKey(name: r'total', required: false, includeIfNull: false)
  final int? total;

  @JsonKey(name: r'negative_rate', required: false, includeIfNull: false)
  final num? negativeRate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminFeedbackStatsByDishInner &&
          other.dishId == dishId &&
          other.dish == dish &&
          other.total == total &&
          other.negativeRate == negativeRate;

  @override
  int get hashCode =>
      dishId.hashCode + dish.hashCode + total.hashCode + negativeRate.hashCode;

  factory AdminFeedbackStatsByDishInner.fromJson(Map<String, dynamic> json) =>
      _$AdminFeedbackStatsByDishInnerFromJson(json);

  Map<String, dynamic> toJson() => _$AdminFeedbackStatsByDishInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
