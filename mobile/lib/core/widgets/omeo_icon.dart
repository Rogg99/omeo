import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/omeo_icons.g.dart';

export 'package:omeo/core/widgets/omeo_icons.g.dart';

/// Icône des maquettes : trait 1,75, couleur héritée de [IconTheme].
///
/// Les icônes directionnelles (chevrons, flèches) passent [mirrorInRtl] pour
/// être retournées en arabe.
class OmeoIcon extends StatelessWidget {
  const OmeoIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.strokeWidth = 1.75,
    this.mirrorInRtl = false,
  });

  final OmeoIcons icon;
  final double? size;
  final Color? color;
  final double strokeWidth;
  final bool mirrorInRtl;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? 22;
    final svg = SvgPicture.string(
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" '
      'stroke-width="$strokeWidth" stroke-linecap="round" '
      'stroke-linejoin="round">${icon.paths}</svg>',
      width: side,
      height: side,
      theme: SvgTheme(
        currentColor: color ?? theme.color ?? const Color(0xFF000000),
      ),
      excludeFromSemantics: true,
    );
    final rtl = Directionality.of(context) == TextDirection.rtl;
    if (!(mirrorInRtl && rtl)) return svg;
    return Transform.flip(flipX: true, child: svg);
  }
}

/// Logo Omeo : disque croqué, suivi ou non du mot « omeo ».
class OmeoLogo extends StatelessWidget {
  const OmeoLogo({
    super.key,
    this.size = 34,
    this.color,
    this.withText = true,
  });

  final double size;
  final Color? color;
  final bool withText;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? DefaultTextStyle.of(context).style.color!;
    final hex = ink.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
    final mark = SvgPicture.string(
      '<svg viewBox="0 0 64 64"><path d="$omeoLogoPath" fill="#$hex"/></svg>',
      width: size,
      height: size,
      excludeFromSemantics: true,
    );
    // Le nom de marque n'est pas traduit : il est lu comme un libellé unique.
    return Semantics(
      label: 'Omeo',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          if (withText) ...[
            SizedBox(width: size * 0.18),
            Text(
              'omeo',
              style: TextStyle(
                fontFamily: OmeoTokens.fontDisplay,
                fontSize: size * 0.62,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: -0.04 * size * 0.62,
                color: ink,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
