# Évolutions du contrat

Toute modification de [openapi.yaml](openapi.yaml) est d'abord proposée ici, puis validée avant d'être appliquée dans un commit dédié. Les clients (TypeScript et Dart) sont ensuite régénérés.

| Date | Endpoint / schéma | Changement | Raison | Compatible ? | Statut |
|---|---|---|---|---|---|
| 2026-11-09 | /admin/*, /auth/mfa/step-up, /admin/approvals | x-permission partout, step-up, quatre yeux (202 et ApprovalRequest), x-entitlement, x-quota, x-email-verified | Contrôle d'accès (D26 à D31) | Oui (ajouts) | Validé |
| 2026-11-09 | — | Version initiale 1.0.0 (142 chemins, 169 opérations) | Contrat cible avant développement | — | Validé |
