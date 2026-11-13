//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/locale.dart';
import 'package:omeo_api/src/model/goal.dart';
import 'package:omeo_api/src/model/plan_tier.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'segment.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Segment {
  /// Returns a new [Segment] instance.
  Segment({
    this.locales,

    this.countries,

    this.tiers,

    this.goals,

    this.inactiveDaysMin,
  });

  @JsonKey(name: r'locales', required: false, includeIfNull: false)
  final List<Locale>? locales;

  @JsonKey(name: r'countries', required: false, includeIfNull: false)
  final List<String>? countries;

  @JsonKey(name: r'tiers', required: false, includeIfNull: false)
  final List<PlanTier>? tiers;

  @JsonKey(name: r'goals', required: false, includeIfNull: false)
  final List<Goal>? goals;

  @JsonKey(name: r'inactive_days_min', required: false, includeIfNull: false)
  final int? inactiveDaysMin;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Segment &&
          other.locales == locales &&
          other.countries == countries &&
          other.tiers == tiers &&
          other.goals == goals &&
          other.inactiveDaysMin == inactiveDaysMin;

  @override
  int get hashCode =>
      locales.hashCode +
      countries.hashCode +
      tiers.hashCode +
      goals.hashCode +
      (inactiveDaysMin == null ? 0 : inactiveDaysMin.hashCode);

  factory Segment.fromJson(Map<String, dynamic> json) =>
      _$SegmentFromJson(json);

  Map<String, dynamic> toJson() => _$SegmentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
