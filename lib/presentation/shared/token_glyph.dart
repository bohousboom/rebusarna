import 'package:flutter/material.dart';

import '../../domain/models/emoji_entry.dart';

/// Vykreslí obrázek tokenu: vlastní obrázek z assetu, nebo emoji jako text.
class TokenGlyph extends StatelessWidget {
  const TokenGlyph(this.value, {super.key, this.size = 40});

  final String value;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (isImageAsset(value)) {
      return Image.asset(
        value,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(Icons.broken_image, size: size),
      );
    }
    return Text(value, style: TextStyle(fontSize: size * 0.9, height: 1));
  }
}
