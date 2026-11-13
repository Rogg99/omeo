//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum Goal {
  @JsonValue(r'lose_weight')
  loseWeight(r'lose_weight'),
  @JsonValue(r'gain_muscle')
  gainMuscle(r'gain_muscle'),
  @JsonValue(r'eat_balanced')
  eatBalanced(r'eat_balanced'),
  @JsonValue(r'prevent_diabetes')
  preventDiabetes(r'prevent_diabetes'),
  @JsonValue(r'prevent_hypertension')
  preventHypertension(r'prevent_hypertension');

  const Goal(this.value);

  final String value;

  @override
  String toString() => value;
}
