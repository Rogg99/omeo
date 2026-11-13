//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/feedback_reason.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'feedback_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FeedbackInput {
  /// Returns a new [FeedbackInput] instance.
  FeedbackInput({
    required this.rating,

    this.reason,

    this.correctedDishLabel,

    this.comment,
  });

  @JsonKey(name: r'rating', required: true, includeIfNull: false)
  final FeedbackInputRatingEnum rating;

  @JsonKey(name: r'reason', required: false, includeIfNull: false)
  final FeedbackReason? reason;

  /// Plat réel selon l'utilisateur, attendu quand reason = wrong_dish (nettoyé avant tout usage)
  @JsonKey(name: r'corrected_dish_label', required: false, includeIfNull: false)
  final String? correctedDishLabel;

  @JsonKey(name: r'comment', required: false, includeIfNull: false)
  final String? comment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedbackInput &&
          other.rating == rating &&
          other.reason == reason &&
          other.correctedDishLabel == correctedDishLabel &&
          other.comment == comment;

  @override
  int get hashCode =>
      rating.hashCode +
      reason.hashCode +
      correctedDishLabel.hashCode +
      comment.hashCode;

  factory FeedbackInput.fromJson(Map<String, dynamic> json) =>
      _$FeedbackInputFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum FeedbackInputRatingEnum {
  @JsonValue(r'up')
  up(r'up'),
  @JsonValue(r'down')
  down(r'down');

  const FeedbackInputRatingEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
