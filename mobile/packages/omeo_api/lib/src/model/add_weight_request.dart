//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'add_weight_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddWeightRequest {
  /// Returns a new [AddWeightRequest] instance.
  AddWeightRequest({required this.weightKg, this.date});

  // minimum: 30
  // maximum: 300
  @JsonKey(name: r'weight_kg', required: true, includeIfNull: false)
  final num weightKg;

  @JsonKey(name: r'date', required: false, includeIfNull: false)
  final DateTime? date;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddWeightRequest &&
          other.weightKg == weightKg &&
          other.date == date;

  @override
  int get hashCode => weightKg.hashCode + date.hashCode;

  factory AddWeightRequest.fromJson(Map<String, dynamic> json) =>
      _$AddWeightRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AddWeightRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
