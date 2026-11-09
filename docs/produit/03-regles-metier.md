# Règles métier & calculs

> **Tous ces calculs sont faits exclusivement par l'API.** Le mobile n'en fait aucun : il envoie les données et affiche les résultats.
>
> Valeurs de départ, à faire valider par un ou une nutritionniste. Toutes les constantes se règlent dans l'admin.

## Objectif calorique quotidien
1. **Métabolisme de base** (formule de Mifflin-St Jeor) :
   - homme : `10 × poids (kg) + 6,25 × taille (cm) − 5 × âge + 5`
   - femme : `10 × poids (kg) + 6,25 × taille (cm) − 5 × âge − 161`
2. **Dépense de base** = métabolisme × 1,2 (profil sédentaire, en attendant des données d'activité).
3. **Selon l'objectif** :
   - perdre du poids : −15 à −20 %, sans descendre sous 1 200 kcal (femme) ou 1 500 kcal (homme) ;
   - prendre de la masse : +10 à +15 % ;
   - manger équilibré ou prévention : pas d'ajustement.
4. **Selon l'activité du jour** : quand les calories dépensées importées dépassent la dépense de base, la moitié de l'excédent s'ajoute à l'objectif. L'utilisateur peut désactiver cet ajustement.

## Répartition des macronutriments

| Objectif | Protéines | Glucides | Lipides |
|---|---|---|---|
| Perdre du poids | 1,6 à 2 g par kg | le reste | 25 à 30 % des calories |
| Prendre de la masse | 1,8 à 2,2 g par kg | le reste | 25 % des calories |
| Manger équilibré | 1,2 à 1,6 g par kg | 45 à 55 % des calories | 30 % des calories |

## Autres repères
- **Eau** : 30 à 35 ml par kg et par jour, plus 50 cl par heure d'activité.
- **Fibres** : 25 g par jour pour une femme, 30 à 38 g pour un homme.
- **Sel** : moins de 5 g par jour (recommandation de l'OMS).

## Règles générales
- Les objectifs sont recalculés à chaque nouveau poids ou modification du profil.
- Si le poids cible contredit l'objectif choisi (vouloir perdre du poids avec une cible plus haute que son poids actuel), on avertit l'utilisateur.
- Une journée correspond à la journée locale de l'utilisateur.
- Le type de repas (petit-déjeuner, déjeuner, collation, dîner) est proposé selon l'heure et reste modifiable.
