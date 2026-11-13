"""Extensions PostgreSQL : unaccent et pg_trgm (recherche des villes, aliments et plats)."""

from django.contrib.postgres.operations import TrigramExtension, UnaccentExtension
from django.db import migrations


class Migration(migrations.Migration):
    initial = True
    dependencies: list[tuple[str, str]] = []
    operations = [UnaccentExtension(), TrigramExtension()]
