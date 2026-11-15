"""Briques pures du socle : UUID v7, textes traduits, erreurs, journaux, images, versions."""

from __future__ import annotations

import base64
import hashlib
import io
import time
from urllib.parse import urljoin

import pytest
from PIL import Image
from pytest_django.fixtures import SettingsWrapper
from rest_framework.exceptions import ErrorDetail

from apps.core import i18n
from apps.core.errors import _flatten_drf_errors
from apps.core.ids import uuid7
from apps.core.logging import REDACTED, scrub, scrub_text, sentry_before_send
from apps.core.middleware import parse_version
from apps.core.storage import public_url
from apps.meals import images


class TestUuid7:
    def test_version_and_variant(self) -> None:
        value = uuid7()
        assert value.version == 7
        assert value.variant == "specified in RFC 4122"

    def test_sortable_in_time(self) -> None:
        first = uuid7()
        time.sleep(0.002)
        assert uuid7() > first

    def test_unique(self) -> None:
        assert len({uuid7() for _ in range(1000)}) == 1000


class TestI18n:
    def test_requested_locale(self) -> None:
        assert i18n.resolve({"fr": "Bonjour", "en": "Hello", "ja": "こんにちは"}, "ja") == "こんにちは"

    def test_fallback_en_then_fr(self) -> None:
        assert i18n.resolve({"fr": "Bonjour", "en": "Hello"}, "de") == "Hello"
        assert i18n.resolve({"fr": "Bonjour"}, "de") == "Bonjour"

    def test_empty_value_falls_back(self) -> None:
        assert i18n.resolve({"de": "", "fr": "Bonjour"}, "de") == "Bonjour"

    def test_empty(self) -> None:
        assert i18n.resolve(None, "fr") == ""

    @pytest.mark.parametrize(
        ("django", "api"), [("zh-hans", "zh"), ("fr-fr", "fr"), ("en", "en"), ("xx", "fr"), (None, "fr")]
    )
    def test_to_api_locale(self, django: str | None, api: str) -> None:
        assert i18n.to_api_locale(django) == api

    def test_validator_rejects_unknown_locale(self) -> None:
        from django.core.exceptions import ValidationError

        with pytest.raises(ValidationError):
            i18n.validate_i18n_text({"klingon": "x"})


class TestErrorFlattening:
    def test_nested_fields(self) -> None:
        detail = {
            "profile": {"height_cm": [ErrorDetail("too small", code="min_value")]},
            "consents": [{}, {"kind": [ErrorDetail("bad", code="invalid_choice")]}],
        }
        assert _flatten_drf_errors(detail) == {
            "profile.height_cm": [{"code": "min_value", "message": "too small"}],
            "consents.1.kind": [{"code": "invalid_choice", "message": "bad"}],
        }


class TestLogScrubbing:
    def test_masks_sensitive_keys(self) -> None:
        assert scrub({"password": "x", "weight_kg": 80, "path": "/me"}) == {
            "password": REDACTED,
            "weight_kg": REDACTED,
            "path": "/me",
        }

    def test_masks_emails_in_text(self) -> None:
        assert scrub_text("login failed for awa@example.com") == "login failed for ***@example.com"

    def test_sentry_filter(self) -> None:
        event = {
            "request": {"data": {"password": "x"}, "cookies": "a", "headers": {"Authorization": "Bearer t", "X": "1"}},
            "user": {"id": "u1", "email": "awa@example.com"},
        }
        cleaned = sentry_before_send(event, {})
        assert cleaned["request"] == {"headers": {"X": "1"}}
        assert cleaned["user"] == {"id": "u1"}


class TestVersions:
    def test_parse(self) -> None:
        assert parse_version("1.4") == (1, 4, 0)
        assert parse_version("1.10.2") > parse_version("1.9.9")


def _image_bytes(fmt: str, *, exif: bool = False) -> bytes:
    image = Image.new("RGB", (40, 20), "red")
    out = io.BytesIO()
    if exif:
        data = Image.Exif()
        data[0x0110] = "Secret phone"  # modèle
        image.save(out, format=fmt, exif=data.tobytes())
    else:
        image.save(out, format=fmt)
    return out.getvalue()


