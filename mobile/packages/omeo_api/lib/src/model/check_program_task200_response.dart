//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/enrollment.dart';
import 'package:omeo_api/src/model/reward_delta.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'check_program_task200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CheckProgramTask200Response {
  /// Returns a new [CheckProgramTask200Response] instance.
  CheckProgramTask200Response({
    required this.enrollment,

    required this.rewards,
  });

  @JsonKey(name: r'enrollment', required: true, includeIfNull: false)
  final Enrollment enrollment;

  @JsonKey(name: r'rewards', required: true, includeIfNull: false)
  final RewardDelta rewards;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckProgramTask200Response &&
          other.enrollment == enrollment &&
          other.rewards == rewards;

  @override
  int get hashCode => enrollment.hashCode + rewards.hashCode;

  factory CheckProgramTask200Response.fromJson(Map<String, dynamic> json) =>
      _$CheckProgramTask200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CheckProgramTask200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
