import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omeo/core/theme/omeo_theme.dart';

/// Règle horizontale à faire glisser (ONB-08), un trait par unité entière.
/// Lue comme un curseur par les lecteurs d'écran (augmenter / diminuer).
class RulerPicker extends StatefulWidget {
  const RulerPicker({
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    required this.semanticValue,
    super.key,
  });

  final int min;
  final int max;
  final int value;
  final ValueChanged<int> onChanged;

  /// Valeur lue (« 175 centimètres », « 5 pieds 9 pouces »).
  final String semanticValue;

  @override
  State<RulerPicker> createState() => _RulerPickerState();
}

class _RulerPickerState extends State<RulerPicker> {
  static const _tick = 11.0;
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: (widget.value - widget.min) * _tick,
  );
  int? _lastEmitted;

  @override
  void didUpdateWidget(RulerPicker old) {
    super.didUpdateWidget(old);
    // Valeur changée de l'extérieur (saisie au clavier) : on suit.
    if (widget.value != _lastEmitted && _scroll.hasClients) {
      _scroll.jumpTo((widget.value - widget.min) * _tick);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final v = (widget.min + _scroll.offset / _tick).round().clamp(
      widget.min,
      widget.max,
    );
    if (v == widget.value) return;
    _lastEmitted = v;
    unawaited(HapticFeedback.selectionClick());
    widget.onChanged(v);
  }

  void _step(int delta) {
    final v = (widget.value + delta).clamp(widget.min, widget.max);
    _lastEmitted = v;
    widget.onChanged(v);
    _scroll.jumpTo((v - widget.min) * _tick);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    return Semantics(
      slider: true,
      value: widget.semanticValue,
      onIncrease: () => _step(1),
      onDecrease: () => _step(-1),
      textDirection: Directionality.of(context),
      child: ExcludeSemantics(
        child: SizedBox(
          height: 70,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = constraints.maxWidth / 2;
              return Stack(
                alignment: Alignment.center,
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollUpdateNotification) _onScroll();
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      physics: const _SnapPhysics(_tick),
                      padding: EdgeInsets.symmetric(horizontal: side),
                      itemExtent: _tick,
                      itemCount: widget.max - widget.min + 1,
                      itemBuilder: (context, i) {
                        final v = widget.min + i;
                        final height = v % 10 == 0
                            ? 48.0
                            : v % 5 == 0
                            ? 34.0
                            : 22.0;
                        return Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 2,
                            height: height,
                            color: t.text3.withValues(
                              alpha: v % 5 == 0 ? 0.9 : 0.45,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  IgnorePointer(
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: t.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Défilement qui s'arrête toujours sur un trait.
class _SnapPhysics extends ScrollPhysics {
  const _SnapPhysics(this.tick, {super.parent});

  final double tick;

  @override
  _SnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapPhysics(tick, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final target = ((position.pixels + velocity * 0.12) / tick).round() * tick;
    final clamped = target.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((clamped - position.pixels).abs() < 0.5) return null;
    return ScrollSpringSimulation(
      SpringDescription.withDampingRatio(mass: 0.5, stiffness: 120),
      position.pixels,
      clamped,
      velocity,
    );
  }
}
