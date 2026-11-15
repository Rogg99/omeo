import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';

/// Durée d'animation, nulle quand l'utilisateur réduit les mouvements.
Duration motionDuration(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

/// Anneau de progression (`ring`). [progress] est une fraction 0–1 fournie
/// telle quelle par l'API (champ de pourcentage) : le widget ne calcule rien.
class OmeoRing extends StatelessWidget {
  const OmeoRing({
    required this.progress,
    required this.semanticLabel,
    super.key,
    this.size = 128,
    this.stroke = 12,
    this.color,
    this.trackColor,
    this.child,
  });

  final double progress;
  final double size;
  final double stroke;
  final Color? color;
  final Color? trackColor;
  final Widget? child;

  /// Valeur lue par le lecteur d'écran (ex. « 890 kcal restantes »).
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: RepaintBoundary(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress.clamp(0, 1)),
            duration: motionDuration(context, OmeoTokens.durationSlow),
            curve: OmeoTokens.ease,
            builder: (context, value, child) => CustomPaint(
              painter: _RingPainter(
                progress: value,
                stroke: stroke,
                color: color ?? t.primary,
                track: trackColor ?? t.surface2,
              ),
              child: child,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.stroke,
    required this.color,
    required this.track,
  });

  final double progress;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arc, 0, 2 * math.pi, false, paint..color = track);
    if (progress <= 0) return;
    canvas.drawArc(
      arc,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.track != track ||
      old.stroke != stroke;
}

/// Épaisseur d'une barre de progression (`.bar`, `.thin`, `.thick`).
enum BarThickness {
  thin(6),
  regular(8),
  thick(12)
  ;

  const BarThickness(this.height);
  final double height;
}

/// Barre de progression horizontale. [progress] vient de l'API (0–1).
class OmeoBar extends StatelessWidget {
  const OmeoBar({
    required this.progress,
    super.key,
    this.color,
    this.trackColor,
    this.thickness = BarThickness.regular,
  });

  /// Barre blanche sur fond coloré (`.bar.on-color`).
  const OmeoBar.onColor({
    required this.progress,
    super.key,
    this.thickness = BarThickness.thin,
  }) : color = Colors.white,
       trackColor = const Color(0x38FFFFFF);

  final double progress;
  final Color? color;
  final Color? trackColor;
  final BarThickness thickness;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final radius = BorderRadius.circular(thickness.height / 2);
    return ExcludeSemantics(
      child: Container(
        height: thickness.height,
        decoration: BoxDecoration(
          color: trackColor ?? t.surface2,
          borderRadius: radius,
        ),
        alignment: AlignmentDirectional.centerStart,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: progress.clamp(0, 1)),
          duration: motionDuration(context, OmeoTokens.durationSlow),
          curve: OmeoTokens.ease,
          builder: (context, value, _) => FractionallySizedBox(
            widthFactor: value,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color ?? t.primary,
                borderRadius: radius,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ligne de macronutriment (`macro`) : libellé, « valeur/objectif » déjà
/// formatés et barre fine. Toutes les valeurs viennent de l'API.
class MacroRow extends StatelessWidget {
  const MacroRow({
    required this.label,
    required this.valueText,
    required this.progress,
    required this.color,
    super.key,
  });

  final String label;

  /// Texte affiché à droite, par exemple « 84/128 g ».
  final String valueText;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '$label, $valueText',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: text.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                valueText,
                style: text.bodySmall?.copyWith(
                  fontSize: 13,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: OmeoTokens.space2),
          OmeoBar(
            progress: progress,
            color: color,
            thickness: BarThickness.thin,
          ),
        ],
      ),
    );
  }
}

/// Barre d'étapes (onboarding) : étapes faites, en cours et à venir.
class StepsBar extends StatelessWidget {
  const StepsBar({
    required this.current,
    required this.total,
    required this.semanticLabel,
    super.key,
  });

  /// Étape en cours, à partir de 1.
  final int current;
  final int total;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 1; i <= total; i++) ...[
            if (i > 1) const SizedBox(width: 5),
            Expanded(
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: i == current
                      ? null
                      : (i < current ? t.primary : t.surface2),
                  // L'étape en cours est à moitié remplie, dans le sens de
                  // lecture.
                  gradient: i == current
                      ? LinearGradient(
                          begin: AlignmentDirectional.centerStart.resolve(
                            Directionality.of(context),
                          ),
                          end: AlignmentDirectional.centerEnd.resolve(
                            Directionality.of(context),
                          ),
                          colors: [
                            t.primary,
                            t.primary,
                            t.surface2,
                            t.surface2,
                          ],
                          stops: const [0, 0.5, 0.5, 1],
                        )
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Indicateur de chargement circulaire (`.spinner`).
class OmeoSpinner extends StatelessWidget {
  const OmeoSpinner({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: 4,
        color: t.primary,
        backgroundColor: t.primarySoft,
        // Mouvements réduits : anneau fixe au quart.
        value: MediaQuery.disableAnimationsOf(context) ? 0.25 : null,
      ),
    );
  }
}
