//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/consent_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'consent_state.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConsentState {
  /// Returns a new [ConsentState] instance.
  ConsentState({
    required this.kind,

    required this.granted,

    this.version,

    required this.updatedAt,

    this.withdrawable,
  });

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final ConsentKind kind;

  @JsonKey(name: r'granted', required: true, includeIfNull: false)
  final bool granted;

  @JsonKey(name: r'version', required: false, includeIfNull: false)
  final int? version;

  @JsonKey(name: r'updated_at', required: true, includeIfNull: false)
  final DateTime updatedAt;

  /// false pour CGU / confidentialité (retrait = suppression du compte)
  @JsonKey(name: r'withdrawable', required: false, includeIfNull: false)
  final bool? withdrawable;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsentState &&
          other.kind == kind &&
          other.granted == granted &&
          other.version == version &&
          other.updatedAt == updatedAt &&
          other.withdrawable == withdrawable;

  @override
  int get hashCode =>
      kind.hashCode +
      granted.hashCode +
      (version == null ? 0 : version.hashCode) +
      updatedAt.hashCode +
      withdrawable.hashCode;

  factory ConsentState.fromJson(Map<String, dynamic> json) =>
      _$ConsentStateFromJson(json);

  Map<String, dynamic> toJson() => _$ConsentStateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
