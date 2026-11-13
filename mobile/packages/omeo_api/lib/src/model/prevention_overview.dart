//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/user_tip.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'prevention_overview.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PreventionOverview {
  /// Returns a new [PreventionOverview] instance.
  PreventionOverview({
    required this.state,

    required this.tips,

    this.weeklyReport,

    this.weeklyReportLocked,
  });

  @JsonKey(name: r'state', required: true, includeIfNull: false)
  final PreventionOverviewStateEnum state;

  @JsonKey(name: r'tips', required: true, includeIfNull: false)
  final List<UserTip> tips;

  /// Plus uniquement
  @JsonKey(name: r'weekly_report', required: false, includeIfNull: false)
  final Map<String, Object>? weeklyReport;

  @JsonKey(name: r'weekly_report_locked', required: false, includeIfNull: false)
  final bool? weeklyReportLocked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreventionOverview &&
          other.state == state &&
          other.tips == tips &&
          other.weeklyReport == weeklyReport &&
          other.weeklyReportLocked == weeklyReportLocked;

  @override
  int get hashCode =>
      state.hashCode +
      tips.hashCode +
      (weeklyReport == null ? 0 : weeklyReport.hashCode) +
      weeklyReportLocked.hashCode;

  factory PreventionOverview.fromJson(Map<String, dynamic> json) =>
      _$PreventionOverviewFromJson(json);

  Map<String, dynamic> toJson() => _$PreventionOverviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PreventionOverviewStateEnum {
  @JsonValue(r'not_enough_data')
  notEnoughData(r'not_enough_data'),
  @JsonValue(r'ok')
  ok(r'ok');

  const PreventionOverviewStateEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
