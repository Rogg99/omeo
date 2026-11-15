import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/omeo_icon.dart';

/// Variantes de bouton des maquettes (`.btn.*`).
enum OmeoButtonVariant {
  black,
  outline,
  soft,
  ghost,
  danger,
  dangerSoft,
  white,
  social,
}

/// Hauteurs de bouton : 56 (par défaut), 48 (`.md`), 42 (`.sm`).
enum OmeoButtonSize {
  small(42, 14, 16),
  medium(48, 15, 22),
  large(56, 16, 22)
  ;

  const OmeoButtonSize(this.height, this.fontSize, this.padding);
  final double height;
  final double fontSize;
  final double padding;
}

/// Bouton pilule. Le retour haptique accompagne chaque appui.
class OmeoButton extends StatelessWidget {
  const OmeoButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = OmeoButtonVariant.black,
    this.size = OmeoButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.expand = true,
    this.loading = false,
  });

  final String label;

  /// `null` désactive le bouton (opacité 40 %).
  final VoidCallback? onPressed;
  final OmeoButtonVariant variant;
  final OmeoButtonSize size;
  final OmeoIcons? icon;
  final OmeoIcons? trailingIcon;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final (Color bg, Color fg, Color? border) = switch (variant) {
      OmeoButtonVariant.black => (t.contrast, t.onContrast, null),
      OmeoButtonVariant.outline => (Colors.transparent, t.text, t.lineStrong),
      OmeoButtonVariant.soft => (t.primarySoft, t.primaryText, null),
      OmeoButtonVariant.ghost => (Colors.transparent, t.primaryText, null),
      OmeoButtonVariant.danger => (t.danger, t.textInv, null),
      OmeoButtonVariant.dangerSoft => (t.dangerSoft, t.danger, null),
      OmeoButtonVariant.white => (OmeoTokens.cream50, OmeoTokens.ink950, null),
      OmeoButtonVariant.social => (t.surface, t.text, t.lineStrong),
    };
    final enabled = onPressed != null && !loading;
    final family = variant == OmeoButtonVariant.social
        ? Theme.of(context).textTheme.labelLarge?.fontFamily
        : Theme.of(context).textTheme.titleMedium?.fontFamily;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
          )
        else if (icon != null)
          OmeoIcon(icon!, size: 20, color: fg),
        if (loading || icon != null) const SizedBox(width: OmeoTokens.space2),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: family,
              fontSize: size.fontSize,
              fontWeight: OmeoTokens.weightSemibold,
              letterSpacing: -0.01 * size.fontSize,
              color: fg,
            ),
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: OmeoTokens.space2),
          OmeoIcon(trailingIcon!, size: 20, color: fg, mirrorInRtl: true),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedOpacity(
        opacity: enabled || loading ? 1 : 0.4,
        duration: OmeoTokens.durationFast,
        child: Material(
          color: bg,
          shape: StadiumBorder(
            side: border == null
                ? BorderSide.none
                : BorderSide(color: border, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled
                ? () {
                    unawaited(HapticFeedback.lightImpact());
                    onPressed!();
                  }
                : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.padding),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton rond à icône (`.icon-btn`), avec badge de compteur facultatif.
class OmeoIconButton extends StatelessWidget {
  const OmeoIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
    this.small = false,
    this.ghost = false,
    this.badgeCount,
    this.mirrorInRtl = false,
  });

  final OmeoIcons icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool small;
  final bool ghost;
  final bool mirrorInRtl;

  /// Nombre affiché en pastille ; rien si `null` ou 0.
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final side = small ? 36.0 : OmeoTokens.sizeTouchTarget;
    final count = badgeCount ?? 0;
    return Semantics(
      button: true,
      label: semanticLabel,
      container: true,
      excludeSemantics: true,
      // La cible tactile reste de 48 dp même quand le cercle est plus petit.
      child: SizedBox.square(
        dimension: OmeoTokens.space12,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: ghost ? Colors.transparent : t.surface,
                shape: CircleBorder(
                  side: ghost ? BorderSide.none : BorderSide(color: t.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onPressed,
                  child: SizedBox.square(
                    dimension: side,
                    child: Center(
                      child: OmeoIcon(
                        icon,
                        size: small ? 18 : 22,
                        color: t.text,
                        mirrorInRtl: mirrorInRtl,
                      ),
                    ),
                  ),
                ),
              ),
              if (count > 0)
                PositionedDirectional(
                  top: -3,
                  end: -3,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 19),
                    height: 19,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.accent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: t.bg, width: 2),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: OmeoTokens.weightBold,
                        color: Colors.white,
                        height: 1,
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
