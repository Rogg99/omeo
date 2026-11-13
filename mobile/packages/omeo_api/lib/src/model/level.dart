//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum Level {
  @JsonValue(r'beginner')
  beginner(r'beginner'),
  @JsonValue(r'intermediate')
  intermediate(r'intermediate'),
  @JsonValue(r'advanced')
  advanced(r'advanced');

  const Level(this.value);

  final String value;

  @override
  String toString() => value;
}
