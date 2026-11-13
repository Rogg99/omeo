//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'point_event.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PointEvent {
  /// Returns a new [PointEvent] instance.
  PointEvent({
    required this.id,

    this.action,

    required this.label,

    required this.points,

    required this.date,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'action', required: false, includeIfNull: false)
  final String? action;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'points', required: true, includeIfNull: false)
  final int points;

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointEvent &&
          other.id == id &&
          other.action == action &&
          other.label == label &&
          other.points == points &&
          other.date == date;

  @override
  int get hashCode =>
      id.hashCode +
      action.hashCode +
      label.hashCode +
      points.hashCode +
      date.hashCode;

  factory PointEvent.fromJson(Map<String, dynamic> json) =>
      _$PointEventFromJson(json);

  Map<String, dynamic> toJson() => _$PointEventToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
