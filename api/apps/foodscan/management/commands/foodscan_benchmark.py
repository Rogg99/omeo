"""
Mesure la précision du scan sur un jeu de test étiqueté.

    python manage.py foodscan_benchmark chemin/vers/jeu --country CM --compare

Le jeu est rangé par plat, le nom du dossier étant la clé attendue :

    jeu/ndole/001.jpg
    jeu/eru/001.jpg

Une réponse est juste si `dish_key`, ou à défaut la clé du `dish_label`,
vaut le nom du dossier. `--compare` lance chaque photo deux fois, sans puis
avec la base de connaissances : c'est la seule façon de savoir si les avis
améliorent réellement les décisions. Chaque photo coûte un appel à l'IA par
passe.
"""

from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path
from typing import Any

from django.core.management.base import BaseCommand, CommandError, CommandParser

from apps.foodscan import services
from apps.foodscan.schemas import normalize_key

IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png", ".webp"}


def _predicted_keys(result: services.ScanResult) -> list[str]:
    if not result.output:
        return []
    out = result.output
    keys = [out.dish_key or normalize_key(out.dish_label)]
    keys += [alt.dish_key or normalize_key(alt.dish_label) for alt in out.alternatives]
    return [k for k in keys if k]


class Command(BaseCommand):
    help = "Mesure la précision du scan sur un jeu de photos rangées par plat."

    def add_arguments(self, parser: CommandParser) -> None:
        parser.add_argument("dataset", type=Path)
        parser.add_argument("--country", default=None, help="Pays ISO simulé pour l'utilisateur")
        parser.add_argument("--locale", default="fr")
        parser.add_argument("--compare", action="store_true", help="Sans puis avec la base de connaissances")
        parser.add_argument("--limit", type=int, default=0, help="Photos maximum par plat (0 = toutes)")
        parser.add_argument("--report", type=Path, default=None, help="Écrit le détail en JSON")

    def handle(self, *args: Any, **options: Any) -> None:
        root: Path = options["dataset"]
        if not root.is_dir():
            raise CommandError(f"Dossier introuvable : {root}")

        samples: list[tuple[str, Path]] = []
        for folder in sorted(p for p in root.iterdir() if p.is_dir()):
            files = sorted(f for f in folder.iterdir() if f.suffix.lower() in IMAGE_SUFFIXES)
            if options["limit"]:
                files = files[: options["limit"]]
            samples += [(normalize_key(folder.name), f) for f in files]
        if not samples:
            raise CommandError("Aucune photo trouvée.")

        passes = [False, True] if options["compare"] else [True]
        report: dict[str, Any] = {"country": options["country"], "samples": len(samples), "passes": {}}

        for use_knowledge in passes:
            name = "avec_connaissances" if use_knowledge else "sans_connaissances"
            self.stdout.write(f"\n— Passe {name} ({len(samples)} photos)")
            per_dish: dict[str, list[int]] = defaultdict(lambda: [0, 0, 0])  # total, top1, top3
            details, failures, cost = [], 0, 0

            for expected, path in samples:
                result = services.scan_photo(
                    image_bytes=path.read_bytes(),
                    country=options["country"],
                    locale=options["locale"],
                    use_knowledge=use_knowledge,
                )
                keys = _predicted_keys(result)
                top1 = bool(keys) and keys[0] == expected
                top3 = expected in keys[:3]
                stats = per_dish[expected]
                stats[0] += 1
                stats[1] += top1
                stats[2] += top3
                failures += not result.succeeded
                cost += result.cost_usd_micros or 0
                details.append(
                    {"file": str(path), "expected": expected, "predicted": keys, "top1": top1,
                     "failure": result.failure_reason, "confidence": result.output.confidence if result.output else None}
                )
                mark = "✓" if top1 else ("~" if top3 else "✗")
                self.stdout.write(f"  {mark} {expected:<28} → {keys[0] if keys else result.failure_reason}")

            total = len(samples)
            top1_total = sum(s[1] for s in per_dish.values())
            top3_total = sum(s[2] for s in per_dish.values())
            summary = {
                "top1": round(top1_total / total, 3),
                "top3": round(top3_total / total, 3),
                "failures": failures,
                "cost_usd": round(cost / 1_000_000, 4),
                "per_dish": {k: {"n": v[0], "top1": round(v[1] / v[0], 3)} for k, v in sorted(per_dish.items())},
                "details": details,
            }
            report["passes"][name] = summary
            self.stdout.write(
                self.style.SUCCESS(
                    f"  top-1 {summary['top1']:.1%} · top-3 {summary['top3']:.1%} · "
                    f"échecs {failures} · coût {summary['cost_usd']} $"
                )
            )

        if options["report"]:
            options["report"].write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
            self.stdout.write(f"\nRapport : {options['report']}")
