"""
Base de connaissances du scan, alimentée par les avis des utilisateurs.

- DishKnowledge : fiche visuelle d'un plat, par pays ou par région. Injectée
  dans le prompt pour les utilisateurs de ce pays ou de cette région.
- ScanReview : une correction proposée (« l'IA a dit X, c'était Y »), avec
  son statut de validation.
- ConfusionRule : une correction devenue règle, par consensus ou par un
  validateur de confiance. Seules les règles `active` entrent dans le prompt.

Les analyses elles-mêmes (Analysis) et l'avis 👍/👎 affiché au mobile
(AnalysisFeedback) restent dans `meals` (docs/technique/modele-donnees.md) :
`meals` transmet ses corrections à foodscan via `services.submit_review`.
"""

from __future__ import annotations

import uuid

from django.conf import settings
from django.db import models


class DishKnowledge(models.Model):
    class Scope(models.TextChoices):
        COUNTRY = "country", "Pays"
        REGION = "region", "Région"

    class Origin(models.TextChoices):
        EDITORIAL = "editorial", "Rédigée par l'équipe"
        REVIEW = "review", "Issue des avis"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    key = models.SlugField(max_length=80, help_text="Clé stable, ex. ndole")
    name = models.CharField(max_length=80, help_text="Nom usuel affiché")
    aliases = models.JSONField(default=list, blank=True, help_text="Noms locaux")
    scope = models.CharField(max_length=10, choices=Scope.choices, default=Scope.COUNTRY)
    country = models.CharField(max_length=2, blank=True, help_text="ISO 3166-1 alpha-2, si scope = pays")
    region = models.CharField(max_length=32, help_text="Région culinaire (voir regions.py)")
    visual_description = models.TextField(help_text="Aspect : couleur, texture, composition")
    distinguishing_tips = models.TextField(blank=True, help_text="Comment ne pas le confondre")
    origin = models.CharField(max_length=10, choices=Origin.choices, default=Origin.EDITORIAL)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "fiche de plat"
        verbose_name_plural = "fiches de plats"
        constraints = [
            models.UniqueConstraint(fields=["key", "country", "region"], name="foodscan_dish_unique_scope"),
        ]
        indexes = [
            models.Index(fields=["country", "is_active"]),
            models.Index(fields=["region", "is_active"]),
        ]

    def __str__(self) -> str:
        return f"{self.name} ({self.country or self.region})"


class ScanReview(models.Model):
    class Status(models.TextChoices):
        PROPOSED = "proposed", "Proposé"
        VALIDATED = "validated", "Validé"
        REJECTED = "rejected", "Rejeté"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+")
    # Identifiant de l'analyse côté `meals` (pas de FK : foodscan ne dépend pas de meals).
    analysis_id = models.UUIDField(null=True, blank=True)
    country = models.CharField(max_length=2, blank=True)
    predicted_key = models.CharField(max_length=80, blank=True)
    predicted_label = models.CharField(max_length=80, blank=True)
    correct_key = models.CharField(max_length=80)
    correct_label = models.CharField(max_length=80)
    # Photo conservée seulement si l'utilisateur y a consenti (clé du bucket privé).
    photo_key = models.CharField(max_length=255, blank=True)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PROPOSED)
    decided_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="+"
    )
    decided_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "avis de scan"
        verbose_name_plural = "avis de scan"
        constraints = [
            models.UniqueConstraint(
                fields=["user", "analysis_id"],
                condition=models.Q(analysis_id__isnull=False),
                name="foodscan_review_one_per_analysis",
            ),
        ]
        indexes = [models.Index(fields=["country", "predicted_key", "status"])]

    def __str__(self) -> str:
        return f"{self.predicted_label or '?'} → {self.correct_label} ({self.country or '??'})"

    @property
    def is_correction(self) -> bool:
        return bool(self.predicted_key) and self.predicted_key != self.correct_key


class ConfusionRule(models.Model):
    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        DISABLED = "disabled", "Désactivée"

    class Origin(models.TextChoices):
        CONSENSUS = "consensus", "Consensus des utilisateurs"
        MODERATOR = "moderator", "Validateur de confiance"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    country = models.CharField(max_length=2)
    predicted_key = models.CharField(max_length=80)
    predicted_label = models.CharField(max_length=80)
    correct_key = models.CharField(max_length=80)
    correct_label = models.CharField(max_length=80)
    support = models.PositiveIntegerField(default=0, help_text="Utilisateurs distincts")
    agreement = models.FloatField(default=0.0)
    hint = models.TextField(blank=True, help_text="Indice visuel rédigé par l'équipe (facultatif)")
    origin = models.CharField(max_length=10, choices=Origin.choices, default=Origin.CONSENSUS)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.ACTIVE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "règle de confusion"
        verbose_name_plural = "règles de confusion"
        constraints = [
            models.UniqueConstraint(
                fields=["country", "predicted_key", "correct_key"], name="foodscan_rule_unique_pair"
            ),
        ]
        indexes = [models.Index(fields=["country", "status"])]

    def __str__(self) -> str:
        return f"{self.country} : {self.predicted_label} → {self.correct_label}"
