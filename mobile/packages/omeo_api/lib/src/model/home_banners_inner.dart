//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'home_banners_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HomeBannersInner {
  /// Returns a new [HomeBannersInner] instance.
  HomeBannersInner({required this.kind, this.message, this.action});

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final HomeBannersInnerKindEnum kind;

  @JsonKey(name: r'message', required: false, includeIfNull: false)
  final String? message;

  @JsonKey(name: r'action', required: false, includeIfNull: false)
  final String? action;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeBannersInner &&
          other.kind == kind &&
          other.message == message &&
          other.action == action;

  @override
  int get hashCode => kind.hashCode + message.hashCode + action.hashCode;

  factory HomeBannersInner.fromJson(Map<String, dynamic> json) =>
      _$HomeBannersInnerFromJson(json);

  Map<String, dynamic> toJson() => _$HomeBannersInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum HomeBannersInnerKindEnum {
  @JsonValue(r'verify_email')
  verifyEmail(r'verify_email'),
  @JsonValue(r'trial_ending')
  trialEnding(r'trial_ending'),
  @JsonValue(r'reaccept_terms')
  reacceptTerms(r'reaccept_terms'),
  @JsonValue(r'connect_health')
  connectHealth(r'connect_health'),
  @JsonValue(r'quota_low')
  quotaLow(r'quota_low');

  const HomeBannersInnerKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
