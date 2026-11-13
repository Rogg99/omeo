//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/admin_feedback_stats_top_contested_inner.dart';
import 'package:omeo_api/src/model/admin_feedback_stats_by_country_inner.dart';
import 'package:omeo_api/src/model/admin_feedback_stats_by_dish_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_feedback_stats.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminFeedbackStats {
  /// Returns a new [AdminFeedbackStats] instance.
  AdminFeedbackStats({this.byDish, this.byCountry, this.topContested});

  @JsonKey(name: r'by_dish', required: false, includeIfNull: false)
  final List<AdminFeedbackStatsByDishInner>? byDish;

  @JsonKey(name: r'by_country', required: false, includeIfNull: false)
  final List<AdminFeedbackStatsByCountryInner>? byCountry;

  @JsonKey(name: r'top_contested', required: false, includeIfNull: false)
  final List<AdminFeedbackStatsTopContestedInner>? topContested;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminFeedbackStats &&
          other.byDish == byDish &&
          other.byCountry == byCountry &&
          other.topContested == topContested;

  @override
  int get hashCode =>
      byDish.hashCode + byCountry.hashCode + topContested.hashCode;

  factory AdminFeedbackStats.fromJson(Map<String, dynamic> json) =>
      _$AdminFeedbackStatsFromJson(json);

  Map<String, dynamic> toJson() => _$AdminFeedbackStatsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
