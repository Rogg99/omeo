import type { ContentStatus, ContentType } from "@/server/data/content";
import type { I18nText, Locale } from "@/server/data/types";

/**
 * Contenus simulés : les 15 types, dans tous les statuts et avec des traductions incomplètes.
 * Repris de previews/admin (ndolé, yassa, sauce gombo, baobab, 8 000 pas, barème de points…).
 */

/** Texte multilingue : français obligatoire, autres langues facultatives. */
function t(fr: string, others: Partial<Record<Exclude<Locale, "fr">, string>> = {}): I18nText {
  return { fr, ...others };
}

export type ContentSeed = {
  id: string;
  type: ContentType;
  status: ContentStatus;
  /** Membre de l'équipe auteur de la dernière version (contrôle « jamais sa propre publication »). */
  authorId: string;
  updatedAt: string;
  /** Vrai si le contenu a déjà été publié une fois (suppression interdite, archivage seulement). */
  everPublished: boolean;
  thumbnail?: string;
  data: Record<string, unknown>;
};

const FATOU = "5b1f6a0e-2c11-4a5e-9d0e-0a1b2c3d4e03";
const IBRAHIM = "5b1f6a0e-2c11-4a5e-9d0e-0a1b2c3d4e02";
const AISSATOU = "5b1f6a0e-2c11-4a5e-9d0e-0a1b2c3d4e01";

const uuid = (n: number) => `c0a7e000-0000-4000-8000-${String(n).padStart(12, "0")}`;

export const FOOD_IDS = {
  ndole: uuid(101),
  gombo: uuid(102),
  attieke: uuid(103),
  plantain: uuid(104),
  riz: uuid(105),
  merou: uuid(106),
  crevettes: uuid(107),
  arachide: uuid(108),
  huile: uuid(109),
  poulet: uuid(110),
  oignon: uuid(111),
  fonio: uuid(112),
} as const;

const food = (
  n: number,
  name: I18nText,
  aliases: string[],
  values: { kcal: number; protein_g: number; carbs_g: number; fat_g: number; fiber_g: number; salt_g: number },
  source: string,
  status: ContentStatus = "published",
): ContentSeed => ({
  id: uuid(n),
  type: "foods",
  status,
  authorId: IBRAHIM,
  updatedAt: "2026-11-02T10:00:00Z",
  everPublished: status !== "draft",
  data: { name, aliases, category: "base", default_portion_g: 100, source, ...values },
});

