//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_user_tip_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateUserTipRequest {
  /// Returns a new [UpdateUserTipRequest] instance.
  UpdateUserTipRequest({this.read, this.dismissed});

  @JsonKey(name: r'read', required: false, includeIfNull: false)
  final bool? read;

  @JsonKey(name: r'dismissed', required: false, includeIfNull: false)
  final bool? dismissed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateUserTipRequest &&
          other.read == read &&
          other.dismissed == dismissed;

  @override
  int get hashCode => read.hashCode + dismissed.hashCode;

  factory UpdateUserTipRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserTipRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateUserTipRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
