//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/gauge.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'water.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Water {
  /// Returns a new [Water] instance.
  Water({required this.date, required this.gauge, required this.quickAddMl});

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final DateTime date;

  @JsonKey(name: r'gauge', required: true, includeIfNull: false)
  final Gauge gauge;

  @JsonKey(name: r'quick_add_ml', required: true, includeIfNull: false)
  final List<int> quickAddMl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Water &&
          other.date == date &&
          other.gauge == gauge &&
          other.quickAddMl == quickAddMl;

  @override
  int get hashCode => date.hashCode + gauge.hashCode + quickAddMl.hashCode;

  factory Water.fromJson(Map<String, dynamic> json) => _$WaterFromJson(json);

  Map<String, dynamic> toJson() => _$WaterToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
