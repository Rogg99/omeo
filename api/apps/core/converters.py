"""Convertisseurs de routes partagés : dates ISO (`<isodate:date>`) et types de documents légaux."""

from __future__ import annotations

from datetime import date
from functools import cache

from django.urls import register_converter


class IsoDateConverter:
    regex = r"\d{4}-\d{2}-\d{2}"

    def to_python(self, value: str) -> date:
        return date.fromisoformat(value)

    def to_url(self, value: date) -> str:
        return value.isoformat()


@cache
def register_converters() -> None:
    register_converter(IsoDateConverter, "isodate")
