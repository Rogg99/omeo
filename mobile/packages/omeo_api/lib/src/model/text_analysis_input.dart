//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'text_analysis_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TextAnalysisInput {
  /// Returns a new [TextAnalysisInput] instance.
  TextAnalysisInput({required this.kind, required this.text});

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final TextAnalysisInputKindEnum kind;

  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextAnalysisInput && other.kind == kind && other.text == text;

  @override
  int get hashCode => kind.hashCode + text.hashCode;

  factory TextAnalysisInput.fromJson(Map<String, dynamic> json) =>
      _$TextAnalysisInputFromJson(json);

  Map<String, dynamic> toJson() => _$TextAnalysisInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum TextAnalysisInputKindEnum {
  @JsonValue(r'text')
  text(r'text');

  const TextAnalysisInputKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
