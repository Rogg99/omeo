//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'problem_errors_value_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProblemErrorsValueInner {
  /// Returns a new [ProblemErrorsValueInner] instance.
  ProblemErrorsValueInner({required this.code, required this.message});

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'message', required: true, includeIfNull: false)
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProblemErrorsValueInner &&
          other.code == code &&
          other.message == message;

  @override
  int get hashCode => code.hashCode + message.hashCode;

  factory ProblemErrorsValueInner.fromJson(Map<String, dynamic> json) =>
      _$ProblemErrorsValueInnerFromJson(json);

  Map<String, dynamic> toJson() => _$ProblemErrorsValueInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