class TestImages:
    @pytest.mark.parametrize(("fmt", "mime"), [("JPEG", "image/jpeg"), ("PNG", "image/png"), ("WEBP", "image/webp")])
    def test_sniff(self, fmt: str, mime: str) -> None:
        assert images.sniff(_image_bytes(fmt)) == mime

    def test_rejects_non_image(self) -> None:
        with pytest.raises(images.InvalidImageError) as exc:
            images.sanitize(b"%PDF-1.7 not an image")
        assert exc.value.reason == "unsupported_type"

    def test_rejects_truncated(self) -> None:
        with pytest.raises(images.InvalidImageError) as exc:
            images.sanitize(_image_bytes("JPEG")[:40])
        assert exc.value.reason == "corrupted"

    def test_rejects_too_large(self) -> None:
        with pytest.raises(images.InvalidImageError):
            images.sanitize(b"\xff\xd8\xff" + b"0" * images.MAX_BYTES)

    def test_strips_exif(self) -> None:
        cleaned = images.sanitize(_image_bytes("JPEG", exif=True))
        with Image.open(io.BytesIO(cleaned.data)) as result:
            assert not result.getexif()
        assert (cleaned.width, cleaned.height) == (40, 20)
        assert cleaned.content_type == "image/jpeg"


class TestSignedMediaUrl:
    """URL des médias publiés, vérifiées par nginx secure_link (deploy/nginx)."""

    SECRET = "s" * 40

    @pytest.fixture(autouse=True)
    def _media(self, settings: SettingsWrapper) -> None:
        settings.MEDIA_URL_SECRET = self.SECRET
        settings.MEDIA_URL_BASE = "https://media.my-omeo.app"
        settings.MEDIA_URL_TTL_SECONDS = 3600

    def test_format_and_token(self) -> None:
        url = public_url("media/video/shared/abc/master.m3u8", now=7200)
        expires = 4 * 3600  # début de la fenêtre courante (7200) + 2 fenêtres
        digest = hashlib.md5(f"{expires}:media/video/shared/abc:{self.SECRET}".encode(), usedforsecurity=False).digest()
        token = base64.urlsafe_b64encode(digest).rstrip(b"=").decode()
        assert url == f"https://media.my-omeo.app/m/{expires}/{token}/media/video/shared/abc/-/master.m3u8"

    def test_stable_within_window_and_valid_at_least_one_window(self) -> None:
        key = "media/image/shared/x.webp"
        assert public_url(key, now=3600) == public_url(key, now=7199)
        expires = int(public_url(key, now=7199).split("/")[4])
        assert expires - 7199 >= 3600

    def test_hls_relative_paths_keep_the_token(self) -> None:
        manifest = public_url("media/video/shared/abc/master.m3u8", now=0)
        variant = urljoin(manifest, "720p/index.m3u8")
        assert variant.startswith(manifest.rsplit("/-/", 1)[0] + "/-/720p/")

    def test_rejects_key_without_folder(self) -> None:
        with pytest.raises(ValueError, match="inside a folder"):
            public_url("orphan.png")

    def test_unsigned_without_secret(self, settings: SettingsWrapper) -> None:
        settings.MEDIA_URL_SECRET = ""
        settings.S3_PUBLIC_BASE_URL = "http://s3.localhost/omeo-public"
        assert public_url("/a/b.png") == "http://s3.localhost/omeo-public/a/b.png"


class TestWebCacheSignature:
    """Même vecteur que web/tests/unit/security.test.ts : les deux côtés signent pareil."""

    def test_matches_web_vector(self) -> None:
        from apps.core.web_cache import body_for, sign

        body = body_for(["faq"])
        assert body == '{"tags":["faq"]}'
        assert sign("s" * 32, "1700000000", body) == (
            "sha256=2354b238d08b33e682eb7f7a3105c795e25c01075441f756a88eeb9c05139808"
        )

    def test_body_is_sorted_and_deduplicated(self) -> None:
        from apps.core.web_cache import body_for

        assert body_for(["plans", "faq", "plans"]) == '{"tags":["faq","plans"]}'
