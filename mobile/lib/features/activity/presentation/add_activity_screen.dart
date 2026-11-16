import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/l10n/error_messages.dart';
import 'package:omeo/core/l10n/formatters.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/activity/application/activity_controller.dart';
import 'package:omeo/features/activity/presentation/sport_screen.dart';
import 'package:omeo_api/omeo_api.dart'
    show
        ActivityInput,
        ActivityInputIntensityEnum,
        ActivityInputTypeEnum,
        ActivityWriteResult;

/// Pas de réglage de la durée, en minutes.
const _durationStep = 5;
const _minDuration = 5;
const _maxDuration = 600;

/// Ajouter une activité (SPO-02) : secours quand rien n'est importé.
/// Activité, durée, intensité et moment ; l'API estime les calories.
class AddActivityScreen extends ConsumerStatefulWidget {
  const AddActivityScreen({
    required this.onClose,
    required this.onSaved,
    super.key,
  });

  final VoidCallback onClose;
  final ValueChanged<ActivityWriteResult> onSaved;

  @override
  ConsumerState<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends ConsumerState<AddActivityScreen> {
  ActivityInputTypeEnum? _type;
  int _minutes = 30;
  ActivityInputIntensityEnum _intensity = ActivityInputIntensityEnum.moderate;
  DateTime? _startedAt;
  bool _saving = false;

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startedAt ?? now),
    );
    if (picked == null) return;
    setState(
      () => _startedAt = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      ),
    );
  }

  Future<void> _save(ActivityInputTypeEnum type) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(activityActionsProvider)
          .add(
            ActivityInput(
              type: type,
              durationS: _minutes * 60,
              intensity: _intensity,
              startedAt: (_startedAt ?? DateTime.now()).toUtc(),
            ),
          );
      unawaited(HapticFeedback.mediumImpact());
      messenger.showSnackBar(
        SnackBar(content: Text(l.appActivitySaved(result.activity.kcal))),
      );
      widget.onSaved(result);
    } on ApiFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage(l, e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final type = _type;
    final started = _startedAt;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OmeoTopBar(
              title: l.appActivityAdd,
              backLabel: l.commonActionClose,
              close: true,
              onBack: widget.onClose,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Eyebrow(l.appActivityAddActivity),
                  const SizedBox(height: OmeoTokens.space2),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.95,
                    children: [
                      for (final ty in ActivityInputTypeEnum.values)
                        _TypeTile(
                          icon: ty == ActivityInputTypeEnum.other
                              ? OmeoIcons.moreH
                              : activityIcon(ty.value),
                          label: l.appActivityType(ty.value),
                          selected: ty == type,
                          onTap: () => setState(() => _type = ty),
                        ),
                    ],
                  ),
                  const SizedBox(height: OmeoTokens.space6),
                  Eyebrow(l.appActivityDuration),
                  const SizedBox(height: OmeoTokens.space2),
                  Row(
                    children: [
                      OmeoIconButton(
                        icon: OmeoIcons.minus,
                        semanticLabel: l.appActivityLess,
                        onPressed: _minutes > _minDuration
                            ? () => setState(() => _minutes -= _durationStep)
                            : null,
                      ),
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: context.number(_minutes),
                                  style: text.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${l.appActivityMinUnit}',
                                  style: TextStyle(color: t.text3),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      OmeoIconButton(
                        icon: OmeoIcons.plus,
                        semanticLabel: l.appActivityMore,
                        onPressed: _minutes < _maxDuration
                            ? () => setState(() => _minutes += _durationStep)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: OmeoTokens.space6),
                  Eyebrow(l.appActivityIntensity),
                  const SizedBox(height: OmeoTokens.space2),
                  OmeoSegmented<ActivityInputIntensityEnum>(
                    segments: [
                      for (final i in ActivityInputIntensityEnum.values)
                        (value: i, label: l.appActivityIntensityValue(i.value)),
                    ],
                    selected: _intensity,
                    onChanged: (i) => setState(() => _intensity = i),
                  ),
                  const SizedBox(height: OmeoTokens.space4),
                  OmeoList(
                    children: [
                      OmeoListTile(
                        icon: OmeoIcons.clock,
                        title: l.appActivityWhen,
                        subtitle: started == null
                            ? l.appActivityNow
                            : MaterialLocalizations.of(
                                context,
                              ).formatTimeOfDay(
                                TimeOfDay.fromDateTime(started),
                              ),
                        onTap: () => unawaited(_pickTime()),
                      ),
                    ],
                  ),
                  const SizedBox(height: OmeoTokens.space3),
                  Text(
                    l.appActivityEstimateHint,
                    style: text.labelSmall?.copyWith(color: t.text3),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: OmeoButton(
                label: l.commonActionSave,
                loading: _saving,
                onPressed: type == null || _saving
                    ? null
                    : () => unawaited(_save(type)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final OmeoIcons icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final fg = selected ? t.onContrast : t.text;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? t.contrast : t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OmeoTokens.rMd),
          side: BorderSide(color: selected ? t.contrast : t.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(OmeoTokens.rMd),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OmeoIcon(icon, color: fg),
              const SizedBox(height: OmeoTokens.space1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
