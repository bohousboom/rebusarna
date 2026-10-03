import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/models/puzzle.dart';
import '../../domain/models/word_type.dart';
import '../../domain/text_logic.dart';

IconData wordTypeIcon(WordType t) => switch (t) {
      WordType.verb => Icons.directions_run,
      WordType.noun => Icons.label,
      WordType.adjective => Icons.brush,
      WordType.city => Icons.location_city,
      WordType.other => Icons.more_horiz,
    };

/// Obrázek rébusu: asset, soubor v zařízení (nebo URL na webu).
class PuzzleImage extends StatelessWidget {
  const PuzzleImage(this.image, {super.key, this.fit = BoxFit.contain, this.cacheWidth});

  final String image;
  final BoxFit fit;

  /// Šířka v pixelech, na kterou se obrázek při dekódování zmenší (úspora paměti).
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    Widget broken(BuildContext _, Object e, StackTrace? s) =>
        const Center(child: Icon(Icons.broken_image, size: 48));
    if (image.startsWith(kImageAssetPrefix)) {
      return Image.asset(image, fit: fit, cacheWidth: cacheWidth, errorBuilder: broken);
    }
    if (kIsWeb || image.startsWith('http')) {
      return Image.network(image, fit: fit, errorBuilder: broken);
    }
    return Image.file(File(image), fit: fit, cacheWidth: cacheWidth, errorBuilder: broken);
  }
}

/// Karta rébusu: bílá zaoblená karta, vlevo nahoře barevný štítek
/// (? vždy, ± bez čárek v řešení, druh slova; barva = obtížnost).
class PuzzleCard extends StatelessWidget {
  const PuzzleCard({
    super.key,
    required this.image,
    required this.solution,
    required this.wordType,
    required this.difficulty,
    this.favorite,
    this.onFavorite,
    this.highlight = false,
    this.adult = false,
  });

  final String image;

  /// Slouží jen k odvození štítku ±; nikdy se nezobrazuje.
  final String solution;
  final WordType wordType;
  final int difficulty;
  final bool? favorite;
  final VoidCallback? onFavorite;
  final bool highlight;
  final bool adult;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlight ? Colors.green : Colors.black12,
          width: highlight ? 4 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: PuzzleImage(image, cacheWidth: 900),
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DifficultyBadge(
                  difficulty: difficulty,
                  wordType: wordType,
                  showPlusMinus: solution.trim().isNotEmpty && hasNoAcute(solution),
                ),
                if (adult) ...[const SizedBox(width: 6), const AdultChip()],
              ],
            ),
          ),
          if (favorite != null)
            Positioned(
              right: 4,
              top: 4,
              child: IconButton(
                key: const Key('favorite-button'),
                tooltip: 'Oblíbené',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white70,
                  minimumSize: const Size(48, 48),
                ),
                icon: Icon(
                  favorite! ? Icons.favorite : Icons.favorite_border,
                  color: Colors.redAccent,
                ),
                onPressed: onFavorite,
              ),
            ),
        ],
      ),
    );
  }
}

/// Značka 18+.
class AdultChip extends StatelessWidget {
  const AdultChip({super.key});

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('adult-chip'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('18+',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
      );
}

class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({
    super.key,
    required this.difficulty,
    required this.wordType,
    required this.showPlusMinus,
  });

  final int difficulty;
  final WordType wordType;
  final bool showPlusMinus;

  @override
  Widget build(BuildContext context) {
    final color = difficultyColor(difficulty);
    final fg = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final style = TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('?', style: style),
          if (showPlusMinus) ...[
            const SizedBox(width: 8),
            Text('±', key: const Key('badge-plusminus'), style: style),
          ],
          const SizedBox(width: 8),
          Icon(wordTypeIcon(wordType), size: 18, color: fg),
          const SizedBox(width: 4),
          Text(wordType.label,
              style: style.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
