//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'participation_days_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ParticipationDaysInner {
  /// Returns a new [ParticipationDaysInner] instance.
  ParticipationDaysInner({required this.date, required this.status});

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final DateTime date;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final ParticipationDaysInnerStatusEnum status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticipationDaysInner &&
          other.date == date &&
          other.status == status;

  @override
  int get hashCode => date.hashCode + status.hashCode;

  factory ParticipationDaysInner.fromJson(Map<String, dynamic> json) =>
      _$ParticipationDaysInnerFromJson(json);

  Map<String, dynamic> toJson() => _$ParticipationDaysInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ParticipationDaysInnerStatusEnum {
  @JsonValue(r'pending')
  pending(r'pending'),
  @JsonValue(r'success')
  success(r'success'),
  @JsonValue(r'failed')
  failed(r'failed'),
  @JsonValue(r'upcoming')
  upcoming(r'upcoming');

  const ParticipationDaysInnerStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
