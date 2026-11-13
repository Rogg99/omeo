//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'select_analysis_dish_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SelectAnalysisDishRequest {
  /// Returns a new [SelectAnalysisDishRequest] instance.
  SelectAnalysisDishRequest({required this.dishId});

  @JsonKey(name: r'dish_id', required: true, includeIfNull: false)
  final String dishId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectAnalysisDishRequest && other.dishId == dishId;

  @override
  int get hashCode => dishId.hashCode;

  factory SelectAnalysisDishRequest.fromJson(Map<String, dynamic> json) =>
      _$SelectAnalysisDishRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SelectAnalysisDishRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
