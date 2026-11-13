//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'get_calendar200_response_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GetCalendar200ResponseInner {
  /// Returns a new [GetCalendar200ResponseInner] instance.
  GetCalendar200ResponseInner({required this.date, required this.status});

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final DateTime date;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final GetCalendar200ResponseInnerStatusEnum status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetCalendar200ResponseInner &&
          other.date == date &&
          other.status == status;

  @override
  int get hashCode => date.hashCode + status.hashCode;

  factory GetCalendar200ResponseInner.fromJson(Map<String, dynamic> json) =>
      _$GetCalendar200ResponseInnerFromJson(json);

  Map<String, dynamic> toJson() => _$GetCalendar200ResponseInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum GetCalendar200ResponseInnerStatusEnum {
  @JsonValue(r'empty')
  empty(r'empty'),
  @JsonValue(r'partial')
  partial(r'partial'),
  @JsonValue(r'on_target')
  onTarget(r'on_target'),
  @JsonValue(r'over')
  over(r'over'),
  @JsonValue(r'under')
  under(r'under');

  const GetCalendar200ResponseInnerStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
