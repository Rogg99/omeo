//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'check_challenge_day_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CheckChallengeDayRequest {
  /// Returns a new [CheckChallengeDayRequest] instance.
  CheckChallengeDayRequest({required this.done});

  @JsonKey(name: r'done', required: true, includeIfNull: false)
  final bool done;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckChallengeDayRequest && other.done == done;

  @override
  int get hashCode => done.hashCode;

  factory CheckChallengeDayRequest.fromJson(Map<String, dynamic> json) =>
      _$CheckChallengeDayRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CheckChallengeDayRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
