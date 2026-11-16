import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:omeo/features/meals/data/photo_compressor.dart';

Uint8List _png(int width, int height) =>
    img.encodePng(img.Image(width: width, height: height));

void main() {
  test('ramène le plus grand côté à 1600 px en JPEG', () async {
    final out = img.decodeJpg(await compressPhoto(_png(4000, 3000)))!;
    expect(out.width, maxPhotoSide);
    expect(out.height, 1200);
  });

  test('photo en portrait : la hauteur est limitée', () async {
    final out = img.decodeJpg(await compressPhoto(_png(1500, 3200)))!;
    expect(out.height, maxPhotoSide);
  });

  test("ne l'agrandit jamais", () async {
    final out = img.decodeJpg(await compressPhoto(_png(800, 600)))!;
    expect((out.width, out.height), (800, 600));
  });

  test('fichier illisible : exception dédiée', () {
    expect(
      compressPhoto(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<UnreadablePhotoException>()),
    );
  });
}
