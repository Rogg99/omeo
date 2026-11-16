import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/theme/omeo_theme.dart';
import 'package:omeo/core/widgets/widgets.dart';
import 'package:omeo/features/training/application/training_controller.dart';
import 'package:omeo_api/omeo_api.dart' show Media;
import 'package:video_player/video_player.dart';

/// Vidéo courte d'un exercice, en boucle et sans son : HLS, ou fichier
/// téléchargé pour le hors connexion. Sous-titres WebVTT dans la langue de
/// l'app quand ils existent. Sans vidéo (hors connexion, erreur), l'affiche
/// reste visible.
class ExerciseVideo extends ConsumerStatefulWidget {
  const ExerciseVideo({
    required this.exerciseId,
    required this.media,
    super.key,
    this.autoplay = true,
    this.fit = BoxFit.cover,
  });

  final String exerciseId;
  final Media media;
  final bool autoplay;
  final BoxFit fit;

  @override
  ConsumerState<ExerciseVideo> createState() => _ExerciseVideoState();
}

class _ExerciseVideoState extends ConsumerState<ExerciseVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  @override
  void didUpdateWidget(ExerciseVideo old) {
    super.didUpdateWidget(old);
    if (old.exerciseId != widget.exerciseId) {
      final previous = _controller;
      _controller = null;
      _failed = false;
      unawaited(previous?.dispose());
      unawaited(_open());
    }
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  Future<ClosedCaptionFile>? _captions(String languageCode) {
    final subtitles = widget.media.subtitles ?? const [];
    final match = subtitles
        .where((s) => s.locale?.value == languageCode && s.url != null)
        .firstOrNull;
    if (match == null) return null;
    return Dio()
        .get<String>(match.url!)
        .then((r) => WebVTTCaptionFile(r.data ?? ''));
  }

  Future<void> _open() async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final local = await ref
        .read(workoutDownloadsProvider)
        .localVideo(widget.exerciseId);
    final controller = local != null
        ? VideoPlayerController.file(
            local,
            closedCaptionFile: _captions(languageCode),
          )
        : VideoPlayerController.networkUrl(
            Uri.parse(widget.media.hlsUrl),
            formatHint: VideoFormat.hls,
            closedCaptionFile: _captions(languageCode),
          );
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      if (widget.autoplay) await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } on Object {
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.omeo;
    final controller = _controller;
    final poster = widget.media.poster;
    final placeholder = Stack(
      fit: StackFit.expand,
      children: [
        if (poster != null)
          Image.network(
            poster.url,
            fit: widget.fit,
            errorBuilder: (_, _, _) => ColoredBox(color: t.infoSoft),
          )
        else
          ColoredBox(color: t.infoSoft),
        Center(
          child: _failed
              ? Semantics(
                  label: l.appTrainingVideoUnavailable,
                  child: OmeoIcon(OmeoIcons.play, size: 40, color: t.text3),
                )
              : const OmeoSpinner(),
        ),
      ],
    );
    if (controller == null) return placeholder;
    return Semantics(
      label: l.appTrainingPlayVideo,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: widget.fit,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
          // Le sous-titre suit la lecture.
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: controller,
            builder: (context, value, _) => Align(
              alignment: Alignment.bottomCenter,
              child: ClosedCaption(text: value.caption.text),
            ),
          ),
        ],
      ),
    );
  }
}
