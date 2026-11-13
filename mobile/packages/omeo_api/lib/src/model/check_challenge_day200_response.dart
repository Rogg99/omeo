//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/participation.dart';
import 'package:omeo_api/src/model/reward_delta.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'check_challenge_day200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CheckChallengeDay200Response {
  /// Returns a new [CheckChallengeDay200Response] instance.
  CheckChallengeDay200Response({
    required this.participation,

    required this.rewards,
  });

  @JsonKey(name: r'participation', required: true, includeIfNull: false)
  final Participation participation;

  @JsonKey(name: r'rewards', required: true, includeIfNull: false)
  final RewardDelta rewards;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckChallengeDay200Response &&
          other.participation == participation &&
          other.rewards == rewards;

  @override
  int get hashCode => participation.hashCode + rewards.hashCode;

  factory CheckChallengeDay200Response.fromJson(Map<String, dynamic> json) =>
      _$CheckChallengeDay200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CheckChallengeDay200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
