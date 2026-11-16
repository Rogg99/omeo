import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/core/api/api_failure.dart';
import 'package:omeo/core/api/api_providers.dart';
import 'package:omeo/features/meals/data/meals_repository.dart';
import 'package:omeo/features/meals/data/photo_compressor.dart';
import 'package:omeo_api/omeo_api.dart';
import 'package:uuid/uuid.dart';

/// Étape visible du parcours d'analyse (MEA-03).
enum AnalysisStep { preparing, uploading, queued, processing }

/// État du parcours : en cours (avec l'étape), terminé (analyse réussie ou
/// photo inexploitable) ou en erreur selon le code de l'API.
sealed class AnalysisFlowState {
  const AnalysisFlowState();
}

final class AnalysisRunning extends AnalysisFlowState {
  const AnalysisRunning(this.step);
  final AnalysisStep step;
}

final class AnalysisDone extends AnalysisFlowState {
  const AnalysisDone(this.analysis);
  final Analysis analysis;

  /// Photo floue ou sans nourriture (MEA-08) : non décomptée par l'API.
  bool get unusable => analysis.status == AnalysisStatusEnum.failed;
}

final class AnalysisError extends AnalysisFlowState {
  const AnalysisError(this.failure);
  final Object failure;
}

/// Délai d'interrogation quand l'API n'envoie pas Retry-After.
const defaultPollInterval = Duration(seconds: 2);

/// Pilote une analyse photo ou texte jusqu'à son résultat. Annulable : un
/// [cancel] arrête l'interrogation (SYS-07).
class AnalysisController extends Notifier<AnalysisFlowState> {
  static const _uuid = Uuid();
  bool _cancelled = false;

  @override
  AnalysisFlowState build() {
    ref.onDispose(cancel);
    return const AnalysisRunning(AnalysisStep.preparing);
  }

  MealsRepository get _repo => ref.read(mealsRepositoryProvider);

  void cancel() => _cancelled = true;

  /// Photo prise ou choisie : compression, envoi présigné puis analyse.
  Future<void> analyzePhoto(Uint8List original) => _run(() async {
    final bytes = await compressPhoto(original);
    if (_cancelled) return null;
    state = const AnalysisRunning(AnalysisStep.uploading);
    final ticket = await _repo.createPhotoUpload(
      size: bytes.length,
      idempotencyKey: _uuid.v4(),
    );
    await _repo.uploadPhoto(ticket, bytes);
    if (_cancelled) return null;
    return _repo.createPhotoAnalysis(
      uploadId: ticket.id,
      idempotencyKey: _uuid.v4(),
    );
  });

  /// Saisie vocale (transcrite sur l'appareil) ou texte libre.
  Future<void> analyzeText(String text) => _run(
    () => _repo.createTextAnalysis(text: text, idempotencyKey: _uuid.v4()),
  );

  Future<void> _run(Future<Analysis?> Function() create) async {
    _cancelled = false;
    state = const AnalysisRunning(AnalysisStep.preparing);
    try {
      var analysis = await create();
      while (analysis != null && !_cancelled && !_finished(analysis)) {
        state = AnalysisRunning(
          analysis.status == AnalysisStatusEnum.queued
              ? AnalysisStep.queued
              : AnalysisStep.processing,
        );
        final poll = await _repo.getAnalysis(analysis.id);
        analysis = poll.analysis;
        if (_finished(analysis) || _cancelled) break;
        await Future<void>.delayed(poll.retryAfter ?? defaultPollInterval);
      }
      if (analysis != null && !_cancelled) state = AnalysisDone(analysis);
    } on UnreadablePhotoException catch (e) {
      if (!_cancelled) state = AnalysisError(e);
    } on ApiFailure catch (e) {
      // Quota, Plus requis… : la racine de l'app présente la feuille dédiée.
      ref.read(globalErrorBusProvider).report(e);
      if (!_cancelled) state = AnalysisError(e);
    }
  }

  static bool _finished(Analysis a) =>
      a.status == AnalysisStatusEnum.succeeded ||
      a.status == AnalysisStatusEnum.failed;
}

/// Parcours d'analyse en cours (un seul à la fois).
final NotifierProvider<AnalysisController, AnalysisFlowState>
analysisControllerProvider =
    NotifierProvider.autoDispose<AnalysisController, AnalysisFlowState>(
      AnalysisController.new,
    );
