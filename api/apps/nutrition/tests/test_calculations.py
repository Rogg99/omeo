"""Calculs nutritionnels purs (docs/produit/03-regles-metier.md), avec les constantes de settings.yaml."""

from __future__ import annotations

from datetime import date
from pathlib import Path

import pytest
import yaml

from apps.nutrition import calculations as calc

SEED = Path(__file__).resolve().parents[3] / "seeds" / "reference" / "settings.yaml"
C = calc.NutritionConstants.from_mapping(yaml.safe_load(SEED.read_text(encoding="utf-8"))["nutrition"])
TODAY = date(2026, 11, 13)


def body(**overrides: object) -> calc.BodyInput:
    data: dict[str, object] = {
        "sex": "female",
        "birth_date": date(1996, 3, 14),
        "height_cm": 175.0,
        "weight_kg": 78.4,
        "target_weight_kg": 74.0,
        "goals": ["lose_weight", "eat_balanced"],
    }
    data.update(overrides)
    return calc.BodyInput(**data)  # type: ignore[arg-type]


class TestAge:
    def test_birthday_not_yet_reached(self) -> None:
        assert calc.age_on(date(1996, 12, 1), TODAY) == 29

    def test_birthday_today(self) -> None:
        assert calc.age_on(date(1996, 11, 13), TODAY) == 30

    def test_leap_day(self) -> None:
        assert calc.age_on(date(2000, 2, 29), date(2026, 2, 28)) == 25


class TestMifflinStJeor:
    def test_female(self) -> None:
        # 10 × 78,4 + 6,25 × 175 − 5 × 30 − 161
        assert calc.bmr_mifflin_st_jeor(sex="female", weight_kg=78.4, height_cm=175, age=30) == pytest.approx(1566.75)

    def test_male(self) -> None:
        assert calc.bmr_mifflin_st_jeor(sex="male", weight_kg=80, height_cm=180, age=30) == pytest.approx(1780.0)


class TestGoals:
    def test_priority_lose_weight_first(self) -> None:
        assert calc.primary_goal(["eat_balanced", "lose_weight"]) == "lose_weight"

    def test_default_balanced(self) -> None:
        assert calc.primary_goal([]) == "eat_balanced"

    def test_lose_weight_deficit(self) -> None:
        assert calc.base_kcal(tdee=2000, goal="lose_weight", sex="female", c=C) == pytest.approx(1650)

    def test_lose_weight_floor_female(self) -> None:
        assert calc.base_kcal(tdee=1300, goal="lose_weight", sex="female", c=C) == 1200

    def test_lose_weight_floor_male(self) -> None:
        assert calc.base_kcal(tdee=1700, goal="lose_weight", sex="male", c=C) == 1500

    def test_gain_muscle_surplus(self) -> None:
        assert calc.base_kcal(tdee=2000, goal="gain_muscle", sex="male", c=C) == pytest.approx(2250)

    @pytest.mark.parametrize("goal", ["eat_balanced", "prevent_diabetes", "prevent_hypertension"])
    def test_no_adjustment(self, goal: str) -> None:
        assert calc.base_kcal(tdee=2000, goal=goal, sex="male", c=C) == 2000


class TestMacros:
    def test_lose_weight_carbs_are_the_rest(self) -> None:
        protein, carbs, fat = calc.macros(kcal=1600, weight_kg=78.4, goal="lose_weight", c=C)
        assert protein == 141  # 1,8 × 78,4
        assert fat == 49  # 27,5 % de 1 600 / 9
        assert carbs == round((1600 - 141.12 * 4 - 1600 * 0.275) / 4)

    def test_balanced_carbs_fixed_share(self) -> None:
        _, carbs, fat = calc.macros(kcal=2000, weight_kg=70, goal="eat_balanced", c=C)
        assert carbs == 250
        assert fat == 67

    def test_carbs_never_negative(self) -> None:
        _, carbs, _ = calc.macros(kcal=900, weight_kg=150, goal="gain_muscle", c=C)
        assert carbs == 0


class TestWater:
    def test_base(self) -> None:
        assert calc.water_ml(weight_kg=78.4, c=C) == 2550  # 2 548 arrondi à 50 ml

    def test_with_activity(self) -> None:
        assert calc.adjusted_water_ml(base_water_ml=2550, active_minutes=60, c=C) == 3050


class TestActivityAdjustment:
    def test_half_of_excess(self) -> None:
        assert calc.activity_adjusted_kcal(base_kcal=1600, tdee_kcal=1900, burned_kcal=2300, enabled=True, c=C) == 1800

    def test_no_excess(self) -> None:
        assert calc.activity_adjusted_kcal(base_kcal=1600, tdee_kcal=1900, burned_kcal=1800, enabled=True, c=C) == 1600

    def test_disabled(self) -> None:
        assert calc.activity_adjusted_kcal(base_kcal=1600, tdee_kcal=1900, burned_kcal=3000, enabled=False, c=C) == 1600

    def test_no_data(self) -> None:
        assert calc.activity_adjusted_kcal(base_kcal=1600, tdee_kcal=1900, burned_kcal=None, enabled=True, c=C) == 1600


class TestTargets:
    def test_awa(self) -> None:
        result = calc.compute_targets(body(), today=TODAY, c=C)
        assert result.bmr_kcal == 1567
        assert result.tdee_kcal == 1880
        assert result.base_kcal == 1551  # 1 880,1 × 0,825
        assert result.fiber_g == 25
        assert result.salt_max_g == 5.0
        assert result.water_ml == 2550
        assert result.warning is None

    def test_warning_loss_with_higher_target(self) -> None:
        assert calc.compute_targets(body(target_weight_kg=88), today=TODAY, c=C).warning == (
            "target_above_current_for_loss"
        )

    def test_warning_gain_with_lower_target(self) -> None:
        result = calc.compute_targets(body(goals=["gain_muscle"], target_weight_kg=70), today=TODAY, c=C)
        assert result.warning == "target_below_current_for_gain"


class TestGauge:
    def test_under(self) -> None:
        g = calc.gauge(value=900, target=1800)
        assert g == {"value": 900, "target": 1800, "remaining": 900, "percent": 50, "status": "under"}

    def test_on_target(self) -> None:
        assert calc.gauge(value=1750, target=1800)["status"] == "on_target"

    def test_over_remaining_clamped(self) -> None:
        g = calc.gauge(value=2100, target=1800)
        assert g["status"] == "over"
        assert g["remaining"] == 0

    def test_upper_bound(self) -> None:
        assert calc.gauge(value=4.2, target=5.0, upper_bound=True)["status"] == "on_target"
        assert calc.gauge(value=5.3, target=5.0, upper_bound=True)["remaining"] == 0.0

    def test_zero_target(self) -> None:
        assert calc.gauge(value=10, target=0)["percent"] == 0

    def test_kcal_within_target(self) -> None:
        assert calc.kcal_within_target(consumed=1700, target=1800, c=C)
        assert not calc.kcal_within_target(consumed=1500, target=1800, c=C)
        assert not calc.kcal_within_target(consumed=0, target=0, c=C)
