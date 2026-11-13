/// Conversion d'unités pour l'affichage et la saisie (décision D23).
///
/// L'API stocke et renvoie tout en métrique. C'est le seul endroit du client
/// où une valeur numérique est transformée : on convertit, sans aucun calcul
/// métier.
library;

/// Système d'unités choisi par l'utilisateur.
enum UnitSystem { metric, imperial }

/// Pieds et pouces, pour l'affichage d'une taille en impérial.
typedef FeetInches = ({int feet, int inches});

abstract final class Units {
  static const double _kgPerLb = 0.45359237;
  static const double _cmPerInch = 2.54;
  static const int _inchesPerFoot = 12;
  static const double _clPerFlOz = 2.95735295625;

  /// Kilogrammes vers livres.
  static double kgToLb(double kg) => kg / _kgPerLb;

  /// Livres vers kilogrammes (saisie).
  static double lbToKg(double lb) => lb * _kgPerLb;

  /// Centimètres vers pieds et pouces, au pouce le plus proche.
  /// 12 pouces arrondis passent au pied suivant (182,9 cm → 6 ft 0 in).
  static FeetInches cmToFeetInches(double cm) {
    final totalInches = (cm / _cmPerInch).round();
    return (
      feet: totalInches ~/ _inchesPerFoot,
      inches: totalInches % _inchesPerFoot,
    );
  }

  /// Pieds et pouces vers centimètres (saisie).
  static double feetInchesToCm({required int feet, required double inches}) =>
      (feet * _inchesPerFoot + inches) * _cmPerInch;

  /// Centilitres vers onces liquides US.
  static double clToOz(double cl) => cl / _clPerFlOz;

  /// Onces liquides US vers centilitres (saisie).
  static double ozToCl(double oz) => oz * _clPerFlOz;

  /// Poids affiché dans le système choisi (valeur API en kg).
  static double displayWeight(double kg, UnitSystem system) =>
      system == UnitSystem.metric ? kg : kgToLb(kg);

  /// Poids saisi dans le système choisi, renvoyé en kg pour l'API.
  static double weightToApi(double value, UnitSystem system) =>
      system == UnitSystem.metric ? value : lbToKg(value);

  /// Volume affiché dans le système choisi (valeur API en cl).
  static double displayVolume(double cl, UnitSystem system) =>
      system == UnitSystem.metric ? cl : clToOz(cl);

  /// Volume saisi dans le système choisi, renvoyé en cl pour l'API.
  static double volumeToApi(double value, UnitSystem system) =>
      system == UnitSystem.metric ? value : ozToCl(value);
}
