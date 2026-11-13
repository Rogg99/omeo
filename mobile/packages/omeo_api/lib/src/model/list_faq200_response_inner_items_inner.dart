//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'list_faq200_response_inner_items_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListFaq200ResponseInnerItemsInner {
  /// Returns a new [ListFaq200ResponseInnerItemsInner] instance.
  ListFaq200ResponseInnerItemsInner({
    required this.id,

    required this.question,

    required this.answer,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'question', required: true, includeIfNull: false)
  final String question;

  /// Markdown
  @JsonKey(name: r'answer', required: true, includeIfNull: false)
  final String answer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListFaq200ResponseInnerItemsInner &&
          other.id == id &&
          other.question == question &&
          other.answer == answer;

  @override
  int get hashCode => id.hashCode + question.hashCode + answer.hashCode;

  factory ListFaq200ResponseInnerItemsInner.fromJson(
    Map<String, dynamic> json,
  ) => _$ListFaq200ResponseInnerItemsInnerFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ListFaq200ResponseInnerItemsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
