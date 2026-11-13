//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:omeo_api/src/model/rewards_summary.dart';
import 'package:omeo_api/src/model/week_day.dart';
import 'package:omeo_api/src/model/home_quick_actions_inner.dart';
import 'package:omeo_api/src/model/program_today.dart';
import 'package:omeo_api/src/model/day_summary.dart';
import 'package:omeo_api/src/model/challenge_today.dart';
import 'package:omeo_api/src/model/insight.dart';
import 'package:omeo_api/src/model/home_banners_inner.dart';
import 'package:omeo_api/src/model/user_tip.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'home.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Home {
  /// Returns a new [Home] instance.
  Home({
    required this.greeting,

    required this.date,

    required this.week,

    required this.day,

    required this.quickActions,

    this.activeProgram,

    this.activeChallenges,

    required this.shortcuts,

    required this.rewards,

    this.insight,

    this.tip,

    this.banners,
  });

  @JsonKey(name: r'greeting', required: true, includeIfNull: false)
  final String greeting;

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final DateTime date;

  @JsonKey(name: r'week', required: true, includeIfNull: false)
  final List<WeekDay> week;

  @JsonKey(name: r'day', required: true, includeIfNull: false)
  final DaySummary day;

  @JsonKey(name: r'quick_actions', required: true, includeIfNull: false)
  final List<HomeQuickActionsInner> quickActions;

  @JsonKey(name: r'active_program', required: false, includeIfNull: false)
  final ProgramToday? activeProgram;

  @JsonKey(name: r'active_challenges', required: false, includeIfNull: false)
  final List<ChallengeToday>? activeChallenges;

  @JsonKey(name: r'shortcuts', required: true, includeIfNull: false)
  final List<HomeShortcutsEnum> shortcuts;

  @JsonKey(name: r'rewards', required: true, includeIfNull: false)
  final RewardsSummary rewards;

  @JsonKey(name: r'insight', required: false, includeIfNull: false)
  final Insight? insight;

  @JsonKey(name: r'tip', required: false, includeIfNull: false)
  final UserTip? tip;

  @JsonKey(name: r'banners', required: false, includeIfNull: false)
  final List<HomeBannersInner>? banners;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Home &&
          other.greeting == greeting &&
          other.date == date &&
          other.week == week &&
          other.day == day &&
          other.quickActions == quickActions &&
          other.activeProgram == activeProgram &&
          other.activeChallenges == activeChallenges &&
          other.shortcuts == shortcuts &&
          other.rewards == rewards &&
          other.insight == insight &&
          other.tip == tip &&
          other.banners == banners;

  @override
  int get hashCode =>
      greeting.hashCode +
      date.hashCode +
      week.hashCode +
      day.hashCode +
      quickActions.hashCode +
      (activeProgram == null ? 0 : activeProgram.hashCode) +
      activeChallenges.hashCode +
      shortcuts.hashCode +
      rewards.hashCode +
      (insight == null ? 0 : insight.hashCode) +
      (tip == null ? 0 : tip.hashCode) +
      banners.hashCode;

  factory Home.fromJson(Map<String, dynamic> json) => _$HomeFromJson(json);

  Map<String, dynamic> toJson() => _$HomeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum HomeShortcutsEnum {
  @JsonValue(r'nutrition')
  nutrition(r'nutrition'),
  @JsonValue(r'sport')
  sport(r'sport'),
  @JsonValue(r'recipes')
  recipes(r'recipes'),
  @JsonValue(r'plants')
  plants(r'plants');

  const HomeShortcutsEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
