import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Plus grand côté d'une photo envoyée à l'analyse.
const maxPhotoSide = 1600;

/// Qualité JPEG des photos envoyées.
const photoJpegQuality = 80;

/// Photo illisible (format non pris en charge ou fichier abîmé).
final class UnreadablePhotoException implements Exception {
  const UnreadablePhotoException();
}

/// Compresse une photo sur l'appareil : orientation EXIF appliquée,
/// métadonnées retirées (position GPS comprise), plus grand côté ramené à
/// [maxPhotoSide], JPEG qualité [photoJpegQuality]. Exécuté hors du fil
/// d'interface.
Future<Uint8List> compressPhoto(Uint8List bytes) => compute(_compress, bytes);

Uint8List _compress(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const UnreadablePhotoException();
  final oriented = img.bakeOrientation(decoded)..exif = img.ExifData();
  final longest = oriented.width > oriented.height
      ? oriented.width
      : oriented.height;
  final resized = longest <= maxPhotoSide
      ? oriented
      : oriented.width >= oriented.height
      ? img.copyResize(oriented, width: maxPhotoSide)
      : img.copyResize(oriented, height: maxPhotoSide);
  return img.encodeJpg(resized, quality: photoJpegQuality);
}
