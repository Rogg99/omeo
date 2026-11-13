//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cursor_page.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CursorPage {
  /// Returns a new [CursorPage] instance.
  CursorPage({required this.results, required this.nextCursor});

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<Object> results;

  @JsonKey(name: r'next_cursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CursorPage &&
          other.results == results &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      results.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory CursorPage.fromJson(Map<String, dynamic> json) =>
      _$CursorPageFromJson(json);

  Map<String, dynamic> toJson() => _$CursorPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
