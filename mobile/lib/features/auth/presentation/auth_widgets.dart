import 'package:flutter/material.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/widgets.dart';

/// Page à défilement avec ses actions collées en bas, à portée du pouce
/// (`.bottom-cta`). Le contenu remonte au-dessus du clavier.
class BottomActionsScaffold extends StatelessWidget {
  const BottomActionsScaffold({
    required this.body,
    required this.actions,
    super.key,
    this.header,
    this.canPop = true,
  });

  final Widget? header;
  final Widget body;
  final List<Widget> actions;
  final bool canPop;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?header,
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: body,
                ),
              ),
              if (actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(height: OmeoTokens.space2),
                        actions[i],
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Titre d'écran (`.h-xl`) annoncé comme en-tête, et son sous-titre.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.title, {super.key, this.subtitle, this.large = true});

  final String title;
  final String? subtitle;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: large ? text.headlineLarge : text.headlineMedium,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: OmeoTokens.space2),
          Text(
            subtitle!,
            style: text.bodyLarge?.copyWith(color: context.omeo.text2),
          ),
        ],
      ],
    );
  }
}

/// Règles du mot de passe, vérifiées en direct (ONB-13, ACC-05, PRF-04).
/// L'API reste juge : ces règles ne servent qu'à guider la saisie.
abstract final class PasswordRules {
  static const minLength = 10;

  static bool longEnough(String p) => p.characters.length >= minLength;
  static bool mixedCase(String p) =>
      p.contains(RegExp('[a-z]')) && p.contains(RegExp('[A-Z]'));
  static bool hasDigit(String p) => p.contains(RegExp('[0-9]'));
  static bool hasSpecial(String p) => p.contains(RegExp('[^A-Za-z0-9]'));

  static bool allMet(String p) =>
      longEnough(p) && mixedCase(p) && hasDigit(p) && hasSpecial(p);
}

/// Liste des règles, cochées au fur et à mesure de la saisie.
class PasswordRulesCard extends StatelessWidget {
  const PasswordRulesCard({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    final rules = [
      (l.appAuthRuleLength(PasswordRules.minLength), PasswordRules.longEnough),
      (l.appAuthRuleCase, PasswordRules.mixedCase),
      (l.appAuthRuleDigit, PasswordRules.hasDigit),
      (l.appAuthRuleSpecial, PasswordRules.hasSpecial),
    ];
    return OmeoCard(
      variant: OmeoCardVariant.sunk,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, check) in rules)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Semantics(
                checked: check(password),
                child: Row(
                  children: [
                    OmeoIcon(
                      check(password) ? OmeoIcons.check : OmeoIcons.minus,
                      size: 16,
                      color: check(password) ? t.primaryText : t.text3,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: text.bodySmall?.copyWith(
                          color: check(password) ? t.primaryText : t.text3,
                        ),
                      ),
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

/// Séparateur « ou » entre connexion sociale et email.
class OrDivider extends StatelessWidget {
  const OrDivider(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    return Row(
      children: [
        Expanded(child: Divider(color: t.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: t.text3),
          ),
        ),
        Expanded(child: Divider(color: t.line)),
      ],
    );
  }
}

/// Grande pastille ronde d'icône en tête d'écran (`.badge-ico.lg.round`).
class HeroBadge extends StatelessWidget {
  const HeroBadge(
    this.icon, {
    super.key,
    this.tone = OmeoTone.primary,
    this.size = 56,
  });

  final OmeoIcons icon;
  final OmeoTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = toneColors(context.omeo, tone);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.background,
        shape: BoxShape.circle,
      ),
      child: OmeoIcon(icon, size: size * 0.42, color: colors.foreground),
    );
  }
}
