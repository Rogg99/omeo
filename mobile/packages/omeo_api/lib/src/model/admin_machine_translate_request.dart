//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/locale.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_machine_translate_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminMachineTranslateRequest {
  /// Returns a new [AdminMachineTranslateRequest] instance.
  AdminMachineTranslateRequest({required this.locales});

  @JsonKey(name: r'locales', required: true, includeIfNull: false)
  final List<Locale> locales;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminMachineTranslateRequest && other.locales == locales;

  @override
  int get hashCode => locales.hashCode;

  factory AdminMachineTranslateRequest.fromJson(Map<String, dynamic> json) =>
      _$AdminMachineTranslateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdminMachineTranslateRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
