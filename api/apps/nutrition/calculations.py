"""
Calculs nutritionnels purs (aucun accès à l'ORM) — docs/produit/03-regles-metier.md.

Toutes les constantes viennent de `NutritionConstants`, construit depuis les réglages (`Setting`, clé `nutrition`).
"""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from datetime import date
from decimal import ROUND_HALF_UP, Decimal
from typing import Any, Final, Literal

Sex = Literal["male", "female"]
GOAL_PRIORITY: Final[tuple[str, ...]] = (
    "lose_weight",
    "gain_muscle",
    "prevent_diabetes",
    "prevent_hypertension",
    "eat_balanced",
)
BALANCED_CARBS_GOALS: Final = frozenset({"eat_balanced", "prevent_diabetes", "prevent_hypertension"})
KCAL_PER_G_PROTEIN: Final = 4
KCAL_PER_G_CARBS: Final = 4
KCAL_PER_G_FAT: Final = 9
WATER_ROUNDING_ML: Final = 50


@dataclass(frozen=True, slots=True)
class NutritionConstants:
    activity_factor: float
    lose_weight_deficit: float
    gain_muscle_surplus: float
    min_kcal: Mapping[str, int]
    protein_g_per_kg: Mapping[str, float]
    fat_ratio: Mapping[str, float]
    carbs_ratio_balanced: float
    water_ml_per_kg: float
    water_ml_per_active_hour: int
    fiber_g: Mapping[str, int]
    salt_max_g: float
    activity_bonus_ratio: float
    kcal_target_tolerance: float

    @classmethod
    def from_mapping(cls, values: Mapping[str, Any]) -> NutritionConstants:
        return cls(
            activity_factor=float(values["activity_factor"]),
            lose_weight_deficit=float(values["lose_weight_deficit"]),
            gain_muscle_surplus=float(values["gain_muscle_surplus"]),
            min_kcal={k: int(v) for k, v in values["min_kcal"].items()},
            protein_g_per_kg={k: float(v) for k, v in values["protein_g_per_kg"].items()},
            fat_ratio={k: float(v) for k, v in values["fat_ratio"].items()},
            carbs_ratio_balanced=float(values["carbs_ratio_balanced"]),
            water_ml_per_kg=float(values["water_ml_per_kg"]),
            water_ml_per_active_hour=int(values["water_ml_per_active_hour"]),
            fiber_g={k: int(v) for k, v in values["fiber_g"].items()},
            salt_max_g=float(values["salt_max_g"]),
            activity_bonus_ratio=float(values["activity_bonus_ratio"]),
            kcal_target_tolerance=float(values["kcal_target_tolerance"]),
        )


@dataclass(frozen=True, slots=True)
class BodyInput:
    sex: Sex
    birth_date: date
    height_cm: float
    weight_kg: float
    target_weight_kg: float
    goals: Sequence[str]


@dataclass(frozen=True, slots=True)
class TargetsResult:
    bmr_kcal: int
    tdee_kcal: int
    base_kcal: int
    protein_g: int
    carbs_g: int
    fat_g: int
    fiber_g: int
    salt_max_g: float
    water_ml: int
    primary_goal: str
    warning: str | None  # code stable, traduit par l'appelant


def round_int(value: float) -> int:
    return int(Decimal(str(value)).quantize(Decimal(1), rounding=ROUND_HALF_UP))


def round_1(value: float) -> float:
    return float(Decimal(str(value)).quantize(Decimal("0.1"), rounding=ROUND_HALF_UP))


def age_on(birth_date: date, today: date) -> int:
    years = today.year - birth_date.year
    if (today.month, today.day) < (birth_date.month, birth_date.day):
        years -= 1
    return years


def bmr_mifflin_st_jeor(*, sex: Sex, weight_kg: float, height_cm: float, age: int) -> float:
    base = 10 * weight_kg + 6.25 * height_cm - 5 * age
    return base + 5 if sex == "male" else base - 161


def primary_goal(goals: Sequence[str]) -> str:
    for goal in GOAL_PRIORITY:
        if goal in goals:
            return goal
    return "eat_balanced"


