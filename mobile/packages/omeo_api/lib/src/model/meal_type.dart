//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum MealType {
  @JsonValue(r'breakfast')
  breakfast(r'breakfast'),
  @JsonValue(r'lunch')
  lunch(r'lunch'),
  @JsonValue(r'snack')
  snack(r'snack'),
  @JsonValue(r'dinner')
  dinner(r'dinner');

  const MealType(this.value);

  final String value;

  @override
  String toString() => value;
}
