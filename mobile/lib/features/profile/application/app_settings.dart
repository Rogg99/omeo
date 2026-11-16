import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omeo/features/auth/data/local_store.dart';

/// Réglages d'affichage gardés sur le téléphone : ils s'appliquent avant la
/// connexion (choix de la langue, ONB-02) puis suivent les préférences du
/// compte.
@immutable
final class AppSettings {
  const AppSettings({
    this.languageCode,
    this.themeMode = ThemeMode.system,
    this.loaded = false,
  });

  /// `null` : langue du téléphone, pas encore choisie.
  final String? languageCode;
  final ThemeMode themeMode;

  /// Faux tant que les réglages enregistrés n'ont pas été relus.
  final bool loaded;

  bool get languageChosen => languageCode != null;

  AppSettings copyWith({String? languageCode, ThemeMode? themeMode}) =>
      AppSettings(
        languageCode: languageCode ?? this.languageCode,
        themeMode: themeMode ?? this.themeMode,
        loaded: loaded,
      );
}

class AppSettingsController extends Notifier<AppSettings> {
  static const _languageKey = 'omeo.settings.language';
  static const _themeKey = 'omeo.settings.theme';

  LocalStore get _store => ref.read(localStoreProvider);

  @override
  AppSettings build() {
    unawaited(_load());
    return const AppSettings();
  }

  Future<void> _load() async {
    final language = await _store.read(_languageKey);
    final theme = await _store.read(_themeKey);
    state = AppSettings(
      languageCode: language,
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == theme,
        orElse: () => ThemeMode.system,
      ),
      loaded: true,
    );
  }

  Future<void> setLanguage(String code) async {
    state = state.copyWith(languageCode: code);
    await _store.write(_languageKey, code);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _store.write(_themeKey, mode.name);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );
