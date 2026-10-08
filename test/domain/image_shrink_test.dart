import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:rebusarna/domain/image_shrink.dart';

void main() {
  test('velký šumový PNG se zmenší pod 1 MB jako JPEG', () {
    final rnd = Random(1);
    final big = img.Image(width: 3000, height: 4500);
    for (final px in big) {
      px
        ..r = rnd.nextInt(256)
        ..g = rnd.nextInt(256)
        ..b = rnd.nextInt(256);
    }
    final png = Uint8List.fromList(img.encodePng(big, level: 1));
    expect(png.length, greaterThan(kMaxImageBytes));

    final out = shrinkImage(png)!;
    expect(out.length, lessThanOrEqualTo(kMaxImageBytes));
    final back = img.decodeJpg(out)!;
    expect(max(back.width, back.height), lessThanOrEqualTo(1500));
  });

  test('nečitelná data vrátí null', () {
    expect(shrinkImage(Uint8List.fromList([1, 2, 3])), isNull);
  });
}
