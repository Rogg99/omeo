import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Mise en forme des valeurs renvoyées par l'API, dans la langue de l'écran.
/// Aucune opération sur les valeurs : uniquement leur présentation.
extension OmeoFormat on BuildContext {
  String get _locale => Localizations.localeOf(this).toLanguageTag();

  /// Entier avec séparateur de milliers (« 1 450 »).
  String number(num value) =>
      NumberFormat.decimalPattern(_locale).format(value);

  /// Entier signé avec le vrai signe moins (« −1 160 », « +180 »), isolé en
  /// gauche à droite pour que le signe reste devant le nombre en arabe.
  String signedNumber(num value) {
    final formatted = number(value.abs());
    if (value == 0) return formatted;
    final sign = value < 0 ? String.fromCharCode(0x2212) : '+';
    final isolate = String.fromCharCode(0x2066);
    final popIsolate = String.fromCharCode(0x2069);
    return '$isolate$sign$formatted$popIsolate';
  }

  /// « lundi 9 novembre ».
  String longDate(DateTime date) => DateFormat.MMMMEEEEd(_locale).format(date);

  /// « jeu. 5 nov. ».
  String shortDate(DateTime date) => DateFormat.MMMEd(_locale).format(date);
}
