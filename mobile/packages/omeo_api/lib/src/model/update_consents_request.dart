//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/consent_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_consents_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateConsentsRequest {
  /// Returns a new [UpdateConsentsRequest] instance.
  UpdateConsentsRequest({required this.consents});

  @JsonKey(name: r'consents', required: true, includeIfNull: false)
  final List<ConsentInput> consents;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateConsentsRequest && other.consents == consents;

  @override
  int get hashCode => consents.hashCode;

  factory UpdateConsentsRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateConsentsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateConsentsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
