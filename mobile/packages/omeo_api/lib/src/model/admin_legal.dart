//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/legal_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_legal.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminLegal {
  /// Returns a new [AdminLegal] instance.
  AdminLegal({required this.kind, required this.body, this.requiresReaccept});

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final LegalKind kind;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'body', required: true, includeIfNull: false)
  final Map<String, String> body;

  @JsonKey(name: r'requires_reaccept', required: false, includeIfNull: false)
  final bool? requiresReaccept;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminLegal &&
          other.kind == kind &&
          other.body == body &&
          other.requiresReaccept == requiresReaccept;

  @override
  int get hashCode => kind.hashCode + body.hashCode + requiresReaccept.hashCode;

  factory AdminLegal.fromJson(Map<String, dynamic> json) =>
      _$AdminLegalFromJson(json);

  Map<String, dynamic> toJson() => _$AdminLegalToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
