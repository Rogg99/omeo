import 'package:flutter/widgets.dart';
import 'package:omeo/core/l10n/formatters.dart';
import 'package:omeo/core/l10n/gen/app_localizations.dart';
import 'package:omeo/core/units/units.dart';

/// Affichage des mesures dans les unités de l'utilisateur (D23) : la valeur
/// de l'API (métrique) est convertie, puis arrondie au dixième pour l'écran.
extension UnitFormat on BuildContext {
  String _one(double v) => number((v * 10).round() / 10);

  /// « 78,4 kg » ou « 172,8 lb ».
  String weight(num kg, UnitSystem system) {
    final l = AppLocalizations.of(this);
    final value = _one(Units.displayWeight(kg.toDouble(), system));
    return system == UnitSystem.metric
        ? l.appProfileUnitKg(value)
        : l.appProfileUnitLb(value);
  }

  /// Écart de poids signé : « −2,1 kg ».
  String signedWeight(num kg, UnitSystem system) {
    final l = AppLocalizations.of(this);
    final converted = Units.displayWeight(kg.toDouble(), system);
    final value = signedNumber((converted * 10).round() / 10);
    return system == UnitSystem.metric
        ? l.appProfileUnitKg(value)
        : l.appProfileUnitLb(value);
  }

  /// « 175 cm » ou « 5 ft 9 in ».
  String height(num cm, UnitSystem system) {
    final l = AppLocalizations.of(this);
    if (system == UnitSystem.metric) {
      return l.appProfileUnitCm(number(cm.round()));
    }
    final ft = Units.cmToFeetInches(cm.toDouble());
    return l.appProfileUnitFeetInches(ft.feet, ft.inches);
  }

  /// Eau (valeur API en ml) : « 260 cl » ou « 87,9 oz ».
  String water(num ml, UnitSystem system) {
    final l = AppLocalizations.of(this);
    final value = _one(Units.displayWater(ml, system));
    return system == UnitSystem.metric
        ? l.appProfileUnitCl(value)
        : l.appProfileUnitOz(value);
  }
}
