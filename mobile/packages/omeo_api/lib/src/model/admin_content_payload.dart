//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/admin_content_payload_data.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_content_payload.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminContentPayload {
  /// Returns a new [AdminContentPayload] instance.
  AdminContentPayload({this.version, required this.data});

  /// Verrou optimiste (requis en PATCH)
  @JsonKey(name: r'version', required: false, includeIfNull: false)
  final int? version;

  @JsonKey(name: r'data', required: true, includeIfNull: false)
  final AdminContentPayloadData data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminContentPayload &&
          other.version == version &&
          other.data == data;

  @override
  int get hashCode => version.hashCode + data.hashCode;

  factory AdminContentPayload.fromJson(Map<String, dynamic> json) =>
      _$AdminContentPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$AdminContentPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
