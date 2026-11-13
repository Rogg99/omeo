//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_estimate_audience200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminEstimateAudience200Response {
  /// Returns a new [AdminEstimateAudience200Response] instance.
  AdminEstimateAudience200Response({required this.count});

  @JsonKey(name: r'count', required: true, includeIfNull: false)
  final int count;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminEstimateAudience200Response && other.count == count;

  @override
  int get hashCode => count.hashCode;

  factory AdminEstimateAudience200Response.fromJson(
    Map<String, dynamic> json,
  ) => _$AdminEstimateAudience200ResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AdminEstimateAudience200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
