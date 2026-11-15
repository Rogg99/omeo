import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:omeo/core/theme/omeo_theme.dart';

// Les graphiques ne font que placer des points : les valeurs viennent de l'API
// et l'échelle verticale (maximum + 15 %) est une marge d'affichage.

/// Courbe avec aire dégradée et ligne d'objectif facultative (`line`).
class OmeoLineChart extends StatelessWidget {
  const OmeoLineChart({
    required this.values,
    required this.semanticLabel,
    super.key,
    this.goal,
    this.height = 150,
    this.color,
  });

  final List<double> values;
  final double? goal;
  final double height;
  final Color? color;

  /// Résumé lu par le lecteur d'écran (ex. « Poids : 72,4 kg, en baisse »).
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _LinePainter(
              values: values,
              goal: goal,
              color: color ?? t.primary,
              goalColor: t.accent,
              dotFill: t.surface,
              rtl: Directionality.of(context) == TextDirection.rtl,
            ),
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({
    required this.values,
    required this.goal,
    required this.color,
    required this.goalColor,
    required this.dotFill,
    required this.rtl,
  });

  final List<double> values;
  final double? goal;
  final Color color;
  final Color goalColor;
  final Color dotFill;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final top = [...values, ?goal].reduce(math.max) * 1.15;
    if (top <= 0) return;
    double x(int i) {
      final p = i / (values.length - 1) * size.width;
      return rtl ? size.width - p : p;
    }

    double y(double v) => size.height - v / top * size.height;

    if (goal != null) {
      final gy = y(goal!);
      final dash = Paint()
        ..color = goalColor
        ..strokeWidth = 1.5;
      for (var dx = 0.0; dx < size.width; dx += 10) {
        canvas.drawLine(
          Offset(dx, gy),
          Offset(math.min(dx + 5, size.width), gy),
          dash,
        );
      }
    }

    final line = Path()..moveTo(x(0), y(values.first));
    for (var i = 1; i < values.length; i++) {
      line.lineTo(x(i), y(values[i]));
    }
    final area = Path.from(line)
      ..lineTo(x(values.length - 1), size.height)
      ..lineTo(x(0), size.height)
      ..close();

    canvas
      ..drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
          ).createShader(Offset.zero & size),
      )
      ..drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round,
      );

    final last = Offset(x(values.length - 1), y(values.last));
    canvas
      ..drawCircle(last, 5, Paint()..color = dotFill)
      ..drawCircle(
        last,
        5,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values != values ||
      old.goal != goal ||
      old.color != color ||
      old.rtl != rtl;
}

/// Histogramme vertical (`bars`) : une barre par jour, aujourd'hui en noir.
class OmeoBarChart extends StatelessWidget {
  const OmeoBarChart({
    required this.values,
    required this.labels,
    required this.semanticLabel,
    super.key,
    this.highlightIndex,
    this.height = 140,
    this.color,
  }) : assert(values.length == labels.length, 'Une étiquette par valeur.');

  final List<double> values;
  final List<String> labels;

  /// Barre mise en avant ; par défaut la dernière (aujourd'hui).
  final int? highlightIndex;
  final double height;
  final Color? color;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final top = values.isEmpty ? 0.0 : values.reduce(math.max) * 1.1;
    final highlight = highlightIndex ?? values.length - 1;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 11,
      letterSpacing: 0,
      fontWeight: FontWeight.w600,
    );
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < values.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: top <= 0
                                ? 0.03
                                : math.max(0.03, values[i] / top),
                            widthFactor: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: i == highlight
                                    ? t.contrast
                                    : (color ?? t.primary),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                  bottom: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(labels[i], style: labelStyle, maxLines: 1),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