export const CONTENT: ContentSeed[] = [
  // Aliments (valeurs pour 100 g)
  food(101, t("Feuilles de ndolé", { en: "Bitterleaf", es: "Hojas de ndolé", pt: "Folhas de ndolé", de: "Bitterblatt" }), ["bitterleaf", "ndolè"], { kcal: 58, protein_g: 5.1, carbs_g: 8.2, fat_g: 0.8, fiber_g: 4.1, salt_g: 0.04 }, "USDA adapté"),
  food(102, t("Gombo frais", { en: "Fresh okra", es: "Quimbombó", pt: "Quiabo", ar: "بامية طازجة", zh: "秋葵", ja: "オクラ", de: "Okra" }), ["okra", "gombo", "lalo", "kandia"], { kcal: 33, protein_g: 1.9, carbs_g: 7.5, fat_g: 0.2, fiber_g: 3.2, salt_g: 0.02 }, "FAO/INFOODS"),
  food(103, t("Attiéké", { en: "Attieke" }), ["garri fermenté"], { kcal: 158, protein_g: 0.9, carbs_g: 37.8, fat_g: 0.2, fiber_g: 1.8, salt_g: 0.01 }, "Table CI 2019"),
  food(104, t("Banane plantain mûre frite", { en: "Fried ripe plantain" }), ["alloco", "dodo"], { kcal: 250, protein_g: 1.5, carbs_g: 38, fat_g: 11.2, fiber_g: 2.3, salt_g: 0.02 }, "FAO/INFOODS"),
  food(105, t("Riz brisé cuit", { en: "Cooked broken rice" }), ["riz cassé"], { kcal: 139, protein_g: 2.6, carbs_g: 30.2, fat_g: 0.3, fiber_g: 0.4, salt_g: 0 }, "USDA"),
  food(106, t("Mérou", { en: "Grouper" }), ["thiof"], { kcal: 92, protein_g: 19.4, carbs_g: 0, fat_g: 1, fiber_g: 0, salt_g: 0.13 }, "USDA"),
  food(107, t("Crevettes", { en: "Shrimp" }), ["gambas"], { kcal: 99, protein_g: 24, carbs_g: 0.2, fat_g: 0.3, fiber_g: 0, salt_g: 0.28 }, "USDA"),
  food(108, t("Pâte d'arachide", { en: "Peanut paste" }), ["beurre de cacahuète"], { kcal: 588, protein_g: 25, carbs_g: 20, fat_g: 50, fiber_g: 6, salt_g: 0.02 }, "USDA"),
  food(109, t("Huile d'arachide", { en: "Peanut oil" }), [], { kcal: 884, protein_g: 0, carbs_g: 0, fat_g: 100, fiber_g: 0, salt_g: 0 }, "USDA"),
  food(110, t("Poulet (blanc)", { en: "Chicken breast" }), [], { kcal: 165, protein_g: 31, carbs_g: 0, fat_g: 3.6, fiber_g: 0, salt_g: 0.17 }, "USDA"),
  food(111, t("Oignon", { en: "Onion" }), [], { kcal: 40, protein_g: 1.1, carbs_g: 9.3, fat_g: 0.1, fiber_g: 1.7, salt_g: 0.01 }, "USDA"),
  food(112, t("Fonio cuit"), ["acha"], { kcal: 120, protein_g: 2.2, carbs_g: 26, fat_g: 0.4, fiber_g: 1.1, salt_g: 0 }, "FAO/INFOODS", "draft"),

  // Plats
  {
    id: uuid(201),
    type: "dishes",
    status: "published",
    authorId: IBRAHIM,
    updatedAt: "2026-10-20T09:00:00Z",
    everPublished: true,
    thumbnail: "/demo/thieb.jpg",
    data: {
      name: t("Thiéboudienne", { en: "Thieboudienne", es: "Thieboudienne", pt: "Thieboudienne", de: "Thieboudienne" }),
      aliases: ["ceebu jën", "riz au poisson"],
      country: "SN",
      standard_portion_g: 450,
      recipe_id: null,
      components: [
        { food_id: FOOD_IDS.riz, grams: 180 },
        { food_id: FOOD_IDS.merou, grams: 150 },
        { food_id: FOOD_IDS.huile, grams: 15 },
      ],
    },
  },
  {
    id: uuid(202),
    type: "dishes",
    status: "published",
    authorId: IBRAHIM,
    updatedAt: "2026-10-18T09:00:00Z",
    everPublished: true,
    thumbnail: "/demo/ndole.jpg",
    data: {
      name: t("Ndolé", { en: "Ndole" }),
      aliases: ["ndolè"],
      country: "CM",
      standard_portion_g: 350,
      recipe_id: uuid(301),
      components: [
        { food_id: FOOD_IDS.ndole, grams: 150 },
        { food_id: FOOD_IDS.arachide, grams: 40 },
        { food_id: FOOD_IDS.crevettes, grams: 80 },
      ],
    },
  },
  {
    id: uuid(203),
    type: "dishes",
    status: "review",
    authorId: FATOU,
    updatedAt: "2026-11-15T16:00:00Z",
    everPublished: false,
    thumbnail: "/demo/gombo.jpg",
    data: {
      name: t("Sauce arachide"),
      aliases: ["mafé", "tigadèguèna"],
      country: "ML",
      standard_portion_g: 400,
      recipe_id: null,
      components: [
        { food_id: FOOD_IDS.arachide, grams: 50 },
        { food_id: FOOD_IDS.poulet, grams: 120 },
        { food_id: FOOD_IDS.riz, grams: 150 },
      ],
    },
  },

  // Recettes
  {
    id: uuid(301),
    type: "recipes",
    status: "published",
    authorId: FATOU,
    updatedAt: "2026-11-14T08:00:00Z",
    everPublished: true,
    thumbnail: "/demo/ndole.jpg",
    data: {
      name: t("Ndolé allégé aux crevettes", {
        en: "Light ndole with shrimp",
        es: "Ndolé ligero con gambas",
        pt: "Ndolé leve com camarão",
        ar: "ندولي خفيف بالروبيان",
        zh: "清淡虾仁苦叶菜",
        ja: "エビの軽いンドレ",
        de: "Leichtes Ndolé mit Garnelen",
      }),
      description: t("La version légère du plat national camerounais, riche en fibres.", {
        en: "A lighter take on Cameroon's national dish, rich in fiber.",
        es: "La versión ligera del plato nacional camerunés, rica en fibra.",
        pt: "A versão leve do prato nacional camaronês, rica em fibras.",
        ar: "النسخة الخفيفة من الطبق الوطني الكاميروني، غنية بالألياف.",
        zh: "喀麦隆国菜的清淡版本，富含纤维。",
        ja: "カメルーンの国民食を軽くアレンジ。食物繊維たっぷり。",
        de: "Die leichte Version des kamerunischen Nationalgerichts, reich an Ballaststoffen.",
      }),
      country: "CM",
      prep_minutes: 25,
      cook_minutes: 45,
      difficulty: "medium",
      servings: 4,
      tags: ["fibres", "protéines"],
      goals: ["lose_weight", "eat_balanced"],
      is_free: true,
      ingredients: [
        { food_id: FOOD_IDS.ndole, grams: 500 },
        { food_id: FOOD_IDS.arachide, grams: 120 },
        { food_id: FOOD_IDS.crevettes, grams: 300 },
        { food_id: FOOD_IDS.oignon, grams: 100 },
      ],
      steps: [
        {
          text: t("Laver et presser les feuilles de ndolé.", {
            en: "Wash and squeeze the bitterleaf.",
            es: "Lavar y escurrir las hojas.",
            pt: "Lavar e espremer as folhas.",
            ar: "اغسل الأوراق واعصرها.",
            zh: "洗净苦叶并挤干。",
            ja: "葉を洗って絞る。",
            de: "Blätter waschen und ausdrücken.",
          }),
        },
        {
          text: t("Faire revenir l'oignon, ajouter la pâte d'arachide et les crevettes.", {
            en: "Sauté the onion, add peanut paste and shrimp.",
            es: "Sofreír la cebolla, añadir la pasta de cacahuete y las gambas.",
            pt: "Refogar a cebola, juntar a pasta de amendoim e o camarão.",
            ar: "قلّب البصل ثم أضف معجون الفول السوداني والروبيان.",
            zh: "炒洋葱，加入花生酱和虾。",
            ja: "玉ねぎを炒め、ピーナッツペーストとエビを加える。",
            de: "Zwiebel anbraten, Erdnusspaste und Garnelen hinzufügen.",
          }),
        },
      ],
    },
  },
  {
    id: uuid(302),
    type: "recipes",
    status: "published",
    authorId: IBRAHIM,
    updatedAt: "2026-11-08T18:03:00Z",
    everPublished: true,
    thumbnail: "/demo/yassa.jpg",
    data: {
      name: t("Poulet yassa", {
        en: "Chicken yassa",
        es: "Pollo yassa",
        pt: "Frango yassa",
        ar: "دجاج ياسا",
        zh: "亚萨鸡",
        ja: "チキン・ヤッサ",
        de: "Hähnchen Yassa",
      }),
      description: t("Poulet mariné au citron et aux oignons, version allégée.", { en: "Lemon and onion marinated chicken, lighter version." }),
      country: "SN",
      prep_minutes: 20,
      cook_minutes: 40,
      difficulty: "easy",
      servings: 4,
      tags: ["protéines"],
      goals: ["gain_muscle"],
      is_free: false,
      ingredients: [
        { food_id: FOOD_IDS.poulet, grams: 600 },
        { food_id: FOOD_IDS.oignon, grams: 400 },
        { food_id: FOOD_IDS.huile, grams: 20 },
        { food_id: FOOD_IDS.riz, grams: 400 },
      ],
      steps: [
        { text: t("Faire mariner le poulet 2 h avec le citron et les oignons.", { en: "Marinate the chicken for 2 hours with lemon and onions." }) },
        { text: t("Griller le poulet puis le mijoter avec les oignons.") },
      ],
    },
  },
  {
    id: uuid(303),
    type: "recipes",
    status: "review",
    authorId: FATOU,
    updatedAt: "2026-11-15T14:20:00Z",
    everPublished: false,
    thumbnail: "/demo/gombo.jpg",
    data: {
      name: t("Sauce gombo légère", { en: "Light okra sauce" }),
      description: t("Une sauce gombo riche en fibres, avec peu d'huile."),
      country: "CI",
      prep_minutes: 15,
      cook_minutes: 30,
      difficulty: "easy",
      servings: 4,
      tags: ["fibres"],
      goals: ["prevent_diabetes"],
      is_free: false,
      ingredients: [
        { food_id: FOOD_IDS.gombo, grams: 400 },
        { food_id: FOOD_IDS.merou, grams: 300 },
        { food_id: FOOD_IDS.huile, grams: 10 },
      ],
      steps: [{ text: t("Couper le gombo en rondelles.") }, { text: t("Cuire le poisson puis ajouter le gombo.") }],
    },
  },
  {
    id: uuid(304),
    type: "recipes",
    status: "draft",
    authorId: FATOU,
    updatedAt: "2026-11-16T07:30:00Z",
    everPublished: false,
    thumbnail: "/demo/fonio.jpg",
    data: {
      name: t("Salade de fonio"),
      description: t("Fonio, légumes croquants et vinaigrette au citron."),
      country: "ML",
      prep_minutes: 20,
      cook_minutes: 10,
      difficulty: "easy",
      servings: 2,
      tags: [],
      goals: ["eat_balanced"],
      is_free: true,
      ingredients: [
        { food_id: FOOD_IDS.fonio, grams: 200 },
        { food_id: FOOD_IDS.oignon, grams: 50 },
      ],
      steps: [{ text: t("Cuire le fonio à la vapeur.") }],
    },
  },
  {
    id: uuid(305),
    type: "recipes",
    status: "archived",
    authorId: IBRAHIM,
    updatedAt: "2026-09-01T09:00:00Z",
    everPublished: true,
    thumbnail: "/demo/alloco.jpg",
    data: {
      name: t("Alloco au four", {
        en: "Oven-baked plantain",
        es: "Plátano al horno",
        pt: "Banana-da-terra no forno",
        ar: "موز الجنة في الفرن",
        zh: "烤大蕉",
        ja: "焼きプランテン",
        de: "Ofen-Kochbanane",
      }),
      description: t("Des bananes plantain dorées au four, sans friture.", {
        en: "Golden oven plantains, no frying.",
        es: "Plátanos dorados al horno, sin freír.",
        pt: "Banana-da-terra dourada no forno, sem fritura.",
        ar: "موز جنة ذهبي في الفرن، بلا قلي.",
        zh: "烤箱金黄大蕉，无需油炸。",
        ja: "揚げずにオーブンで焼いたプランテン。",
        de: "Goldene Kochbananen aus dem Ofen, ohne Frittieren.",
      }),
      country: "CI",
      prep_minutes: 10,
      cook_minutes: 25,
      difficulty: "easy",
      servings: 2,
      tags: [],
      goals: ["eat_balanced"],
      is_free: true,
      ingredients: [{ food_id: FOOD_IDS.plantain, grams: 400 }],
      steps: [
        {
          text: t("Couper les bananes et les enfourner 25 min à 200 °C.", {
            en: "Slice the plantains and bake 25 min at 200 °C.",
            es: "Cortar y hornear 25 min a 200 °C.",
            pt: "Cortar e assar 25 min a 200 °C.",
            ar: "قطّع الموز واخبزه 25 دقيقة على 200 درجة.",
            zh: "切片，200 °C 烤 25 分钟。",
            ja: "切って200 °Cで25分焼く。",
            de: "In Scheiben schneiden und 25 Min. bei 200 °C backen.",
          }),
        },
      ],
    },
  },

  // Plantes
  {
    id: uuid(401),
    type: "plants",
    status: "published",
    authorId: FATOU,
    updatedAt: "2026-10-30T10:00:00Z",
    everPublished: true,
    data: {
      common_name: t("Baobab", { en: "Baobab", ar: "باوباب" }),
      scientific_name: "Adansonia digitata",
      tags: ["fibres", "vitamine C"],
      traditional_use: t("La poudre du fruit (pain de singe) est consommée en boisson."),
      nutritional_benefits: t("Riche en fibres et en vitamine C."),
      precautions: t("Riche en fibres : à introduire progressivement.", { ar: "غني بالألياف: يُدخل تدريجيًا." }),
      contraindications: [],
      related_recipe_ids: [],
    },
  },
  {
    id: uuid(402),
    type: "plants",
    status: "draft",
    authorId: FATOU,
    updatedAt: "2026-11-12T10:00:00Z",
    everPublished: false,
    data: {
      common_name: t("Moringa"),
      scientific_name: "Moringa oleifera",
      tags: ["fer"],
      traditional_use: t("Feuilles séchées en poudre, ajoutées aux sauces."),
      nutritional_benefits: t("Source de fer et de protéines végétales."),
      precautions: t("Déconseillé pendant la grossesse sans avis médical."),
      contraindications: ["grossesse"],
      related_recipe_ids: [],
    },
  },

  // Exercices et séances
  {
    id: uuid(501),
    type: "exercises",
    status: "published",
    authorId: IBRAHIM,
    updatedAt: "2026-10-10T10:00:00Z",
    everPublished: true,
    data: {
      name: t("Squat", { en: "Squat", es: "Sentadilla", pt: "Agachamento", ar: "القرفصاء", zh: "深蹲", ja: "スクワット", de: "Kniebeuge" }),
      instructions: t("Pieds écartés à la largeur des épaules, descends comme pour t'asseoir.", {
        en: "Feet shoulder-width apart, lower as if sitting down.",
      }),
      muscles: ["quadriceps", "fessiers"],
      level: "beginner",
      equipment: [],
      met: 5,
      is_free: true,
      subtitle_upload_ids: {},
    },
  },
  {
    id: uuid(502),
    type: "exercises",
    status: "published",
    authorId: IBRAHIM,
    updatedAt: "2026-10-10T10:00:00Z",
    everPublished: true,
    data: {
      name: t("Pompes", { en: "Push-ups" }),
      instructions: t("Mains sous les épaules, corps gainé, descends la poitrine vers le sol."),
      muscles: ["pectoraux", "triceps"],
      level: "intermediate",
      equipment: [],
      met: 8,
      is_free: false,
      subtitle_upload_ids: {},
    },
  },
  {
    id: uuid(601),
    type: "workouts",
    status: "published",
    authorId: IBRAHIM,
    updatedAt: "2026-10-12T10:00:00Z",
    everPublished: true,
    data: {
      name: t("Cardio express 20 min", { en: "20-min express cardio" }),
      description: t("Une séance courte, sans matériel."),
      goal: "cardio",
      level: "beginner",
      is_free: true,
      steps: [
        { exercise_id: uuid(501), mode: "time", duration_s: 40, rest_s: 20 },
        { exercise_id: uuid(502), mode: "reps", reps: 10, rest_s: 30 },
      ],
    },
  },

  // Programmes et challenges
  {
    id: uuid(701),
    type: "programs",
    status: "published",
    authorId: FATOU,
    updatedAt: "2026-10-25T10:00:00Z",
    everPublished: true,
    data: {
      name: t("Perdre 4 kg en 8 semaines", { en: "Lose 4 kg in 8 weeks" }),
      description: t("Un programme progressif : alimentation, marche et renforcement."),
      goal: "lose_weight",
      weeks: 8,
      points: 300,
      badge_id: null,
      days: [
        {
          day_index: 1,
          tip: t("Commence par noter tous tes repas aujourd'hui."),
          workout_id: null,
          recipe_ids: [uuid(301)],
          tasks: [{ label: t("Enregistrer 3 repas"), rule: { metric: "meals_count", operator: "gte", threshold: 3, period: "day" } }],
        },
        {
          day_index: 2,
          tip: t("Bois un grand verre d'eau à chaque repas."),
          workout_id: uuid(601),
          recipe_ids: [],
          tasks: [{ label: t("Boire 2 L d'eau"), rule: { metric: "water_ml", operator: "gte", threshold: 2000, period: "day" } }],
        },
      ],
    },
  },
  {
    id: uuid(801),
    type: "challenges",
    status: "draft",
    authorId: FATOU,
    updatedAt: "2026-11-16T08:10:00Z",
    everPublished: false,
    data: {
      name: t("8 000 pas"),
      description: t("Fais au moins 8 000 pas par jour pendant 14 jours. Ton téléphone compte pour toi."),
      duration_days: 14,
      rule: { metric: "steps", operator: "gte", threshold: 8000, period: "day" },
      success_threshold: 0.8,
      points_per_day: 10,
      points_completion: 100,
      badge_id: uuid(901),
    },
  },
  {
    id: uuid(802),
    type: "challenges",
    status: "published",
    authorId: IBRAHIM,
    updatedAt: "2026-10-01T10:00:00Z",
    everPublished: true,
    data: {
      name: t("2 L d'eau par jour", { en: "2 L of water a day", es: "2 L de agua al día" }),
      description: t("Atteins ton objectif d'hydratation 7 jours de suite."),
      duration_days: 7,
      rule: { metric: "water_ml", operator: "gte", threshold: 2000, period: "day" },
      success_threshold: 0.8,
      points_per_day: 10,
      points_completion: 100,
      badge_id: null,
    },
  },

  // Gamification
  {
    id: uuid(901),
    type: "badges",
    status: "published",
    authorId: IBRAHIM,
    updatedAt: "2026-09-15T10:00:00Z",
    everPublished: true,
    data: {
      code: "steady_walker",
      family: "activity",
      name: t("Marcheur assidu", { en: "Steady walker" }),
      description: t("Réussir le challenge 8 000 pas."),
      condition: { challenge: "8000_steps" },
      bonus_points: 50,
    },
  },
  ...[
    ["Commis", "Commis chef", 0],
    ["Apprenti", "Apprentice", 100],
    ["Marmiton", "Kitchen hand", 250],
    ["Cuisinier", "Cook", 450],
    ["Chef de partie", "Chef de partie", 1000],
    ["Sous-chef", "Sous-chef", 1600],
  ].map(
    ([fr, en, min], i): ContentSeed => ({
      id: uuid(1001 + i),
      type: "levels",
      status: "published",
      authorId: AISSATOU,
      updatedAt: "2026-09-01T10:00:00Z",
      everPublished: true,
      data: { rank: i + 1, name: t(String(fr), { en: String(en) }), min_points: Number(min) },
    }),
  ),
  ...[
    ["meal_logged", 10, 4, "day"],
    ["full_day", 20, 1, "day"],
    ["water_goal", 10, 1, "day"],
    ["kcal_on_target", 20, 1, "day"],
    ["steps_goal", 15, 1, "day"],
    ["workout_completed", 30, 2, "day"],
    ["weight_logged", 5, 1, "week"],
    ["challenge_day", 10, null, "none"],
    ["challenge_completed", 100, null, "none"],
    ["program_completed", 300, null, "none"],
    ["analysis_feedback", 5, 3, "day"],
    ["referral_signup", 50, null, "none"],
  ].map(
    ([action, points, cap, period], i): ContentSeed => ({
      id: uuid(1101 + i),
      type: "point-rules",
      status: "published",
      authorId: AISSATOU,
      updatedAt: "2026-09-01T10:00:00Z",
      everPublished: true,
      data: { action, points, cap, cap_period: period },
    }),
  ),

  // Prévention, FAQ, légal, villes
  {
    id: uuid(1201),
    type: "prevention-tips",
    status: "published",
    authorId: FATOU,
    updatedAt: "2026-10-05T10:00:00Z",
    everPublished: true,
    data: {
      code: "salt_cubes",
      topic: "salt",
      title: t("Le sel caché dans les cubes", { ar: "الملح المخفي في المكعبات", en: "The salt hidden in stock cubes" }),
      body: t("Un cube de bouillon contient près de 4 g de sel. Remplace-le par des herbes et des épices."),
      trigger: { metric: "salt_g", operator: "gte", threshold: 6, days: 3 },
      tier: "free",
      related_recipe_ids: [uuid(303)],
      related_plant_ids: [],
    },
  },
  {
    id: uuid(1202),
    type: "prevention-tips",
    status: "review",
    authorId: FATOU,
    updatedAt: "2026-11-15T10:00:00Z",
    everPublished: false,
    data: {
      code: "fiber_low",
      topic: "fiber",
      title: t("Plus de fibres, moins de pics de sucre"),
      body: t("Ajoute du gombo, du fonio ou des légumes feuilles à tes repas."),
      trigger: { metric: "fiber_g", operator: "lte", threshold: 15, days: 5 },
      tier: "plus",
      related_recipe_ids: [],
      related_plant_ids: [uuid(401)],
    },
  },
  {
    id: uuid(1301),
    type: "faq",
    status: "published",
    authorId: AISSATOU,
    updatedAt: "2026-10-01T10:00:00Z",
    everPublished: true,
    data: {
      category: "compte",
      question: t("Comment changer de langue ?", { en: "How do I change the language?" }),
      answer: t("Dans Profil › Réglages › Langue.", { en: "In Profile › Settings › Language." }),
      order: 1,
      audience: "both",
    },
  },
  {
    id: uuid(1401),
    type: "legal",
    status: "published",
    authorId: AISSATOU,
    updatedAt: "2026-09-20T10:00:00Z",
    everPublished: true,
    data: {
      kind: "terms",
      body: t("# Conditions générales d'utilisation\n\nVersion 3.", { en: "# Terms of use\n\nVersion 3." }),
      requires_reaccept: false,
    },
  },
  ...[
    ["Yaoundé", "CM", "Africa/Douala"],
    ["Dakar", "SN", "Africa/Dakar"],
    ["Abidjan", "CI", "Africa/Abidjan"],
  ].map(
    ([name, country, timezone], i): ContentSeed => ({
      id: uuid(1501 + i),
      type: "cities",
      status: "published",
      authorId: AISSATOU,
      updatedAt: "2026-08-01T10:00:00Z",
      everPublished: true,
      data: { name: t(String(name), { en: String(name) }), country, timezone, is_suggested: true },
    }),
  ),
];
