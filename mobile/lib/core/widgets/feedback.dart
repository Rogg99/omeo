import 'dart:async';

import 'package:flutter/material.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/theme/tokens.g.dart';
import 'package:omeo/core/widgets/buttons.dart';
import 'package:omeo/core/widgets/omeo_icon.dart';

/// Ouvre une feuille modale (`sheet`) : poignée, titre, fermeture, contenu.
Future<T?> showOmeoSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  String? closeLabel,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => OmeoSheet(
      title: title,
      closeLabel: closeLabel,
      child: builder(context),
    ),
  );
}

/// Contenu d'une feuille modale, utilisable seul dans les tests.
class OmeoSheet extends StatelessWidget {
  const OmeoSheet({
    required this.child,
    super.key,
    this.title,
    this.closeLabel,
  });

  final String? title;
  final String? closeLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          34 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          title!,
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(fontSize: 21),
                        ),
                      ),
                    ),
                    if (closeLabel != null)
                      OmeoIconButton(
                        icon: OmeoIcons.x,
                        small: true,
                        semanticLabel: closeLabel!,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                  ],
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

/// Bloc de chargement animé (`.skeleton`), fixe si les mouvements sont réduits.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = 12});

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // Reflet qui balaie le bloc de gauche à droite.
            final x = -3 + 4 * _controller.value;
            return Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                gradient: LinearGradient(
                  begin: Alignment(x, 0),
                  end: Alignment(x + 2, 0),
                  colors: [t.surface2, t.surface, t.surface2],
                  tileMode: TileMode.mirror,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Affiche un message court (`toast`) en bas de l'écran.
void showOmeoToast(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  OmeoIcons? icon,
}) {
  final t = context.omeo;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        content: Row(
          children: [
            if (icon != null) ...[
              OmeoIcon(icon, size: 20, color: t.onContrast),
              const SizedBox(width: OmeoTokens.space3),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: t.accent,
                onPressed: onAction ?? () {},
              ),
      ),
    );
}

/// État vide ou d'erreur d'un écran : pastille, titre, texte et action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    super.key,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final OmeoIcons icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.omeo;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.surface2,
              borderRadius: BorderRadius.circular(24),
            ),
            child: OmeoIcon(icon, size: 30, color: t.text2),
          ),
          const SizedBox(height: OmeoTokens.space5),
          Text(title, textAlign: TextAlign.center, style: text.headlineSmall),
          if (message != null) ...[
            const SizedBox(height: OmeoTokens.space2),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: t.text2),
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: OmeoTokens.space6),
            OmeoButton(
              label: actionLabel!,
              onPressed: onAction,
              size: OmeoButtonSize.medium,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}
