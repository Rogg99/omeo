import { LEGAL_FR } from "./legal-fr";
import type { LocalizedContent } from "./types";
import { FAQ_IDS } from "./ids";

export const en: LocalizedContent = {
  planNames: { free: "Free", plus_annual: "Omeo Plus annual", plus_monthly: "Omeo Plus monthly" },
  comparison: [
    { feature: "photo_analysis", label: "Photo analyses", trial: "28", free: "3 / day", plus: "140 / month" },
    { feature: "text_analysis", label: "Voice or text entry", trial: "10", free: "—", plus: "140 / month" },
    { feature: "dish_catalog", label: "Catalog dishes", trial: "Unlimited", free: "Unlimited", plus: "Unlimited" },
    { feature: "health_sync", label: "Health Connect / Apple Health sync", trial: "✓", free: "✓", plus: "✓" },
    { feature: "progress_long_range", label: "Progress", trial: "30 d · 90 d · 1 yr", free: "7 days", plus: "30 d · 90 d · 1 yr" },
    { feature: "workouts", label: "Video workouts", trial: "All", free: "Selection", plus: "All + offline" },
    { feature: "programs", label: "Programs", trial: "✓", free: "—", plus: "✓" },
    { feature: "challenges_active", label: "Challenges at once", trial: "1", free: "1", plus: "Unlimited" },
    { feature: "recipes", label: "Recipes", trial: "All", free: "Selection", plus: "All" },
    { feature: "insights", label: "Prevention", trial: "Detailed + weekly review", free: "Basic tips", plus: "Detailed + weekly review" },
    { feature: "streak_freeze", label: "Streak day covered", trial: "—", free: "—", plus: "1 / week" },
  ],
  faq: [
    {
      category: "Photo analysis",
      items: [
        {
          id: FAQ_IDS.dishes,
          question: "Which dishes does Omeo recognize?",
          answer:
            "Hundreds of West and Central African dishes (ndolé, thieboudienne, attiéké, garba, yassa, okra sauce…) and more and more dishes from around the world. The database grows every week thanks to your feedback.",
        },
        {
          id: FAQ_IDS.wrong,
          question: "The analysis got it wrong, what should I do?",
          answer: "Correct the ingredients and quantities before saving, then give your feedback. The team uses it to improve recognition.",
        },
        {
          id: FAQ_IDS.blurry,
          question: "Does a blurry photo count against my quota?",
          answer: "No. A failed analysis is **never** counted.",
        },
      ],
    },
    {
      category: "Subscription",
      items: [
        {
          id: FAQ_IDS.free,
          question: "Is it free?",
          answer:
            "Yes. Free includes 3 photo analyses a day and all the tracking. Plus unlocks 140 analyses a month, voice entry, programs and long-term progress.",
        },
        {
          id: FAQ_IDS.everywhere,
          question: "Can I pay on the website and use Plus in the app?",
          answer: "Yes. The subscription is linked to your Omeo account: paid on the website or in a store, it's recognized everywhere.",
        },
        {
          id: FAQ_IDS.cancel,
          question: "How do I cancel?",
          answer:
            "In Google Play or the App Store if you paid in the app; on the [My subscription](/subscription) page if you paid on the website. Plus stays active until the end of the paid period.",
        },
        {
          id: FAQ_IDS.trialEnd,
          question: "What happens at the end of the trial?",
          answer: "You automatically switch to Free, without being charged. You keep all your data.",
        },
        {
          id: FAQ_IDS.dollars,
          question: "Why are prices in dollars?",
          answer: "For the same price everywhere. Google Play and the App Store automatically convert to your currency.",
        },
      ],
    },
    {
      category: "Health & activity",
      items: [
        {
          id: FAQ_IDS.healthData,
          question: "Is my health data shared?",
          answer:
            "No. Omeo reads your activity data without ever writing anything, and only daily totals are sent to our servers. You can export or delete your data at any time.",
        },
        {
          id: FAQ_IDS.steps,
          question: "My steps aren't syncing",
          answer: "Check the “Steps” permission in Health Connect (Permissions › Omeo), then reopen the app.",
        },
      ],
    },
    {
      category: "Account & data",
      items: [
        {
          id: FAQ_IDS.delete,
          question: "How do I delete my account?",
          answer: "From the app (Profile › Settings) or on the [Delete my account](/delete-account) page. Data is erased within 30 days.",
        },
        {
          id: FAQ_IDS.export,
          question: "Can I export my data?",
          answer: "Yes, from Settings › Privacy. You'll receive a file by email.",
        },
      ],
    },
  ],
  legal: LEGAL_FR,
  promoLabel: "Welcome −20%",
};
