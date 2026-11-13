//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_health_connection_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetHealthConnectionRequest {
  /// Returns a new [SetHealthConnectionRequest] instance.
  SetHealthConnectionRequest({
    required this.source_,

    required this.grantedTypes,
  });

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final SetHealthConnectionRequestSource_Enum source_;

  @JsonKey(name: r'granted_types', required: true, includeIfNull: false)
  final List<SetHealthConnectionRequestGrantedTypesEnum> grantedTypes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetHealthConnectionRequest &&
          other.source_ == source_ &&
          other.grantedTypes == grantedTypes;

  @override
  int get hashCode => source_.hashCode + grantedTypes.hashCode;

  factory SetHealthConnectionRequest.fromJson(Map<String, dynamic> json) =>
      _$SetHealthConnectionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetHealthConnectionRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum SetHealthConnectionRequestSource_Enum {
  @JsonValue(r'health_connect')
  healthConnect(r'health_connect'),
  @JsonValue(r'apple_health')
  appleHealth(r'apple_health');

  const SetHealthConnectionRequestSource_Enum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum SetHealthConnectionRequestGrantedTypesEnum {
  @JsonValue(r'steps')
  steps(r'steps'),
  @JsonValue(r'distance')
  distance(r'distance'),
  @JsonValue(r'active_calories')
  activeCalories(r'active_calories'),
  @JsonValue(r'workouts')
  workouts(r'workouts'),
  @JsonValue(r'weight')
  weight(r'weight'),
  @JsonValue(r'heart_rate')
  heartRate(r'heart_rate');

  const SetHealthConnectionRequestGrantedTypesEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
