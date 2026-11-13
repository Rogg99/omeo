//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_ai.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SettingsAi {
  /// Returns a new [SettingsAi] instance.
  SettingsAi({
    this.visionModel,

    this.textModel,

    this.translationModel,

    this.promptVersion,

    this.systemPrompt,

    this.lowConfidenceThreshold,

    this.monthlyBudgetUsd,
  });

  @JsonKey(name: r'vision_model', required: false, includeIfNull: false)
  final String? visionModel;

  @JsonKey(name: r'text_model', required: false, includeIfNull: false)
  final String? textModel;

  @JsonKey(name: r'translation_model', required: false, includeIfNull: false)
  final String? translationModel;

  @JsonKey(name: r'prompt_version', required: false, includeIfNull: false)
  final String? promptVersion;

  @JsonKey(name: r'system_prompt', required: false, includeIfNull: false)
  final String? systemPrompt;

  @JsonKey(
    name: r'low_confidence_threshold',
    required: false,
    includeIfNull: false,
  )
  final num? lowConfidenceThreshold;

  @JsonKey(name: r'monthly_budget_usd', required: false, includeIfNull: false)
  final num? monthlyBudgetUsd;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsAi &&
          other.visionModel == visionModel &&
          other.textModel == textModel &&
          other.translationModel == translationModel &&
          other.promptVersion == promptVersion &&
          other.systemPrompt == systemPrompt &&
          other.lowConfidenceThreshold == lowConfidenceThreshold &&
          other.monthlyBudgetUsd == monthlyBudgetUsd;

  @override
  int get hashCode =>
      visionModel.hashCode +
      textModel.hashCode +
      translationModel.hashCode +
      promptVersion.hashCode +
      systemPrompt.hashCode +
      lowConfidenceThreshold.hashCode +
      monthlyBudgetUsd.hashCode;

  factory SettingsAi.fromJson(Map<String, dynamic> json) =>
      _$SettingsAiFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsAiToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
