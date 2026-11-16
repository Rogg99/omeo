import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/l10n/formatters.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/units/units.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/onboarding/application/onboarding_controller.dart';
import 'package:omeo/features/onboarding/application/target_weight.dart';
import 'package:omeo/features/onboarding/data/onboarding_draft.dart';
import 'package:omeo/features/onboarding/presentation/ruler_picker.dart';
import 'package:omeo/features/onboarding/presentation/step_scaffold.dart';
import 'package:omeo_api/omeo_api.dart' hide Locale;

/// Lit un nombre saisi avec une virgule ou un point décimal.
double? parseDecimal(String input) =>
    double.tryParse(input.trim().replaceAll(',', '.'));

/// Valeur affichée dans un champ numérique : une décimale au plus.
String formatDecimal(BuildContext context, double value) {
  final rounded = (value * 10).round() / 10;
  return context.number(rounded);
}

/// Étapes 1 à 8 du questionnaire. Chaque réponse est enregistrée sur le
/// téléphone dès qu'elle change.
class QuestionStepScreen extends ConsumerWidget {
  const QuestionStepScreen({
    required this.step,
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final int step;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final draft = ref.watch(onboardingProvider).value;
    if (draft == null) {
      return const Scaffold(body: Center(child: OmeoSpinner()));
    }
    final controller = ref.read(onboardingProvider.notifier);
    void update(OnboardingDraft Function(OnboardingDraft) change) =>
        unawaited(controller.answer(change));

    final (icon, title, subtitle, body) = switch (step) {
      1 => (
        OmeoIcons.user,
        l.appOnboardingNameTitle,
        l.appOnboardingNameSubtitle,
        _NameStep(draft: draft, update: update),
      ),
      2 => (
        OmeoIcons.calendar,
        l.appOnboardingBirthTitle,
        l.appOnboardingBirthSubtitle,
        _BirthStep(draft: draft, update: update),
      ),
      3 => (
        OmeoIcons.users,
        l.appOnboardingSexTitle,
        l.appOnboardingSexSubtitle,
        _SexStep(draft: draft, update: update),
      ),
      4 => (
        OmeoIcons.pin,
        l.appOnboardingCityTitle,
        l.appOnboardingCitySubtitle,
        _CityStep(draft: draft, update: update),
      ),
      5 => (
        OmeoIcons.ruler,
        l.appOnboardingHeightTitle,
        l.appOnboardingHeightSubtitle,
        _HeightStep(draft: draft, update: update),
      ),
      6 => (
        OmeoIcons.scale,
        l.appOnboardingWeightTitle,
        l.appOnboardingWeightSubtitle,
        _WeightStep(draft: draft, update: update, target: false),
      ),
      7 => (
        OmeoIcons.flag,
        l.appOnboardingTargetTitle,
        l.appOnboardingTargetSubtitle,
        _WeightStep(draft: draft, update: update, target: true),
      ),
      _ => (
        OmeoIcons.target,
        l.appOnboardingGoalsTitle,
        l.appOnboardingGoalsSubtitle,
        _GoalsStep(draft: draft, onToggle: controller.toggleGoal),
      ),
    };

    return StepScaffold(
      step: step,
      icon: icon,
      title: title,
      subtitle: subtitle,
      body: body,
      onBack: onBack,
      continueLabel: step == onboardingQuestionSteps && draft.goals.isNotEmpty
          ? l.appOnboardingGoalsContinue(draft.goals.length)
          : null,
      onContinue: draft.isStepComplete(step)
          ? () {
              unawaited(controller.reach(step + 1));
              onNext();
            }
          : null,
    );
  }
}

typedef _Update = void Function(OnboardingDraft Function(OnboardingDraft));

/// Étape 1 (ONB-04) : prénom et nom, clavier ouvert directement.
class _NameStep extends StatefulWidget {
  const _NameStep({required this.draft, required this.update});

  final OnboardingDraft draft;
  final _Update update;

  @override
  State<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<_NameStep> {
  late final _first = TextEditingController(text: widget.draft.firstName);
  late final _last = TextEditingController(text: widget.draft.lastName);

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AutofillGroup(
      child: Column(
        children: [
          OmeoTextField(
            controller: _first,
            hint: l.appOnboardingFirstName,
            icon: OmeoIcons.user,
            autofocus: true,
            maxLength: OnboardingDraft.nameMaxLength,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.givenName],
            onChanged: (v) => widget.update((d) => d.copyWith(firstName: v)),
          ),
          const SizedBox(height: OmeoTokens.space3),
          OmeoTextField(
            controller: _last,
            hint: l.appOnboardingLastName,
            icon: OmeoIcons.user,
            maxLength: OnboardingDraft.nameMaxLength,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.familyName],
            onChanged: (v) => widget.update((d) => d.copyWith(lastName: v)),
          ),
        ],
      ),
    );
  }
}

