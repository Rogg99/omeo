//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'progress_summary_last7_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProgressSummaryLast7Inner {
  /// Returns a new [ProgressSummaryLast7Inner] instance.
  ProgressSummaryLast7Inner({
    required this.date,

    required this.kcal,

    this.status,
  });

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final DateTime date;

  @JsonKey(name: r'kcal', required: true, includeIfNull: false)
  final int kcal;

  @JsonKey(name: r'status', required: false, includeIfNull: false)
  final String? status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressSummaryLast7Inner &&
          other.date == date &&
          other.kcal == kcal &&
          other.status == status;

  @override
  int get hashCode => date.hashCode + kcal.hashCode + status.hashCode;

  factory ProgressSummaryLast7Inner.fromJson(Map<String, dynamic> json) =>
      _$ProgressSummaryLast7InnerFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressSummaryLast7InnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
