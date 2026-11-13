# Évolutions du contrat

Toute modification de [openapi.yaml](openapi.yaml) est d'abord proposée ici, puis validée avant d'être appliquée dans un commit dédié. Les clients (TypeScript et Dart) sont ensuite régénérés.

| Date | Endpoint / schéma | Changement | Raison | Compatible ? | Statut |
|---|---|---|---|---|---|
| 2026-11-13 | PUT /me/analyses/{id}/feedback (FeedbackInput) | Ajout de `corrected_dish_label` facultatif (string, 80 caractères max), attendu quand `reason = wrong_dish` | Alimenter les règles de confusion de foodscan (D37) | Oui (ajout facultatif) | Validé (1.1.0) |
| 2026-11-13 | Analysis, nouveau schéma AnalysisAlternative | Ajout de `alternatives` (0 à 3, triées par probabilité décroissante) : `label` (string), `dish` (DishSummary ou null si absent du catalogue), `probability_percent` (entier 0 à 100, arrondi par l'API) | Rubrique « Pas satisfait ? » de l'écran de vérification ([02-saisie-repas.md](../docs/produit/features/02-saisie-repas.md)) | Oui (ajout) | Validé (1.1.0) |
| 2026-11-13 | POST /me/analyses/{id}/dish (nouveau) | Corps : `dish_id` (uuid). Remplace le plat de l'analyse par un plat du catalogue (une alternative ou un plat trouvé par recherche), recharge sa composition type, recalcule `items` et `totals`, enregistre l'avis `wrong_dish` (foodscan.submit_review). Réponse 200 : Analysis. Sans appel à l'IA ni décompte de quota. Idempotency-Key. 409 si l'analyse n'est pas `succeeded` ou est déjà liée à un repas | Corriger la détection en un geste | Oui (ajout) | Validé (1.1.0) |
| 2026-11-09 | /admin/*, /auth/mfa/step-up, /admin/approvals | x-permission partout, step-up, quatre yeux (202 et ApprovalRequest), x-entitlement, x-quota, x-email-verified | Contrôle d'accès (D26 à D31) | Oui (ajouts) | Validé |
| 2026-11-09 | — | Version initiale 1.0.0 (142 chemins, 169 opérations) | Contrat cible avant développement | — | Validé |
