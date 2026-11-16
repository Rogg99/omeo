import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/auth/presentation/auth_widgets.dart';
import 'package:omeo/features/profile/application/app_settings.dart';

/// Écran de démarrage (ONB-01) : logo sur vert profond le temps de relire la
/// session. Aucune interaction.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    const ink = OmeoTokens.cream50;
    return Scaffold(
      backgroundColor: OmeoTokens.sage800,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const OmeoLogo(size: 64, withText: false, color: ink),
                  const SizedBox(height: 14),
                  Text(
                    l.appAuthBrandName,
                    style: text.displayMedium?.copyWith(color: ink),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.appAuthTagline,
                    textAlign: TextAlign.center,
                    style: text.bodyLarge?.copyWith(
                      color: ink.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Semantics(
                  label: l.commonStateLoading,
                  child: const SizedBox.square(
                    dimension: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: ink,
                      backgroundColor: Color(0x2EFFFFFF),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Langues de l'app, chacune écrite dans sa propre écriture (elles ne se
/// traduisent pas).
const List<({String code, String name})> appLanguages = [
  (code: 'fr', name: 'Français'),
  (code: 'en', name: 'English'),
  (code: 'es', name: 'Español'),
  (code: 'pt', name: 'Português'),
  (code: 'ar', name: 'العربية'),
  (code: 'zh', name: '简体中文'),
  (code: 'ja', name: '日本語'),
  (code: 'de', name: 'Deutsch'),
];

/// Liste des 8 langues (ONB-02, PRF-07). L'arabe bascule l'interface de
/// droite à gauche dès la sélection.
class LanguageList extends StatelessWidget {
  const LanguageList({
    required this.selected,
    required this.onSelect,
    super.key,
    this.detected,
  });

  final String selected;

  /// Langue détectée sur le téléphone, signalée sous son nom.
  final String? detected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return OmeoList(
      children: [
        for (final lang in appLanguages)
          Semantics(
            selected: lang.code == selected,
            inMutuallyExclusiveGroup: true,
            child: OmeoListTile(
              title: lang.name,
              subtitle: lang.code == 'ar'
                  ? l.appAuthLanguageRtl
                  : lang.code == detected
                  ? l.appAuthLanguageDetected
                  : null,
              showChevron: false,
              trailing: SelectionMark(
                selected: lang.code == selected,
                square: false,
              ),
              onTap: () => onSelect(lang.code),
            ),
          ),
      ],
    );
  }
}

/// Choix de la langue au premier lancement (ONB-02).
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({required this.onContinue, super.key});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final device = WidgetsBinding.instance.platformDispatcher.locale;
    final supported = appLanguages.map((x) => x.code).toSet();
    final detected = supported.contains(device.languageCode)
        ? device.languageCode
        : 'fr';
    final current = Localizations.localeOf(context).languageCode;
    return BottomActionsScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: OmeoLogo(size: 36),
          ),
          const SizedBox(height: 32),
          ScreenTitle(
            l.appAuthLanguageTitle,
            subtitle: l.appAuthLanguageSubtitle,
          ),
          const SizedBox(height: 24),
          LanguageList(
            selected: supported.contains(current) ? current : detected,
            detected: detected,
            onSelect: (code) =>
                ref.read(appSettingsProvider.notifier).setLanguage(code),
          ),
        ],
      ),
      actions: [
        OmeoButton(
          label: l.commonActionContinue,
          trailingIcon: OmeoIcons.arrowR,
          onPressed: () async {
            // Valide aussi la langue détectée si rien n'a été touché.
            final settings = ref.read(appSettingsProvider.notifier);
            if (!ref.read(appSettingsProvider).languageChosen) {
              await settings.setLanguage(
                supported.contains(current) ? current : detected,
              );
            }
            onContinue();
          },
        ),
      ],
    );
  }
}

/// Bienvenue (ONB-03) : la promesse, puis deux chemins clairs.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    required this.onStart,
    required this.onLogin,
    super.key,
  });

  final VoidCallback onStart;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _WelcomeHero(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: '${l.appAuthWelcomeTitle}\n'),
                                TextSpan(
                                  text: l.appAuthWelcomeAccent,
                                  style: TextStyle(
                                    fontFamily: OmeoTokens.fontAccent,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w400,
                                    color: t.primaryText,
                                  ),
                                ),
                              ],
                            ),
                            style: text.headlineLarge,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.appAuthWelcomeBody,
                          style: text.bodyLarge?.copyWith(color: t.text2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  OmeoButton(label: l.appAuthWelcomeStart, onPressed: onStart),
                  const SizedBox(height: OmeoTokens.space2),
                  OmeoButton(
                    label: l.appAuthWelcomeLogin,
                    variant: OmeoButtonVariant.ghost,
                    onPressed: onLogin,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Visuel de la bienvenue : assiette cerclée et étiquettes d'analyse.
class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return ExcludeSemantics(
      child: Container(
        height: 430,
        decoration: const BoxDecoration(
          color: OmeoTokens.sage800,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 290,
                height: 290,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [OmeoTokens.brown700, OmeoTokens.ink950],
                  ),
                ),
                child: const Center(
                  child: OmeoIcon(
                    OmeoIcons.utensils,
                    size: 72,
                    color: OmeoTokens.cream50,
                  ),
                ),
              ),
              PositionedDirectional(
                start: 26,
                top: 60,
                child: OmeoTag(
                  l.appAuthWelcomeKcalTag,
                  tone: OmeoTone.glass,
                  icon: OmeoIcons.flame,
                ),
              ),
              PositionedDirectional(
                end: 24,
                top: 210,
                child: OmeoTag(
                  l.appAuthWelcomeProteinTag,
                  tone: OmeoTone.glass,
                  icon: OmeoIcons.beef,
                ),
              ),
              PositionedDirectional(
                start: 44,
                bottom: 30,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: OmeoTokens.cream50,
                    borderRadius: BorderRadius.circular(OmeoTokens.rPill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const OmeoIcon(
                          OmeoIcons.sparkles,
                          size: 14,
                          color: OmeoTokens.ink950,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l.appAuthWelcomeDishTag,
                          style: text.labelMedium?.copyWith(
                            color: OmeoTokens.ink950,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
