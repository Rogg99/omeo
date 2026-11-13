import 'package:flutter_test/flutter_test.dart';
import 'package:omeo/core/units/units.dart';

void main() {
  group('poids', () {
    test('kg vers lb', () {
      expect(Units.kgToLb(1), closeTo(2.20462, 1e-5));
      expect(Units.kgToLb(72.5), closeTo(159.835, 1e-3));
    });

    test('aller-retour sans perte', () {
      expect(Units.lbToKg(Units.kgToLb(68.4)), closeTo(68.4, 1e-9));
    });

    test('zéro reste zéro', () {
      expect(Units.kgToLb(0), 0);
      expect(Units.lbToKg(0), 0);
    });

    test('affichage et saisie selon le système', () {
      expect(Units.displayWeight(70, UnitSystem.metric), 70);
      expect(
        Units.displayWeight(70, UnitSystem.imperial),
        closeTo(154.32, 1e-2),
      );
      expect(Units.weightToApi(70, UnitSystem.metric), 70);
      expect(Units.weightToApi(154.32, UnitSystem.imperial), closeTo(70, 1e-2));
    });
  });

  group('taille', () {
    test('cm vers pieds et pouces', () {
      expect(Units.cmToFeetInches(170), (feet: 5, inches: 7));
      expect(Units.cmToFeetInches(152.4), (feet: 5, inches: 0));
    });

    test('12 pouces arrondis passent au pied suivant', () {
      expect(Units.cmToFeetInches(182.6), (feet: 6, inches: 0));
    });

    test('pieds et pouces vers cm', () {
      expect(Units.feetInchesToCm(feet: 5, inches: 7), closeTo(170.18, 1e-9));
      expect(Units.feetInchesToCm(feet: 0, inches: 0), 0);
    });
  });

  group('volume', () {
    test('cl vers oz', () {
      expect(Units.clToOz(25), closeTo(8.4535, 1e-4));
    });

    test('aller-retour sans perte', () {
      expect(Units.ozToCl(Units.clToOz(33)), closeTo(33, 1e-9));
    });

    test('affichage et saisie selon le système', () {
      expect(Units.displayVolume(50, UnitSystem.metric), 50);
      expect(
        Units.volumeToApi(
          Units.displayVolume(50, UnitSystem.imperial),
          UnitSystem.imperial,
        ),
        closeTo(50, 1e-9),
      );
    });
  });
}
