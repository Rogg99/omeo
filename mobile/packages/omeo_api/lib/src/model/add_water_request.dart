//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'add_water_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddWaterRequest {
  /// Returns a new [AddWaterRequest] instance.
  AddWaterRequest({required this.amountMl, this.date});

  // minimum: -2000
  // maximum: 3000
  @JsonKey(name: r'amount_ml', required: true, includeIfNull: false)
  final int amountMl;

  /// Défaut : aujourd'hui (local)
  @JsonKey(name: r'date', required: false, includeIfNull: false)
  final DateTime? date;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddWaterRequest &&
          other.amountMl == amountMl &&
          other.date == date;

  @override
  int get hashCode => amountMl.hashCode + date.hashCode;

  factory AddWaterRequest.fromJson(Map<String, dynamic> json) =>
      _$AddWaterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AddWaterRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
