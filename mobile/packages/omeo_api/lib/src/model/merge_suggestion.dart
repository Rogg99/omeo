//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'merge_suggestion.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MergeSuggestion {
  /// Returns a new [MergeSuggestion] instance.
  MergeSuggestion({
    required this.manualId,

    required this.importedId,

    this.message,
  });

  @JsonKey(name: r'manual_id', required: true, includeIfNull: false)
  final String manualId;

  @JsonKey(name: r'imported_id', required: true, includeIfNull: false)
  final String importedId;

  @JsonKey(name: r'message', required: false, includeIfNull: false)
  final String? message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MergeSuggestion &&
          other.manualId == manualId &&
          other.importedId == importedId &&
          other.message == message;

  @override
  int get hashCode =>
      manualId.hashCode + importedId.hashCode + message.hashCode;

  factory MergeSuggestion.fromJson(Map<String, dynamic> json) =>
      _$MergeSuggestionFromJson(json);

  Map<String, dynamic> toJson() => _$MergeSuggestionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
