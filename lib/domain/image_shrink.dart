import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Limit nahrávaného obrázku (shodný s limitem bucketu v Supabase).
const kMaxImageBytes = 1024 * 1024;

/// Karta je v poměru 2:3; delší strana se zmenšuje na tento rozměr.
const _kMaxSide = 1500;

/// Zmenší a převede obrázek na JPEG tak, aby se vešel do [maxBytes].
/// Vrátí null, když se obrázek nepodaří přečíst (pak se použije originál).
/// Průhlednost se vyplní bílou.
Uint8List? shrinkImage(Uint8List bytes, {int maxBytes = kMaxImageBytes}) {
  try {
    return _shrink(bytes, maxBytes);
  } catch (_) {
    return null; // poškozený nebo nepodporovaný formát
  }
}

Uint8List? _shrink(Uint8List bytes, int maxBytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  var image = decoded;
  final longest = max(image.width, image.height);
  if (longest > _kMaxSide) {
    image = img.copyResize(
      image,
      width: image.width >= image.height ? _kMaxSide : null,
      height: image.height > image.width ? _kMaxSide : null,
      interpolation: img.Interpolation.average,
    );
  }
  if (image.hasAlpha) {
    final bg = img.Image(width: image.width, height: image.height, numChannels: 3)
      ..clear(img.ColorRgb8(255, 255, 255));
    image = img.compositeImage(bg, image);
  }

  // Nejdřív snižujeme kvalitu, pak i rozměr, dokud se nevejde.
  for (var scale = 1.0; scale >= 0.4; scale -= 0.15) {
    final sized = scale == 1.0
        ? image
        : img.copyResize(image,
            width: (image.width * scale).round(), interpolation: img.Interpolation.average);
    for (final quality in const [88, 80, 70, 60]) {
      final out = Uint8List.fromList(img.encodeJpg(sized, quality: quality));
      if (out.length <= maxBytes) return out;
    }
  }
  return null;
}
