# Nyam — Documentation projet

> « Scanne. Comprends. Mange mieux. »
> Application de suivi nutritionnel et sportif, pensée d'abord pour l'Afrique francophone, puis pour l'international.

## Livrables

| Livrable | Description |
|---|---|
| **API** | Backend unique pour le mobile, l'admin et le site |
| **Mobile** | Application Flutter (Android et iOS), produit principal |
| **Admin** | Back-office web multi-rôles |
| **Site web** | Vitrine et landing, avec une page de paiement web (pas d'espace utilisateur) |

## Sommaire

### Produit
- [Vision produit](produit/00-vision.md)
- [Catalogue des features](produit/01-catalogue-features.md)
- [Offres, prix & quotas](produit/02-offres-quotas.md)
- [Règles métier & calculs](produit/03-regles-metier.md)
- [Décisions & questions ouvertes](produit/99-decisions.md)

### Features de l'application mobile
1. [Onboarding & compte](produit/features/01-onboarding-compte.md)
2. [Saisie des repas](produit/features/02-saisie-repas.md)
3. [Suivi nutritionnel](produit/features/03-suivi-nutrition.md)
4. [Sport & activité](produit/features/04-sport-activite.md)
5. [Programmes & challenges](produit/features/05-programmes-challenges.md)
6. [Gamification](produit/features/06-gamification.md)
7. [Contenus](produit/features/07-contenus.md)
8. [Abonnement, paiement & parrainage](produit/features/08-abonnement-paiement.md)
9. [Notifications](produit/features/09-notifications.md)
10. [Profil, paramètres, langues & support](produit/features/10-profil-parametres-support.md)

### Plateformes
- [Admin](produit/admin.md)
- [Site web](produit/site-vitrine.md)

### Design
- Captures de référence : [Captures/](Captures/)
- Direction visuelle : [Vision produit › Identité visuelle](produit/00-vision.md#identité-visuelle)

### Technique
- Stack retenue : API **Django** (Django REST Framework, PostgreSQL, Celery + Redis), mobile **Flutter**, admin **Next.js**, site **Next.js**. Structure du dépôt : [README racine](../README.md).
- [Conventions de l'API](technique/conventions-api.md) : authentification, erreurs, pagination, idempotence, sécurité
- [Modèle de données](technique/modele-donnees.md)
- [Contrôle d'accès](technique/controle-acces.md) : permissions, step-up, validation à quatre yeux, droits Plus
- [Design tokens](technique/design-tokens.md) et [traductions](technique/i18n.md) : sources uniques dans [shared/](../shared/)
- Contrat d'API : [contracts/openapi.yaml](../contracts/openapi.yaml)
- Prompts de développement par livrable : [prompts/](prompts/)