/// Étape 2 (ONB-05) : date de naissance en roues, sans clavier.
class _BirthStep extends StatefulWidget {
  const _BirthStep({required this.draft, required this.update});

  final OnboardingDraft draft;
  final _Update update;

  @override
  State<_BirthStep> createState() => _BirthStepState();
}

class _BirthStepState extends State<_BirthStep> {
  late final DateTime _today = DateUtils.dateOnly(DateTime.now());

  /// Date proposée au départ : 30 ans avant aujourd'hui (simple position
  /// initiale des roues, enregistrée telle quelle si elle convient).
  late final DateTime _initial =
      widget.draft.birthDate ??
      DateTime(_today.year - 30, _today.month, _today.day);

  @override
  void initState() {
    super.initState();
    if (widget.draft.birthDate == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.update((d) => d.copyWith(birthDate: _initial)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    return OmeoCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 220,
        child: CupertinoTheme(
          data: CupertinoThemeData(
            brightness: Theme.of(context).brightness,
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: t.text),
            ),
          ),
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: _initial,
            minimumDate: DateTime(_today.year - 110),
            maximumDate: _today,
            dateOrder: DatePickerDateOrder.dmy,
            onDateTimeChanged: (date) => widget.update(
              (d) => d.copyWith(birthDate: DateUtils.dateOnly(date)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Étape 3 (ONB-06) : deux grandes cartes.
class _SexStep extends StatelessWidget {
  const _SexStep({required this.draft, required this.update});

  final OnboardingDraft draft;
  final _Update update;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget option(Sex sex, String label) => Padding(
      padding: const EdgeInsets.only(bottom: OmeoTokens.space3),
      child: OmeoOption(
        title: label,
        selected: draft.sex == sex,
        leading: BadgeIcon(
          OmeoIcons.user,
          round: true,
          tone: draft.sex == sex ? OmeoTone.primary : OmeoTone.neutral,
        ),
        onTap: () => update((d) => d.copyWith(sex: sex)),
      ),
    );
    return Column(
      children: [
        option(Sex.male, l.appOnboardingSexMale),
        option(Sex.female, l.appOnboardingSexFemale),
      ],
    );
  }
}

/// Étape 4 (ONB-07) : saisie avec suggestions et villes populaires.
class _CityStep extends ConsumerStatefulWidget {
  const _CityStep({required this.draft, required this.update});

  final OnboardingDraft draft;
  final _Update update;

  @override
  ConsumerState<_CityStep> createState() => _CityStepState();
}

class _CityStepState extends ConsumerState<_CityStep> {
  late final _input = TextEditingController(text: widget.draft.cityLabel);
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Saisie libre acceptée : la ville choisie dans la liste la précise.
    widget.update(
      (d) => d.copyWith(city: (id: null, label: value, country: null)),
    );
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => setState(() => _query = value.trim()),
    );
  }

  void _select(City city) {
    _input.text = city.name;
    widget.update(
      (d) => d.copyWith(
        city: (id: city.id, label: city.name, country: city.country),
      ),
    );
    FocusScope.of(context).unfocus();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final results = _query.isEmpty
        ? null
        : ref.watch(citySearchProvider(_query));
    final popular = ref.watch(citySearchProvider(''));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OmeoTextField(
          controller: _input,
          hint: l.appOnboardingCitySearch,
          icon: OmeoIcons.search,
          autofocus: widget.draft.cityLabel == null,
          textCapitalization: TextCapitalization.words,
          onChanged: _onChanged,
        ),
        if (results?.value case final cities? when cities.isNotEmpty) ...[
          const SizedBox(height: OmeoTokens.space3),
          OmeoList(
            children: [
              for (final c in cities)
                OmeoListTile(
                  title: c.name,
                  subtitle: c.country,
                  leading: const OmeoIcon(OmeoIcons.pin, size: 20),
                  showChevron: false,
                  trailing: c.id == widget.draft.cityId
                      ? const OmeoIcon(OmeoIcons.check, size: 20)
                      : null,
                  onTap: () => _select(c),
                ),
            ],
          ),
        ],
        if (popular.value case final cities? when cities.isNotEmpty) ...[
          const SizedBox(height: OmeoTokens.space4),
          Text(
            l.appOnboardingCityPopular.toUpperCase(),
            style: text.labelSmall,
          ),
          const SizedBox(height: OmeoTokens.space2),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in cities)
                OmeoChip(
                  label: c.name,
                  selected: c.id == widget.draft.cityId,
                  onTap: () => _select(c),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Étape 5 (ONB-08) : règle à faire glisser, saisie au clavier, cm / ft.
class _HeightStep extends StatelessWidget {
  const _HeightStep({required this.draft, required this.update});

  final OnboardingDraft draft;
  final _Update update;

  static const _default = 170;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final cm = (draft.heightCm ?? _default).round();
    final imperial = draft.heightUnit == UnitSystem.imperial;
    final ft = Units.cmToFeetInches(cm.toDouble());
    final display = imperial
        ? l.appOnboardingFeetInches(ft.feet, ft.inches)
        : l.appOnboardingCm(cm);

    if (draft.heightCm == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => update((d) => d.copyWith(heightCm: _default.toDouble())),
      );
    }

    Future<void> typeIn() async {
      final value = await showDialog<double>(
        context: context,
        builder: (_) => _NumberDialog(
          title: l.appOnboardingHeightTitle,
          unit: l.appOnboardingUnitCm,
          initial: cm.toDouble(),
        ),
      );
      if (value == null) return;
      update(
        (d) => d.copyWith(
          heightCm: value.clamp(
            OnboardingDraft.minHeightCm,
            OnboardingDraft.maxHeightCm,
          ),
        ),
      );
    }

    return Column(
      children: [
        Semantics(
          button: true,
          label: l.appOnboardingTypeValue,
          child: InkWell(
            borderRadius: BorderRadius.circular(OmeoTokens.rMd),
            onTap: typeIn,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                display,
                style: text.displayLarge?.copyWith(
                  fontSize: 56,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: OmeoTokens.space2),
        RulerPicker(
          min: OnboardingDraft.minHeightCm.round(),
          max: OnboardingDraft.maxHeightCm.round(),
          value: cm,
          semanticValue: display,
          onChanged: (v) => update((d) => d.copyWith(heightCm: v.toDouble())),
        ),
        const SizedBox(height: OmeoTokens.space2),
        SizedBox(
          width: 180,
          child: OmeoSegmented<UnitSystem>(
            segments: [
              (value: UnitSystem.metric, label: l.appOnboardingUnitCm),
              (value: UnitSystem.imperial, label: l.appOnboardingUnitFt),
            ],
            selected: draft.heightUnit,
            onChanged: (u) => update((d) => d.copyWith(heightUnit: u)),
          ),
        ),
        const SizedBox(height: OmeoTokens.space2),
        Text(
          l.appOnboardingHeightTapHint,
          style: text.bodySmall?.copyWith(color: t.text3),
        ),
      ],
    );
  }
}

/// Saisie au clavier d'une valeur numérique.
class _NumberDialog extends StatefulWidget {
  const _NumberDialog({
    required this.title,
    required this.unit,
    required this.initial,
  });

  final String title;
  final String unit;
  final double initial;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final _input = TextEditingController(
    text: widget.initial.round().toString(),
  );

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: OmeoTextField(
        controller: _input,
        unit: widget.unit,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonActionCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(parseDecimal(_input.text)),
          child: Text(l.commonActionConfirm),
        ),
      ],
    );
  }
}

/// Étapes 6 et 7 (ONB-09 à ONB-11) : champ géant avec décimale, kg / lb.
/// À l'étape 7, l'écart avec le poids actuel s'affiche en direct (D22).
class _WeightStep extends StatefulWidget {
  const _WeightStep({
    required this.draft,
    required this.update,
    required this.target,
  });

  final OnboardingDraft draft;
  final _Update update;
  final bool target;

  @override
  State<_WeightStep> createState() => _WeightStepState();
}

class _WeightStepState extends State<_WeightStep> {
  final _input = TextEditingController();
  bool _initialized = false;

  double? get _kg =>
      widget.target ? widget.draft.targetWeightKg : widget.draft.weightKg;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final kg = _kg;
    if (kg != null) {
      _input.text = formatDecimal(
        context,
        Units.displayWeight(kg, widget.draft.weightUnit),
      );
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final parsed = parseDecimal(value);
    final kg = parsed == null
        ? null
        : Units.weightToApi(parsed, widget.draft.weightUnit);
    widget.update((d) => d.withWeight(kg, target: widget.target));
  }

  void _onUnit(UnitSystem unit) {
    final kg = _kg;
    if (kg != null) {
      _input.text = formatDecimal(context, Units.displayWeight(kg, unit));
    }
    widget.update((d) => d.copyWith(weightUnit: unit));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final unit = widget.draft.weightUnit;
    final unitLabel = unit == UnitSystem.metric
        ? l.appOnboardingUnitKg
        : l.appOnboardingUnitLb;
    final current = widget.draft.weightKg;
    final advice = widget.target
        ? targetWeightAdvice(
            current: current == null
                ? null
                : Units.displayWeight(current, unit),
            target: _kg == null ? null : Units.displayWeight(_kg!, unit),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OmeoTextField(
          controller: _input,
          big: true,
          autofocus: true,
          unit: unitLabel,
          hint: '0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
            LengthLimitingTextInputFormatter(5),
          ],
          error:
              _kg != null && !widget.draft.isStepComplete(widget.target ? 7 : 6)
              ? l.appOnboardingWeightRange(
                  formatDecimal(
                    context,
                    Units.displayWeight(OnboardingDraft.minWeightKg, unit),
                  ),
                  formatDecimal(
                    context,
                    Units.displayWeight(OnboardingDraft.maxWeightKg, unit),
                  ),
                  unitLabel,
                )
              : null,
          onChanged: _onChanged,
        ),
        const SizedBox(height: OmeoTokens.space2),
        Center(
          child: SizedBox(
            width: 180,
            child: OmeoSegmented<UnitSystem>(
              segments: [
                (value: UnitSystem.metric, label: l.appOnboardingUnitKg),
                (value: UnitSystem.imperial, label: l.appOnboardingUnitLb),
              ],
              selected: unit,
              onChanged: _onUnit,
            ),
          ),
        ),
        const SizedBox(height: OmeoTokens.space4),
        if (!widget.target)
          OmeoBanner(
            icon: OmeoIcons.lock,
            child: Text(l.appOnboardingWeightPrivacy),
          )
        else if (advice != null && advice.difference != 0)
          Semantics(
            liveRegion: true,
            child: advice.aboveCurrent
                ? OmeoBanner(
                    icon: OmeoIcons.alert,
                    tone: OmeoTone.warning,
                    child: Text(
                      l.appOnboardingTargetAbove(
                        context.signedNumber(advice.difference),
                        unitLabel,
                      ),
                    ),
                  )
                : OmeoCard(
                    variant: OmeoCardVariant.soft,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const OmeoIcon(OmeoIcons.trend, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.appOnboardingTargetBelow(
                              context.signedNumber(advice.difference),
                              unitLabel,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
      ],
    );
  }
}

/// Étape 8 (ONB-12) : choix multiple ; perdre et prendre s'excluent.
class _GoalsStep extends StatelessWidget {
  const _GoalsStep({required this.draft, required this.onToggle});

  final OnboardingDraft draft;
  final Future<void> Function(Goal) onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final options = [
      (
        Goal.loseWeight,
        OmeoIcons.scale,
        l.appOnboardingGoalLose,
        l.appOnboardingGoalLoseSub,
      ),
      (
        Goal.gainMuscle,
        OmeoIcons.dumbbell,
        l.appOnboardingGoalGain,
        l.appOnboardingGoalGainSub,
      ),
      (
        Goal.eatBalanced,
        OmeoIcons.utensils,
        l.appOnboardingGoalBalanced,
        l.appOnboardingGoalBalancedSub,
      ),
      (
        Goal.preventDiabetes,
        OmeoIcons.drop,
        l.appOnboardingGoalDiabetes,
        l.appOnboardingGoalDiabetesSub,
      ),
      (
        Goal.preventHypertension,
        OmeoIcons.heart,
        l.appOnboardingGoalHypertension,
        l.appOnboardingGoalHypertensionSub,
      ),
    ];
    String labelOf(Goal g) => options.firstWhere((o) => o.$1 == g).$3;
    return Column(
      children: [
        for (final (goal, icon, title, sub) in options)
          () {
            final selected = draft.goals.contains(goal);
            final blocker = incompatibleGoals[goal];
            final blocked =
                !selected && blocker != null && draft.goals.contains(blocker);
            return Padding(
              padding: const EdgeInsets.only(bottom: OmeoTokens.space3),
              child: Opacity(
                opacity: blocked ? 0.45 : 1,
                child: OmeoOption(
                  title: title,
                  subtitle: blocked
                      ? l.appOnboardingGoalIncompatible(labelOf(blocker))
                      : sub,
                  multiple: true,
                  selected: selected,
                  leading: BadgeIcon(
                    icon,
                    round: true,
                    tone: selected ? OmeoTone.primary : OmeoTone.neutral,
                  ),
                  onTap: () => unawaited(onToggle(goal)),
                ),
              ),
            );
          }(),
      ],
    );
  }
}
