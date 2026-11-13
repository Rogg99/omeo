//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_feedback_stats_by_country_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminFeedbackStatsByCountryInner {
  /// Returns a new [AdminFeedbackStatsByCountryInner] instance.
  AdminFeedbackStatsByCountryInner({
    this.country,

    this.total,

    this.negativeRate,
  });

  @JsonKey(name: r'country', required: false, includeIfNull: false)
  final String? country;

  @JsonKey(name: r'total', required: false, includeIfNull: false)
  final int? total;

  @JsonKey(name: r'negative_rate', required: false, includeIfNull: false)
  final num? negativeRate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminFeedbackStatsByCountryInner &&
          other.country == country &&
          other.total == total &&
          other.negativeRate == negativeRate;

  @override
  int get hashCode => country.hashCode + total.hashCode + negativeRate.hashCode;

  factory AdminFeedbackStatsByCountryInner.fromJson(
    Map<String, dynamic> json,
  ) => _$AdminFeedbackStatsByCountryInnerFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AdminFeedbackStatsByCountryInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
