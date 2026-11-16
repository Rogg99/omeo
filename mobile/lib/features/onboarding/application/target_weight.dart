/// Avertissement « poids cible » de l'étape 7 (décision D22) : seule
/// exception à la règle D1 avec la conversion d'unités. Le calcul est un
/// écart d'affichage, avant la création du compte et sans appel à l'API.
library;

/// Écart entre la cible et le poids actuel, dans l'unité saisie.
typedef TargetWeightAdvice = ({
  /// Cible moins poids actuel, arrondi au dixième (signe conservé).
  double difference,

  /// Vrai si la cible est plus haute que le poids actuel : avertissement
  /// non bloquant, l'objectif sera précisé à l'étape suivante.
  bool aboveCurrent,
});

/// `null` tant qu'une des deux valeurs manque.
TargetWeightAdvice? targetWeightAdvice({
  required double? current,
  required double? target,
}) {
  if (current == null || target == null) return null;
  final difference = ((target - current) * 10).round() / 10;
  return (difference: difference, aboveCurrent: difference > 0);
}
