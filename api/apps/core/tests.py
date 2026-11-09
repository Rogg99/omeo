from urllib.parse import parse_qs, urlparse

from django.test import SimpleTestCase, override_settings

from apps.core import storage

S3 = {
    "S3_ENDPOINT_URL": "http://minio:9000",
    "S3_PUBLIC_ENDPOINT_URL": "http://s3.localhost",
    "S3_REGION": "us-east-1",
    "S3_ACCESS_KEY_ID": "test",
    "S3_SECRET_ACCESS_KEY": "test-secret",
    "S3_PRIVATE_BUCKET": "omeo-private",
    "S3_PUBLIC_BUCKET": "omeo-public",
    "S3_PUBLIC_BASE_URL": "http://s3.localhost/omeo-public",
}


@override_settings(**S3)
class StorageTests(SimpleTestCase):
    """Signature hors ligne : aucun appel réseau, aucun conteneur nécessaire."""

    def setUp(self) -> None:
        storage.internal_client.cache_clear()
        storage.signing_client.cache_clear()

    def test_upload_url_is_signed_for_public_host_and_private_bucket(self) -> None:
        key = storage.build_key(prefix="meal_photo", owner_id="u1", extension="jpg")
        upload = storage.presign_upload(key=key, content_type="image/jpeg", size=1234)
        url = urlparse(upload.url)
        self.assertEqual(url.netloc, "s3.localhost")
        self.assertTrue(url.path.startswith(f"/omeo-private/{key}"))
        signed = parse_qs(url.query)["X-Amz-SignedHeaders"][0].split(";")
        self.assertIn("content-type", signed)
        self.assertIn("content-length", signed)
        self.assertEqual(upload.headers, {"Content-Type": "image/jpeg"})

    def test_keys_are_unique_and_scoped_by_owner(self) -> None:
        a = storage.build_key(prefix="avatar", owner_id="u1", extension=".png")
        b = storage.build_key(prefix="avatar", owner_id="u1", extension="png")
        self.assertNotEqual(a, b)
        self.assertRegex(a, r"^avatar/u1/[0-9a-f]{32}\.png$")

    def test_download_url_expires(self) -> None:
        url = storage.presign_download(key="exports/u1/x.zip", filename="omeo.zip", ttl=60)
        query = parse_qs(urlparse(url).query)
        self.assertEqual(query["X-Amz-Expires"], ["60"])
        self.assertIn("attachment", query["response-content-disposition"][0])

    def test_public_url(self) -> None:
        self.assertEqual(storage.public_url("/recipes/a.jpg"), "http://s3.localhost/omeo-public/recipes/a.jpg")

    def test_rejects_empty_upload(self) -> None:
        with self.assertRaises(ValueError):
            storage.presign_upload(key="k", content_type="image/jpeg", size=0)