def base_kcal(*, tdee: float, goal: str, sex: Sex, c: NutritionConstants) -> float:
    if goal == "lose_weight":
        return max(tdee * (1 - c.lose_weight_deficit), float(c.min_kcal[sex]))
    if goal == "gain_muscle":
        return tdee * (1 + c.gain_muscle_surplus)
    return tdee


def macros(*, kcal: float, weight_kg: float, goal: str, c: NutritionConstants) -> tuple[int, int, int]:
    """Protéines (g/kg), lipides (part des calories), glucides (part fixe ou reste). Renvoie (P, G, L) en grammes."""
    protein = c.protein_g_per_kg[goal] * weight_kg
    fat = kcal * c.fat_ratio[goal] / KCAL_PER_G_FAT
    if goal in BALANCED_CARBS_GOALS:
        carbs = kcal * c.carbs_ratio_balanced / KCAL_PER_G_CARBS
    else:
        carbs = (kcal - protein * KCAL_PER_G_PROTEIN - fat * KCAL_PER_G_FAT) / KCAL_PER_G_CARBS
    return round_int(protein), round_int(max(carbs, 0.0)), round_int(fat)


def water_ml(*, weight_kg: float, active_minutes: int = 0, c: NutritionConstants) -> int:
    raw = weight_kg * c.water_ml_per_kg + (active_minutes / 60) * c.water_ml_per_active_hour
    return int(round_int(raw / WATER_ROUNDING_ML) * WATER_ROUNDING_ML)


def goal_warning(*, goal: str, weight_kg: float, target_weight_kg: float) -> str | None:
    """Poids cible contradictoire avec l'objectif choisi."""
    if goal == "lose_weight" and target_weight_kg >= weight_kg:
        return "target_above_current_for_loss"
    if goal == "gain_muscle" and target_weight_kg < weight_kg:
        return "target_below_current_for_gain"
    return None


def compute_targets(body: BodyInput, *, today: date, c: NutritionConstants) -> TargetsResult:
    age = age_on(body.birth_date, today)
    bmr = bmr_mifflin_st_jeor(sex=body.sex, weight_kg=body.weight_kg, height_cm=body.height_cm, age=age)
    tdee = bmr * c.activity_factor
    goal = primary_goal(body.goals)
    kcal = base_kcal(tdee=tdee, goal=goal, sex=body.sex, c=c)
    protein, carbs, fat = macros(kcal=kcal, weight_kg=body.weight_kg, goal=goal, c=c)
    return TargetsResult(
        bmr_kcal=round_int(bmr),
        tdee_kcal=round_int(tdee),
        base_kcal=round_int(kcal),
        protein_g=protein,
        carbs_g=carbs,
        fat_g=fat,
        fiber_g=int(c.fiber_g[body.sex]),
        salt_max_g=round_1(c.salt_max_g),
        water_ml=water_ml(weight_kg=body.weight_kg, c=c),
        primary_goal=goal,
        warning=goal_warning(goal=goal, weight_kg=body.weight_kg, target_weight_kg=body.target_weight_kg),
    )


def activity_adjusted_kcal(
    *, base_kcal: int, tdee_kcal: int, burned_kcal: int | None, enabled: bool, c: NutritionConstants
) -> int:
    """Quand la dépense importée du jour dépasse la dépense de base, la moitié de l'excédent s'ajoute à l'objectif."""
    if not enabled or burned_kcal is None or burned_kcal <= tdee_kcal:
        return base_kcal
    return round_int(base_kcal + c.activity_bonus_ratio * (burned_kcal - tdee_kcal))


def adjusted_water_ml(*, base_water_ml: int, active_minutes: int, c: NutritionConstants) -> int:
    extra = (active_minutes / 60) * c.water_ml_per_active_hour
    return int(round_int((base_water_ml + extra) / WATER_ROUNDING_ML) * WATER_ROUNDING_ML)


def kcal_within_target(*, consumed: float, target: float, c: NutritionConstants) -> bool:
    if target <= 0:
        return False
    return abs(consumed - target) <= target * c.kcal_target_tolerance


