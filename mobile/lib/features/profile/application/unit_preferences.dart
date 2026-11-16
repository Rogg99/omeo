import 'package:omeo/core/units/units.dart';
import 'package:omeo_api/omeo_api.dart';

/// Systèmes d'unités choisis par l'utilisateur (PRF-08). Métrique par
/// défaut ; l'API stocke tout en métrique (D23).
extension UnitPreferences on MePreferences {
  UnitSystem get weightSystem => unitWeight == MePreferencesUnitWeightEnum.lb
      ? UnitSystem.imperial
      : UnitSystem.metric;

  UnitSystem get heightSystem => unitHeight == MePreferencesUnitHeightEnum.ft
      ? UnitSystem.imperial
      : UnitSystem.metric;

  UnitSystem get volumeSystem => unitVolume == MePreferencesUnitVolumeEnum.oz
      ? UnitSystem.imperial
      : UnitSystem.metric;
}
