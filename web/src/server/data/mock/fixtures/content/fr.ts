import { LEGAL_FR } from "./legal-fr";
import type { LocalizedContent } from "./types";
import { FAQ_IDS } from "./ids";

export const fr: LocalizedContent = {
  planNames: { free: "Free", plus_annual: "Omeo Plus annuel", plus_monthly: "Omeo Plus mensuel" },
  comparison: [
    { feature: "photo_analysis", label: "Analyses photo", trial: "28", free: "3 / jour", plus: "140 / mois" },
    { feature: "text_analysis", label: "Saisie vocale ou texte", trial: "10", free: "—", plus: "140 / mois" },
    { feature: "dish_catalog", label: "Plats du catalogue", trial: "Illimité", free: "Illimité", plus: "Illimité" },
    { feature: "health_sync", label: "Suivi Health Connect / Apple Health", trial: "✓", free: "✓", plus: "✓" },
    { feature: "progress_long_range", label: "Progression", trial: "30 j · 90 j · 1 an", free: "7 jours", plus: "30 j · 90 j · 1 an" },
    { feature: "workouts", label: "Séances vidéo", trial: "Toutes", free: "Sélection", plus: "Toutes + hors connexion" },
    { feature: "programs", label: "Programmes", trial: "✓", free: "—", plus: "✓" },
    { feature: "challenges_active", label: "Challenges en parallèle", trial: "1", free: "1", plus: "Illimité" },
    { feature: "recipes", label: "Recettes", trial: "Toutes", free: "Sélection", plus: "Toutes" },
    { feature: "insights", label: "Prévention", trial: "Détaillés + bilan hebdo", free: "Conseils de base", plus: "Détaillés + bilan hebdo" },
    { feature: "streak_freeze", label: "Jour de série couvert", trial: "—", free: "—", plus: "1 / semaine" },
  ],
  faq: [
    {
      category: "Analyses photo",
      items: [
        {
          id: FAQ_IDS.dishes,
          question: "Quels plats Omeo reconnaît-il ?",
          answer:
            "Des centaines de plats d'Afrique de l'Ouest et centrale (ndolé, thiéboudienne, attiéké, garba, yassa, sauce gombo…) et de plus en plus de plats du monde. La base grandit chaque semaine grâce à vos avis.",
        },
        {
          id: FAQ_IDS.wrong,
          question: "L'analyse s'est trompée, que faire ?",
          answer:
            "Corrige les ingrédients et les quantités avant d'enregistrer, puis donne ton avis. L'équipe s'en sert pour améliorer la reconnaissance.",
        },
        {
          id: FAQ_IDS.blurry,
          question: "Une photo floue compte-t-elle dans mon quota ?",
          answer: "Non. Une analyse qui échoue n'est **jamais** décomptée.",
        },
      ],
    },
    {
      category: "Abonnement",
      items: [
        {
          id: FAQ_IDS.free,
          question: "Est-ce que c'est gratuit ?",
          answer:
            "Oui. Free inclut 3 analyses photo par jour et tout le suivi. Plus débloque 140 analyses par mois, la saisie vocale, les programmes et la progression longue durée.",
        },
        {
          id: FAQ_IDS.everywhere,
          question: "Puis-je payer sur le site et utiliser Plus dans l'app ?",
          answer: "Oui. L'abonnement est rattaché à ton compte Omeo : payé sur le site ou dans un store, il est reconnu partout.",
        },
        {
          id: FAQ_IDS.cancel,
          question: "Comment résilier ?",
          answer:
            "Dans Google Play ou l'App Store si tu as payé dans l'app ; sur la page [Mon abonnement](/subscription) si tu as payé sur le site. Plus reste actif jusqu'à la fin de la période payée.",
        },
        {
          id: FAQ_IDS.trialEnd,
          question: "Que se passe-t-il à la fin de l'essai ?",
          answer: "Tu passes automatiquement en Free, sans être débité. Tu gardes toutes tes données.",
        },
        {
          id: FAQ_IDS.dollars,
          question: "Pourquoi les prix sont en dollars ?",
          answer: "Pour un prix identique partout. Google Play et l'App Store convertissent automatiquement dans ta monnaie.",
        },
      ],
    },
    {
      category: "Santé & activité",
      items: [
        {
          id: FAQ_IDS.healthData,
          question: "Mes données de santé sont-elles partagées ?",
          answer:
            "Non. Omeo lit tes données d'activité sans jamais rien écrire, et seuls des totaux par jour sont envoyés à nos serveurs. Tu peux exporter ou supprimer tes données à tout moment.",
        },
        {
          id: FAQ_IDS.steps,
          question: "Mes pas ne se synchronisent pas",
          answer: "Vérifie l'autorisation « Pas » dans Health Connect (Autorisations › Omeo), puis rouvre l'app.",
        },
      ],
    },
    {
      category: "Compte & données",
      items: [
        {
          id: FAQ_IDS.delete,
          question: "Comment supprimer mon compte ?",
          answer:
            "Depuis l'app (Profil › Paramètres) ou sur la page [Supprimer mon compte](/delete-account). Les données sont effacées sous 30 jours.",
        },
        {
          id: FAQ_IDS.export,
          question: "Puis-je exporter mes données ?",
          answer: "Oui, depuis Paramètres › Confidentialité. Tu reçois un fichier par email.",
        },
      ],
    },
  ],
  legal: LEGAL_FR,
  promoLabel: "Bienvenue −20 %",
};