def gauge(*, value: float, target: float, c: NutritionConstants | None = None, upper_bound: bool = False) -> dict[str, Any]:
    """Jauge prête à afficher : restant borné à 0, pourcentage entier, statut.

    `upper_bound` : la cible est un maximum (sel) — dépasser est `over`, rester dessous est `on_target`.
    """
    percent = round_int(value / target * 100) if target > 0 else 0
    tolerance = c.kcal_target_tolerance if c else 0.10
    if upper_bound:
        status = "over" if value > target else "on_target"
    elif target > 0 and value > target * (1 + tolerance):
        status = "over"
    elif target > 0 and value >= target * (1 - tolerance):
        status = "on_target"
    else:
        status = "under"
    remaining = max(target - value, 0)
    integral = isinstance(value, int) and isinstance(target, int)
    return {
        "value": value,
        "target": target,
        "remaining": remaining if integral else round_1(float(remaining)),
        "percent": percent,
        "status": status,
    }


# ───────────────────────── Nutriments ─────────────────────────

NUTRIENT_KEYS: Final[tuple[str, ...]] = (
    "kcal",
    "protein_g",
    "carbs_g",
    "sugars_g",
    "fat_g",
    "saturated_fat_g",
    "fiber_g",
    "salt_g",
)


def scale_nutrients(per_100g: Mapping[str, float | Decimal], grams: float | Decimal) -> dict[str, float]:
    """Nutriments d'une portion à partir des valeurs pour 100 g (non arrondis)."""
    factor = float(grams) / 100
    return {key: float(per_100g.get(key, 0) or 0) * factor for key in NUTRIENT_KEYS}


def sum_nutrients(parts: Sequence[Mapping[str, float]]) -> dict[str, float]:
    total = dict.fromkeys(NUTRIENT_KEYS, 0.0)
    for part in parts:
        for key in NUTRIENT_KEYS:
            total[key] += float(part.get(key, 0) or 0)
    return total


def per_100g(total: Mapping[str, float], grams: float) -> dict[str, float]:
    if grams <= 0:
        return dict.fromkeys(NUTRIENT_KEYS, 0.0)
    return {key: float(total.get(key, 0)) * 100 / grams for key in NUTRIENT_KEYS}


def display_nutrients(values: Mapping[str, float]) -> dict[str, int | float]:
    """Arrondi d'affichage : kcal entiers, grammes à 0,1 près."""
    return {key: round_int(values.get(key, 0)) if key == "kcal" else round_1(values.get(key, 0)) for key in NUTRIENT_KEYS}


# ───────────────────────── Journée ─────────────────────────

MEALS_FOR_COMPLETE_DAY: Final = 3
BALANCE_TOLERANCE_KCAL: Final = 100


def day_status(*, meals_count: int, consumed_kcal: int, target_kcal: int, c: NutritionConstants) -> str:
    """État d'un jour pour le calendrier et la semaine : empty, partial, on_target, over, under."""
    if meals_count == 0:
        return "empty"
    if meals_count < MEALS_FOR_COMPLETE_DAY:
        return "partial"
    if kcal_within_target(consumed=consumed_kcal, target=target_kcal, c=c):
        return "on_target"
    return "over" if consumed_kcal > target_kcal else "under"


def balance(*, consumed_kcal: int, burned_kcal: int | None) -> dict[str, Any] | None:
    """Balance énergétique du jour ; None sans donnée de dépense importée."""
    if burned_kcal is None:
        return None
    difference = consumed_kcal - burned_kcal
    if abs(difference) <= BALANCE_TOLERANCE_KCAL:
        status = "balanced"
    else:
        status = "surplus" if difference > 0 else "deficit"
    return {
        "consumed_kcal": consumed_kcal,
        "burned_kcal": burned_kcal,
        "difference_kcal": difference,
        "status": status,
    }


def delta_percent(today: float, yesterday: float) -> int | None:
    if yesterday == 0:
        return None
    return round_int((today - yesterday) / yesterday * 100)
