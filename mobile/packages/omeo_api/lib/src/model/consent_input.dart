//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/consent_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'consent_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConsentInput {
  /// Returns a new [ConsentInput] instance.
  ConsentInput({required this.kind, required this.granted, this.version});

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final ConsentKind kind;

  @JsonKey(name: r'granted', required: true, includeIfNull: false)
  final bool granted;

  /// Version du document acceptée
  @JsonKey(name: r'version', required: false, includeIfNull: false)
  final int? version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsentInput &&
          other.kind == kind &&
          other.granted == granted &&
          other.version == version;

  @override
  int get hashCode => kind.hashCode + granted.hashCode + version.hashCode;

  factory ConsentInput.fromJson(Map<String, dynamic> json) =>
      _$ConsentInputFromJson(json);

  Map<String, dynamic> toJson() => _$ConsentInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
