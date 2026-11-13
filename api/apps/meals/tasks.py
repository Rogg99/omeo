"""Tâches Celery de meals (file « ai »). Idempotentes : rejouer une tâche ne relance jamais une analyse traitée."""

from __future__ import annotations

from celery import shared_task

from apps.meals import services


@shared_task(name=services.RUN_ANALYSIS_TASK, acks_late=True, ignore_result=True)
def run_analysis(analysis_id: str) -> None:
    services.run_analysis(analysis_id=analysis_id)
