//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/reward_delta.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'put_analysis_feedback200_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PutAnalysisFeedback200Response {
  /// Returns a new [PutAnalysisFeedback200Response] instance.
  PutAnalysisFeedback200Response({required this.rewards});

  @JsonKey(name: r'rewards', required: true, includeIfNull: false)
  final RewardDelta rewards;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PutAnalysisFeedback200Response && other.rewards == rewards;

  @override
  int get hashCode => rewards.hashCode;

  factory PutAnalysisFeedback200Response.fromJson(Map<String, dynamic> json) =>
      _$PutAnalysisFeedback200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PutAnalysisFeedback200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
