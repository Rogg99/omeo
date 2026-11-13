//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'merge_activity_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MergeActivityRequest {
  /// Returns a new [MergeActivityRequest] instance.
  MergeActivityRequest({required this.intoId});

  @JsonKey(name: r'into_id', required: true, includeIfNull: false)
  final String intoId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MergeActivityRequest && other.intoId == intoId;

  @override
  int get hashCode => intoId.hashCode;

  factory MergeActivityRequest.fromJson(Map<String, dynamic> json) =>
      _$MergeActivityRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MergeActivityRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
