//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/weight_overview.dart';
import 'package:omeo_api/src/model/targets.dart';
import 'package:omeo_api/src/model/reward_delta.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'add_weight201_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddWeight201Response {
  /// Returns a new [AddWeight201Response] instance.
  AddWeight201Response({
    required this.overview,

    required this.targets,

    required this.rewards,
  });

  @JsonKey(name: r'overview', required: true, includeIfNull: false)
  final WeightOverview overview;

  @JsonKey(name: r'targets', required: true, includeIfNull: false)
  final Targets targets;

  @JsonKey(name: r'rewards', required: true, includeIfNull: false)
  final RewardDelta rewards;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddWeight201Response &&
          other.overview == overview &&
          other.targets == targets &&
          other.rewards == rewards;

  @override
  int get hashCode => overview.hashCode + targets.hashCode + rewards.hashCode;

  factory AddWeight201Response.fromJson(Map<String, dynamic> json) =>
      _$AddWeight201ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AddWeight201ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
