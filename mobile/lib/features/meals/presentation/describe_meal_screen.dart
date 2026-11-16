import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/meals/application/quotas_controller.dart';
import 'package:omeo/features/meals/data/speech_transcriber.dart';
import 'package:omeo_api/omeo_api.dart' show QuotaFeatureEnum;

/// Mode de saisie : voix (par défaut) ou texte.
enum DescribeMode { voice, text }

/// Longueur maximale d'une description envoyée à l'analyse.
const _maxDescription = 500;

/// Saisie vocale (MEA-11) et en texte (MEA-12), réservées à Plus. La voix
/// est transcrite sur l'appareil ; le texte part ensuite à l'analyse, puis au
/// même écran de correction que la photo.
class DescribeMealScreen extends ConsumerStatefulWidget {
  const DescribeMealScreen({
    required this.onClose,
    required this.onAnalyze,
    super.key,
    this.initialMode = DescribeMode.voice,
  });

  final VoidCallback onClose;
  final ValueChanged<String> onAnalyze;
  final DescribeMode initialMode;

  @override
  ConsumerState<DescribeMealScreen> createState() => _DescribeMealScreenState();
}

class _DescribeMealScreenState extends ConsumerState<DescribeMealScreen> {
  late DescribeMode _mode = widget.initialMode;
  final _text = TextEditingController();
  bool _listening = false;
  double _level = 0;
  TranscriberUnavailable? _unavailable;

  SpeechTranscriber get _speech => ref.read(speechTranscriberProvider);

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (_listening) unawaited(_speech.stop());
    _text.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      return;
    }
    final problem = await _speech.prepare();
    if (!mounted) return;
    if (problem != null) {
      setState(() {
        _unavailable = problem;
        _mode = DescribeMode.text;
      });
      return;
    }
    unawaited(HapticFeedback.lightImpact());
    setState(() => _listening = true);
    await _speech.start(
      localeTag: Localizations.localeOf(context).toLanguageTag(),
      onText: (text) => _text.text = text,
      onLevel: (level) {
        if (mounted) setState(() => _level = level);
      },
      onStopped: () {
        if (mounted) setState(() => _listening = false);
      },
    );
  }

  void _setMode(DescribeMode mode) {
    if (_listening) unawaited(_speech.stop());
    setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final quotas = ref.watch(quotasProvider).value;
    final quota = quotas == null
        ? null
        : quotaFor(quotas, QuotaFeatureEnum.textAnalysis);
    final description = _text.text.trim();
    final canAnalyze = description.isNotEmpty && !_listening;
    final voice = _mode == DescribeMode.voice;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OmeoTopBar(
              title: voice
                  ? l.appMealDescribeVoiceTitle
                  : l.appMealDescribeTextTitle,
              backLabel: l.commonActionClose,
              close: true,
              onBack: widget.onClose,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  OmeoSegmented<DescribeMode>(
                    segments: [
                      (
                        value: DescribeMode.voice,
                        label: l.appMealDescribeVoice,
                      ),
                      (value: DescribeMode.text, label: l.appMealDescribeText),
                    ],
                    selected: _mode,
                    onChanged: _setMode,
                  ),
                  if (_unavailable != null) ...[
                    const SizedBox(height: OmeoTokens.space4),
                    OmeoBanner(
                      icon: OmeoIcons.info,
                      child: Text(
                        _unavailable == TranscriberUnavailable.denied
                            ? l.appMealDescribeMicDenied
                            : l.appMealDescribeUnavailable,
                      ),
                    ),
                  ],
                  if (voice) ...[
                    const SizedBox(height: OmeoTokens.space8),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        description.isEmpty
                            ? l.appMealDescribeListeningHint
                            : description,
                        style: text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                          color: description.isEmpty ? t.text3 : t.text,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                    TextField(
                      controller: _text,
                      autofocus: _unavailable == null,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: _maxDescription,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: l.appMealDescribeTextHint,
                      ),
                    ),
                    const SizedBox(height: OmeoTokens.space4),
                    Eyebrow(l.appMealDescribeExamples),
                    const SizedBox(height: OmeoTokens.space2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final example in [
                          l.appMealDescribeExample1,
                          l.appMealDescribeExample2,
                          l.appMealDescribeExample3,
                        ])
                          OmeoChip(
                            label: example,
                            selected: false,
                            onTap: () => _text.text = example,
                          ),
                      ],
                    ),
                  ],
                  if (quota?.remaining != null) ...[
                    const SizedBox(height: OmeoTokens.space4),
                    Text(
                      l.appMealDescribeLeft(quota!.remaining!),
                      style: text.labelSmall?.copyWith(color: t.text3),
                    ),
                  ],
                ],
              ),
            ),
            if (voice)
              _MicControl(
                listening: _listening,
                level: _level,
                onTap: () => unawaited(_toggleListening()),
              ),
            if (!voice || canAnalyze)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: OmeoButton(
                  label: l.appMealDescribeAnalyze,
                  icon: OmeoIcons.sparkles,
                  onPressed: canAnalyze
                      ? () => widget.onAnalyze(description)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Barres de niveau sonore et bouton du micro.
class _MicControl extends StatelessWidget {
  const _MicControl({
    required this.listening,
    required this.level,
    required this.onTap,
  });

  final bool listening;
  final double level;
  final VoidCallback onTap;

  static const _bars = [10, 22, 34, 18, 40, 26, 14, 30, 38, 20, 12, 28, 16];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      child: Column(
        children: [
          ExcludeSemantics(
            child: SizedBox(
              height: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final h in _bars)
                    AnimatedContainer(
                      duration: reduceMotion
                          ? Duration.zero
                          : OmeoTokens.durationFast,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 4,
                      height: listening ? 4 + (h - 4) * (0.3 + 0.7 * level) : 4,
                      decoration: BoxDecoration(
                        color: t.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Semantics(
            button: true,
            label: listening ? l.appMealDescribeStop : l.appMealDescribeStart,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: listening ? t.accent : t.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (listening ? t.accentSoft : t.primarySoft),
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: OmeoIcon(
                    listening ? OmeoIcons.pause : OmeoIcons.mic,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: OmeoTokens.space3),
          Text(
            listening
                ? l.appMealDescribeTapToStop
                : l.appMealDescribeTapToStart,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: t.text2),
          ),
        ],
      ),
    );
  }
}
