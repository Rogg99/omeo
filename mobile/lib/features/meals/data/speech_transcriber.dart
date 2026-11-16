import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Pourquoi la dictée ne peut pas démarrer.
enum TranscriberUnavailable { denied, unsupported }

/// Transcription vocale sur l'appareil (D24) : aucune voix ne quitte le
/// téléphone, seul le texte transcrit est envoyé à l'analyse.
abstract interface class SpeechTranscriber {
  /// Prépare la dictée (demande la permission du micro au premier appel).
  /// Renvoie `null` si elle est prête.
  Future<TranscriberUnavailable?> prepare();

  /// Démarre l'écoute dans la langue [localeTag]. [onText] reçoit la
  /// transcription en direct, [onLevel] le niveau sonore (0 à 1),
  /// [onStopped] la fin de l'écoute.
  Future<void> start({
    required String localeTag,
    required void Function(String text) onText,
    required void Function(double level) onLevel,
    required void Function() onStopped,
  });

  Future<void> stop();
}

/// Implémentation réelle (speech_to_text), en reconnaissance locale.
final class DeviceSpeechTranscriber implements SpeechTranscriber {
  final _speech = SpeechToText();
  void Function()? _onStopped;

  @override
  Future<TranscriberUnavailable?> prepare() async {
    var denied = false;
    final ready = await _speech.initialize(
      onError: (e) {
        if (e.errorMsg.contains('permission')) denied = true;
        _onStopped?.call();
      },
      onStatus: (status) {
        if (status == SpeechToText.doneStatus ||
            status == SpeechToText.notListeningStatus) {
          _onStopped?.call();
        }
      },
    );
    if (ready) return null;
    final allowed = await _speech.hasPermission;
    return denied || !allowed
        ? TranscriberUnavailable.denied
        : TranscriberUnavailable.unsupported;
  }

  @override
  Future<void> start({
    required String localeTag,
    required void Function(String text) onText,
    required void Function(double level) onLevel,
    required void Function() onStopped,
  }) async {
    _onStopped = onStopped;
    await _speech.listen(
      onResult: (r) => onText(r.recognizedWords),
      // Niveau en décibels relatifs (environ −2 à 10), ramené à 0..1 pour
      // l'animation des barres.
      onSoundLevelChange: (db) => onLevel(((db + 2) / 12).clamp(0, 1)),
      listenOptions: SpeechListenOptions(
        onDevice: true,
        localeId: localeTag.replaceAll('-', '_'),
        listenMode: ListenMode.dictation,
      ),
    );
  }

  @override
  Future<void> stop() => _speech.stop();
}

final speechTranscriberProvider = Provider<SpeechTranscriber>(
  (ref) => DeviceSpeechTranscriber(),
);
