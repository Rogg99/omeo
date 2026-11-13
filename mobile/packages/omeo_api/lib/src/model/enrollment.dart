//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/program_day_view.dart';
import 'package:omeo_api/src/model/program_summary.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'enrollment.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Enrollment {
  /// Returns a new [Enrollment] instance.
  Enrollment({
    required this.id,

    required this.program,

    required this.status,

    required this.startedOn,

    required this.dayIndex,

    required this.percent,

    this.assiduityPercent,

    required this.today,

    required this.week,

    this.report,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'program', required: true, includeIfNull: false)
  final ProgramSummary program;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final EnrollmentStatusEnum status;

  @JsonKey(name: r'started_on', required: true, includeIfNull: false)
  final DateTime startedOn;

  @JsonKey(name: r'day_index', required: true, includeIfNull: false)
  final int dayIndex;

  @JsonKey(name: r'percent', required: true, includeIfNull: false)
  final int percent;

  @JsonKey(name: r'assiduity_percent', required: false, includeIfNull: false)
  final int? assiduityPercent;

  @JsonKey(name: r'today', required: true, includeIfNull: false)
  final ProgramDayView today;

  @JsonKey(name: r'week', required: true, includeIfNull: false)
  final List<ProgramDayView> week;

  /// Bilan final (poids, assiduité) si terminé
  @JsonKey(name: r'report', required: false, includeIfNull: false)
  final Object? report;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Enrollment &&
          other.id == id &&
          other.program == program &&
          other.status == status &&
          other.startedOn == startedOn &&
          other.dayIndex == dayIndex &&
          other.percent == percent &&
          other.assiduityPercent == assiduityPercent &&
          other.today == today &&
          other.week == week &&
          other.report == report;

  @override
  int get hashCode =>
      id.hashCode +
      program.hashCode +
      status.hashCode +
      startedOn.hashCode +
      dayIndex.hashCode +
      percent.hashCode +
      assiduityPercent.hashCode +
      today.hashCode +
      week.hashCode +
      (report == null ? 0 : report.hashCode);

  factory Enrollment.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollmentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum EnrollmentStatusEnum {
  @JsonValue(r'active')
  active(r'active'),
  @JsonValue(r'completed')
  completed(r'completed'),
  @JsonValue(r'abandoned')
  abandoned(r'abandoned'),
  @JsonValue(r'replaced')
  replaced(r'replaced');

  const EnrollmentStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
