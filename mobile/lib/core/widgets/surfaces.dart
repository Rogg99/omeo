import 'package:flutter/material.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/omeo_icon.dart';

/// Tons partagés par les cartes, pastilles, étiquettes et bannières.
enum OmeoTone {
  primary,
  accent,
  danger,
  warning,
  info,
  neutral,
  contrast,
  glass,
}

/// Couleurs (fond, contenu) d'un ton, résolues depuis les tokens.
({Color background, Color foreground}) toneColors(
  OmeoThemeTokens t,
  OmeoTone tone,
) => switch (tone) {
  OmeoTone.primary => (background: t.primarySoft, foreground: t.primaryText),
  OmeoTone.accent => (background: t.accentSoft, foreground: t.accentText),
  OmeoTone.danger => (background: t.dangerSoft, foreground: t.danger),
  OmeoTone.warning => (background: t.warningSoft, foreground: t.warning),
  OmeoTone.info => (background: t.infoSoft, foreground: t.info),
  OmeoTone.neutral => (background: t.surface2, foreground: t.text2),
  OmeoTone.contrast => (background: t.contrast, foreground: t.onContrast),
  OmeoTone.glass => (
    background: Colors.white.withValues(alpha: 0.16),
    foreground: Colors.white,
  ),
};

/// Variantes de carte des maquettes (`.card`, `.card.green`, `.card.black`…).
enum OmeoCardVariant {
  surface,
  flat,
  sunk,
  green,
  black,
  soft,
  accent,
  warning,
  danger,
  info,
}

/// Carte : surface arrondie (rayon lg), bordure fine, ombre douce.
class OmeoCard extends StatelessWidget {
  const OmeoCard({
    required this.child,
    super.key,
    this.variant = OmeoCardVariant.surface,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.semanticLabel,
  });

  /// Carte compacte (`.card.tight`).
  const OmeoCard.tight({
    required this.child,
    super.key,
    this.variant = OmeoCardVariant.surface,
    this.onTap,
    this.semanticLabel,
  }) : padding = const EdgeInsets.all(14);

  final Widget child;
  final OmeoCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final (background, foreground, border, shadow) = switch (variant) {
      OmeoCardVariant.surface => (t.surface, t.text, t.line, t.shadow1),
      OmeoCardVariant.flat => (t.surface, t.text, t.line, const <BoxShadow>[]),
      OmeoCardVariant.sunk => (
        t.surfaceSunk,
        t.text,
        t.line,
        const <BoxShadow>[],
      ),
      OmeoCardVariant.green => (
        t.primary,
        t.onPrimary,
        null,
        const <BoxShadow>[],
      ),
      OmeoCardVariant.black => (
        t.contrast,
        t.onContrast,
        null,
        const <BoxShadow>[],
      ),
      OmeoCardVariant.soft => (
        t.primarySoft,
        t.text,
        null,
        const <BoxShadow>[],
      ),
      OmeoCardVariant.accent => (
        t.accentSoft,
        t.text,
        null,
        const <BoxShadow>[],
      ),
      OmeoCardVariant.warning => (
        t.warningSoft,
        t.text,
        null,
        const <BoxShadow>[],
      ),
      OmeoCardVariant.danger => (
        t.dangerSoft,
        t.text,
        null,
        const <BoxShadow>[],
      ),
      OmeoCardVariant.info => (t.infoSoft, t.text, null, const <BoxShadow>[]),
    };
    final radius = BorderRadius.circular(OmeoTokens.rLg);
    final content = DefaultTextStyle.merge(
      style: TextStyle(color: foreground),
      child: IconTheme.merge(
        data: IconThemeData(color: foreground),
        child: Padding(padding: padding, child: child),
      ),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          border: border == null ? null : Border.all(color: border),
          boxShadow: shadow,
        ),
        child: onTap == null
            ? content
            : Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: radius,
                  onTap: onTap,
                  child: content,
                ),
              ),
      ),
    );
  }
}

/// Taille d'une pastille d'icône (`.badge-ico`, `.sm`, `.lg`).
enum BadgeSize {
  small(34, 11, 17),
  medium(44, 14, 22),
  large(56, 18, 26)
  ;

  const BadgeSize(this.side, this.radius, this.icon);
  final double side;
  final double radius;
  final double icon;
}

/// Pastille d'icône colorée.
class BadgeIcon extends StatelessWidget {
  const BadgeIcon(
    this.icon, {
    super.key,
    this.tone = OmeoTone.primary,
    this.size = BadgeSize.medium,
    this.round = false,
    this.background,
  });

  final OmeoIcons icon;
  final OmeoTone tone;
  final BadgeSize size;
  final bool round;

  /// Fond imposé (ex. surface sur une carte accent), prioritaire sur [tone].
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final colors = toneColors(context.omeo, tone);
    return Container(
      width: size.side,
      height: size.side,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? colors.background,
        borderRadius: BorderRadius.circular(round ? size.side : size.radius),
      ),
      child: OmeoIcon(icon, size: size.icon, color: colors.foreground),
    );
  }
}

/// Étiquette (`.tag`) : pastille de texte courte, avec icône facultative.
class OmeoTag extends StatelessWidget {
  const OmeoTag(
    this.label, {
    super.key,
    this.tone = OmeoTone.primary,
    this.icon,
  });

  /// Étiquette « Plus » des fonctionnalités réservées à l'offre payante.
  const OmeoTag.plus(this.label, {super.key})
    : tone = OmeoTone.contrast,
      icon = null;

  final String label;
  final OmeoTone tone;
  final OmeoIcons? icon;

  @override
  Widget build(BuildContext context) {
    final colors = toneColors(context.omeo, tone);
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(OmeoTokens.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            OmeoIcon(icon!, size: 13, color: colors.foreground),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.foreground,
                fontSize: 11.5,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bannière d'information (`.banner`) : hors connexion, succès, alerte…
class OmeoBanner extends StatelessWidget {
  const OmeoBanner({
    required this.icon,
    required this.child,
    super.key,
    this.tone = OmeoTone.neutral,
    this.trailing,
  });

  final OmeoIcons icon;
  final Widget child;
  final OmeoTone tone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final (background, foreground) = switch (tone) {
      OmeoTone.primary => (t.successSoft, t.primaryText),
      OmeoTone.warning => (
        t.warningSoft,
        Color.lerp(t.warning, t.text, 0.25)!,
      ),
      OmeoTone.info => (t.infoSoft, Color.lerp(t.info, t.text, 0.3)!),
      OmeoTone.danger => (t.dangerSoft, t.danger),
      _ => (t.surface2, t.text2),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(OmeoTokens.rMd),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: OmeoIcon(icon, size: 20, color: foreground),
            ),
            const SizedBox(width: OmeoTokens.space3),
            Expanded(
              child: DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontSize: 13.5,
                ),
                child: child,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: OmeoTokens.space2),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
