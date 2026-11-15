import 'package:intl/number_symbols.dart';
import 'package:intl/number_symbols_data.dart';

/// Les polices de l'app n'ont pas de glyphe pour l'espace fine insécable
/// (U+202F), séparateur de milliers du français et d'autres langues : le
/// chiffre « 1 450 » s'afficherait « 1450 ». On la remplace par l'espace
/// insécable (U+00A0), présente dans toutes nos polices. À appeler une fois
/// au démarrage, avant tout formatage.
void useRenderableGroupSeparators() {
  final narrowNbsp = String.fromCharCode(0x202F);
  final nbsp = String.fromCharCode(0x00A0);
  for (final entry in numberFormatSymbols.entries.toList()) {
    final s = entry.value;
    if (s.GROUP_SEP != narrowNbsp) continue;
    numberFormatSymbols[entry.key] = NumberSymbols(
      NAME: s.NAME,
      DECIMAL_SEP: s.DECIMAL_SEP,
      GROUP_SEP: nbsp,
      PERCENT: s.PERCENT,
      ZERO_DIGIT: s.ZERO_DIGIT,
      PLUS_SIGN: s.PLUS_SIGN,
      MINUS_SIGN: s.MINUS_SIGN,
      EXP_SYMBOL: s.EXP_SYMBOL,
      PERMILL: s.PERMILL,
      INFINITY: s.INFINITY,
      NAN: s.NAN,
      DECIMAL_PATTERN: s.DECIMAL_PATTERN,
      SCIENTIFIC_PATTERN: s.SCIENTIFIC_PATTERN,
      PERCENT_PATTERN: s.PERCENT_PATTERN,
      CURRENCY_PATTERN: s.CURRENCY_PATTERN,
      DEF_CURRENCY_CODE: s.DEF_CURRENCY_CODE,
    );
  }
}
