//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'page_meta.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PageMeta {
  /// Returns a new [PageMeta] instance.
  PageMeta({
    required this.results,

    required this.count,

    required this.page,

    required this.pageSize,
  });

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<Object> results;

  @JsonKey(name: r'count', required: true, includeIfNull: false)
  final int count;

  @JsonKey(name: r'page', required: true, includeIfNull: false)
  final int page;

  @JsonKey(name: r'page_size', required: true, includeIfNull: false)
  final int pageSize;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageMeta &&
          other.results == results &&
          other.count == count &&
          other.page == page &&
          other.pageSize == pageSize;

  @override
  int get hashCode =>
      results.hashCode + count.hashCode + page.hashCode + pageSize.hashCode;

  factory PageMeta.fromJson(Map<String, dynamic> json) =>
      _$PageMetaFromJson(json);

  Map<String, dynamic> toJson() => _$PageMetaToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
