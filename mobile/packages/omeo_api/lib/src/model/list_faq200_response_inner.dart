//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/list_faq200_response_inner_items_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'list_faq200_response_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListFaq200ResponseInner {
  /// Returns a new [ListFaq200ResponseInner] instance.
  ListFaq200ResponseInner({required this.category, required this.items});

  @JsonKey(name: r'category', required: true, includeIfNull: false)
  final String category;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<ListFaq200ResponseInnerItemsInner> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListFaq200ResponseInner &&
          other.category == category &&
          other.items == items;

  @override
  int get hashCode => category.hashCode + items.hashCode;

  factory ListFaq200ResponseInner.fromJson(Map<String, dynamic> json) =>
      _$ListFaq200ResponseInnerFromJson(json);

  Map<String, dynamic> toJson() => _$ListFaq200ResponseInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
