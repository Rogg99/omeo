//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_faq.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminFaq {
  /// Returns a new [AdminFaq] instance.
  AdminFaq({
    required this.category,

    required this.question,

    required this.answer,

    this.order,

    this.audience,
  });

  @JsonKey(name: r'category', required: true, includeIfNull: false)
  final String category;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'question', required: true, includeIfNull: false)
  final Map<String, String> question;

  /// Admin uniquement. Clés = codes de langue.
  @JsonKey(name: r'answer', required: true, includeIfNull: false)
  final Map<String, String> answer;

  @JsonKey(name: r'order', required: false, includeIfNull: false)
  final int? order;

  @JsonKey(name: r'audience', required: false, includeIfNull: false)
  final AdminFaqAudienceEnum? audience;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminFaq &&
          other.category == category &&
          other.question == question &&
          other.answer == answer &&
          other.order == order &&
          other.audience == audience;

  @override
  int get hashCode =>
      category.hashCode +
      question.hashCode +
      answer.hashCode +
      order.hashCode +
      audience.hashCode;

  factory AdminFaq.fromJson(Map<String, dynamic> json) =>
      _$AdminFaqFromJson(json);

  Map<String, dynamic> toJson() => _$AdminFaqToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminFaqAudienceEnum {
  @JsonValue(r'app')
  app(r'app'),
  @JsonValue(r'web')
  web(r'web'),
  @JsonValue(r'both')
  both(r'both');

  const AdminFaqAudienceEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
