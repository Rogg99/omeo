//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/water.dart';
import 'package:omeo_api/src/model/reward_delta.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'add_water201_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddWater201Response {
  /// Returns a new [AddWater201Response] instance.
  AddWater201Response({required this.water, required this.rewards});

  @JsonKey(name: r'water', required: true, includeIfNull: false)
  final Water water;

  @JsonKey(name: r'rewards', required: true, includeIfNull: false)
  final RewardDelta rewards;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddWater201Response &&
          other.water == water &&
          other.rewards == rewards;

  @override
  int get hashCode => water.hashCode + rewards.hashCode;

  factory AddWater201Response.fromJson(Map<String, dynamic> json) =>
      _$AddWater201ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AddWater201ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
