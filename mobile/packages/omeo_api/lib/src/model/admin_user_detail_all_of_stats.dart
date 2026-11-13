//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_user_detail_all_of_stats.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminUserDetailAllOfStats {
  /// Returns a new [AdminUserDetailAllOfStats] instance.
  AdminUserDetailAllOfStats({
    this.meals,

    this.analyses,

    this.streak,

    this.points,
  });

  @JsonKey(name: r'meals', required: false, includeIfNull: false)
  final int? meals;

  @JsonKey(name: r'analyses', required: false, includeIfNull: false)
  final int? analyses;

  @JsonKey(name: r'streak', required: false, includeIfNull: false)
  final int? streak;

  @JsonKey(name: r'points', required: false, includeIfNull: false)
  final int? points;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUserDetailAllOfStats &&
          other.meals == meals &&
          other.analyses == analyses &&
          other.streak == streak &&
          other.points == points;

  @override
  int get hashCode =>
      meals.hashCode + analyses.hashCode + streak.hashCode + points.hashCode;

  factory AdminUserDetailAllOfStats.fromJson(Map<String, dynamic> json) =>
      _$AdminUserDetailAllOfStatsFromJson(json);

  Map<String, dynamic> toJson() => _$AdminUserDetailAllOfStatsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
