//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'home_quick_actions_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HomeQuickActionsInner {
  /// Returns a new [HomeQuickActionsInner] instance.
  HomeQuickActionsInner({
    required this.kind,

    required this.enabled,

    this.lockedReason,

    this.remaining,
  });

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final HomeQuickActionsInnerKindEnum kind;

  @JsonKey(name: r'enabled', required: true, includeIfNull: false)
  final bool enabled;

  @JsonKey(name: r'locked_reason', required: false, includeIfNull: false)
  final HomeQuickActionsInnerLockedReasonEnum? lockedReason;

  @JsonKey(name: r'remaining', required: false, includeIfNull: false)
  final int? remaining;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeQuickActionsInner &&
          other.kind == kind &&
          other.enabled == enabled &&
          other.lockedReason == lockedReason &&
          other.remaining == remaining;

  @override
  int get hashCode =>
      kind.hashCode +
      enabled.hashCode +
      (lockedReason == null ? 0 : lockedReason.hashCode) +
      (remaining == null ? 0 : remaining.hashCode);

  factory HomeQuickActionsInner.fromJson(Map<String, dynamic> json) =>
      _$HomeQuickActionsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$HomeQuickActionsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum HomeQuickActionsInnerKindEnum {
  @JsonValue(r'photo')
  photo(r'photo'),
  @JsonValue(r'voice')
  voice(r'voice'),
  @JsonValue(r'catalog')
  catalog(r'catalog');

  const HomeQuickActionsInnerKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum HomeQuickActionsInnerLockedReasonEnum {
  @JsonValue(r'plan_required')
  planRequired(r'plan_required'),
  @JsonValue(r'quota_exceeded')
  quotaExceeded(r'quota_exceeded');

  const HomeQuickActionsInnerLockedReasonEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
