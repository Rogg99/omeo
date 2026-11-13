//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum FeedbackReason {
  @JsonValue(r'wrong_dish')
  wrongDish(r'wrong_dish'),
  @JsonValue(r'missing_ingredient')
  missingIngredient(r'missing_ingredient'),
  @JsonValue(r'wrong_quantities')
  wrongQuantities(r'wrong_quantities'),
  @JsonValue(r'other')
  other(r'other');

  const FeedbackReason(this.value);

  final String value;

  @override
  String toString() => value;
}
