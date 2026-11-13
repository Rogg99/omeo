"""
Régions culinaires : à quelle cuisine se rattache le pays de l'utilisateur.

Sert au contexte géographique du scan. Le pays seul est trop étroit (le
jollof est autant ghanéen que nigérian), la région donne les plats voisins.
Module pur : aucune dépendance à Django, testable isolément.
"""

from __future__ import annotations

# Une région = une cuisine partagée. Les libellés sont envoyés tels quels à l'IA.
REGIONS: dict[str, str] = {
    "west_africa": "Afrique de l'Ouest",
    "central_africa": "Afrique centrale",
    "east_south_africa": "Afrique de l'Est et australe",
    "maghreb": "Maghreb",
    "middle_east": "Moyen-Orient",
    "europe": "Europe",
    "north_america": "Amérique du Nord",
    "latin_america": "Amérique latine",
    "india": "Inde",
    "south_asia": "Asie du Sud et du Sud-Est",
    "china": "Chine",
    "japan_korea": "Japon et Corée",
}

COUNTRY_REGION: dict[str, str] = {
    # Afrique de l'Ouest
    **dict.fromkeys(
        ["BJ", "BF", "CV", "CI", "GM", "GH", "GN", "GW", "LR", "ML", "MR", "NE", "NG", "SN", "SL", "TG"],
        "west_africa",
    ),
    # Afrique centrale (Cameroun en tête)
    **dict.fromkeys(["CM", "CF", "TD", "CG", "CD", "GQ", "GA", "ST", "AO", "BI", "RW"], "central_africa"),
    # Afrique de l'Est et australe
    **dict.fromkeys(
        ["KE", "TZ", "UG", "ET", "ER", "DJ", "SO", "SS", "SD", "MG", "MU", "SC", "KM", "MZ", "MW", "ZM",
         "ZW", "BW", "NA", "ZA", "LS", "SZ"],
        "east_south_africa",
    ),
    # Maghreb
    **dict.fromkeys(["MA", "DZ", "TN", "LY", "EG"], "maghreb"),
    # Moyen-Orient
    **dict.fromkeys(
        ["LB", "SY", "JO", "PS", "IL", "IQ", "IR", "TR", "SA", "AE", "QA", "KW", "BH", "OM", "YE"],
        "middle_east",
    ),
    # Europe
    **dict.fromkeys(
        ["FR", "BE", "CH", "LU", "MC", "DE", "AT", "NL", "GB", "IE", "ES", "PT", "IT", "GR", "PL", "CZ",
         "SK", "HU", "RO", "BG", "HR", "SI", "RS", "SE", "NO", "DK", "FI", "IS", "EE", "LV", "LT", "UA"],
        "europe",
    ),
    # Amérique du Nord
    **dict.fromkeys(["US", "CA"], "north_america"),
    # Amérique latine (Mexique compris)
    **dict.fromkeys(
        ["MX", "GT", "HN", "SV", "NI", "CR", "PA", "CU", "DO", "HT", "PR", "CO", "VE", "EC", "PE", "BO",
         "BR", "PY", "UY", "AR", "CL"],
        "latin_america",
    ),
    "IN": "india",
    **dict.fromkeys(["PK", "BD", "LK", "NP", "TH", "VN", "KH", "LA", "MM", "MY", "SG", "ID", "PH"], "south_asia"),
    **dict.fromkeys(["CN", "HK", "TW", "MO"], "china"),
    **dict.fromkeys(["JP", "KR"], "japan_korea"),
}


def normalize_country(country: str | None) -> str | None:
    """Code ISO 3166-1 alpha-2 en majuscules, ou None s'il est absent ou invalide."""
    if not country:
        return None
    code = country.strip().upper()
    return code if len(code) == 2 and code.isalpha() else None


def region_of(country: str | None) -> str | None:
    """Région culinaire d'un pays, ou None s'il n'est pas répertorié."""
    code = normalize_country(country)
    return COUNTRY_REGION.get(code) if code else None


def region_label(region: str | None) -> str | None:
    return REGIONS.get(region) if region else None
