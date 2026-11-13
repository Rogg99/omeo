//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/challenge_summary.dart';
import 'package:omeo_api/src/model/challenge_today.dart';
import 'package:omeo_api/src/model/participation_days_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'participation.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Participation {
  /// Returns a new [Participation] instance.
  Participation({
    required this.id,

    required this.challenge,

    required this.status,

    required this.startedOn,

    this.endsOn,

    required this.successRatePercent,

    required this.streak,

    this.today,

    required this.days,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'challenge', required: true, includeIfNull: false)
  final ChallengeSummary challenge;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final ParticipationStatusEnum status;

  @JsonKey(name: r'started_on', required: true, includeIfNull: false)
  final DateTime startedOn;

  @JsonKey(name: r'ends_on', required: false, includeIfNull: false)
  final DateTime? endsOn;

  @JsonKey(name: r'success_rate_percent', required: true, includeIfNull: false)
  final int successRatePercent;

  @JsonKey(name: r'streak', required: true, includeIfNull: false)
  final int streak;

  @JsonKey(name: r'today', required: false, includeIfNull: false)
  final ChallengeToday? today;

  @JsonKey(name: r'days', required: true, includeIfNull: false)
  final List<ParticipationDaysInner> days;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Participation &&
          other.id == id &&
          other.challenge == challenge &&
          other.status == status &&
          other.startedOn == startedOn &&
          other.endsOn == endsOn &&
          other.successRatePercent == successRatePercent &&
          other.streak == streak &&
          other.today == today &&
          other.days == days;

  @override
  int get hashCode =>
      id.hashCode +
      challenge.hashCode +
      status.hashCode +
      startedOn.hashCode +
      endsOn.hashCode +
      successRatePercent.hashCode +
      streak.hashCode +
      today.hashCode +
      days.hashCode;

  factory Participation.fromJson(Map<String, dynamic> json) =>
      _$ParticipationFromJson(json);

  Map<String, dynamic> toJson() => _$ParticipationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ParticipationStatusEnum {
  @JsonValue(r'active')
  active(r'active'),
  @JsonValue(r'succeeded')
  succeeded(r'succeeded'),
  @JsonValue(r'failed')
  failed(r'failed'),
  @JsonValue(r'abandoned')
  abandoned(r'abandoned');

  const ParticipationStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
