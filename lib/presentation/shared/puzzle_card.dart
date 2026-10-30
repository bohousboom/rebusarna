import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/models/puzzle.dart';
import '../../domain/models/word_type.dart';

IconData wordTypeIcon(WordType t) => switch (t) {
  WordType.verb => Icons.directions_run,
  WordType.noun => Icons.label,
  WordType.adjective => Icons.brush,
  WordType.city => Icons.location_city,
  WordType.plural => Icons.layers,
  WordType.foreign => Icons.translate,
  WordType.other => Icons.more_horiz,
};

/// Obrázek rébusu: asset, soubor v zařízení (nebo URL na webu).
class PuzzleImage extends StatelessWidget {
  const PuzzleImage(
    this.image, {
    super.key,
    this.fit = BoxFit.contain,
    this.cacheWidth,
  });

  final String image;
  final BoxFit fit;

  /// Šířka v pixelech, na kterou se obrázek při dekódování zmenší (úspora paměti).
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    Widget broken(BuildContext _, Object e, StackTrace? s) =>
        const Center(child: Icon(Icons.broken_image, size: 48));
    if (image.startsWith(kImageAssetPrefix)) {
      return Image.asset(
        image,
        fit: fit,
        cacheWidth: cacheWidth,
        errorBuilder: broken,
      );
    }
    if (kIsWeb || image.startsWith('http')) {
      return Image.network(image, fit: fit, errorBuilder: broken);
    }
    return Image.file(
      File(image),
      fit: fit,
      cacheWidth: cacheWidth,
      errorBuilder: broken,
    );
  }
}

/// Karta rébusu: bílá zaoblená karta, vlevo nahoře barevný štítek
/// (? vždy, ± bez čárek v řešení, druh slova; barva = obtížnost).
class PuzzleCard extends StatelessWidget {
  const PuzzleCard({
    super.key,
    required this.image,
    this.plusMinus = false,
    required this.wordTypes,
    required this.difficulty,
    this.favorite,
    this.onFavorite,
    this.highlight = false,
    this.adult = false,
    this.onExpand,
    this.onShare,
  });

  final String image;

  /// Klepnutí na kartu / ikonu rozšíření (celoobrazovkový náhled).
  final VoidCallback? onExpand;

  /// Tlačítko sdílení odkazu na kartě (pod srdíčkem).
  final VoidCallback? onShare;

  /// Zobrazit štítek ± (nastavuje autor).
  final bool plusMinus;
  final List<WordType> wordTypes;
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
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
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
          if (onExpand != null) ...[
            Positioned.fill(
              child: GestureDetector(
                key: const Key('card-expand-area'),
                behavior: HitTestBehavior.translucent,
                onTap: onExpand,
              ),
            ),
            const Positioned(
              right: 10,
              bottom: 10,
              child: IgnorePointer(
                child: Icon(Icons.fullscreen, color: Colors.black45, size: 28),
              ),
            ),
          ],
          Positioned(
            left: 10,
            top: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DifficultyBadge(
                  difficulty: difficulty,
                  wordTypes: wordTypes,
                  showPlusMinus: plusMinus,
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
          if (onShare != null)
            Positioned(
              right: 4,
              top: favorite != null ? 56 : 4,
              child: IconButton(
                key: const Key('share-button'),
                tooltip: 'Sdílet odkaz na rébus',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white70,
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.share_outlined, color: Colors.black87),
                onPressed: onShare,
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
  Widget build(BuildContext context) => Tooltip(
    message: 'Obsah pro dospělé (18+)',
    triggerMode: TooltipTriggerMode.tap,
    child: Container(
      key: const Key('adult-chip'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '18+',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    ),
  );
}

/// Štítek v rohu karty: jen symboly (? vždy, ± bez čárek, ikona druhu slova),
/// barva = obtížnost. Význam každého symbolu se ukáže po najetí myší (v telefonu klepnutím).
class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({
    super.key,
    required this.difficulty,
    required this.wordTypes,
    required this.showPlusMinus,
  });

  final int difficulty;
  final List<WordType> wordTypes;
  final bool showPlusMinus;

  Widget _hint(String message, Widget child, {Key? key}) => Tooltip(
    key: key,
    message: message,
    triggerMode: TooltipTriggerMode.tap,
    showDuration: const Duration(seconds: 4),
    preferBelow: true,
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final color = difficultyColor(difficulty);
    final fg = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final style = TextStyle(
      color: fg,
      fontWeight: FontWeight.w800,
      fontSize: 18,
    );
    return _hint(
      'Obtížnost: ${difficultyLabel(difficulty)} (barva štítku)',
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _hint(
              'Hádej skryté slovo nebo výraz z obrázku.',
              Text('?', style: style),
            ),
            if (showPlusMinus) ...[
              const SizedBox(width: 10),
              _hint(
                'Řešení neobsahuje čárky: délka samohlásek se neřeší (např. ó = o).',
                Text('±', key: const Key('badge-plusminus'), style: style),
              ),
            ],
            for (var i = 0; i < wordTypes.length; i++) ...[
              const SizedBox(width: 10),
              _hint(
                'Druh slova: ${wordTypes[i].label}',
                Icon(
                  wordTypeIcon(wordTypes[i]),
                  key: Key(i == 0 ? 'badge-wordtype' : 'badge-wordtype-$i'),
                  size: 22,
                  color: fg,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Celoobrazovkový náhled rébusu: obrázek se dá přiblížit; tlačítko ho zase zmenší.
Future<void> showPuzzleFullscreen(BuildContext context, String image) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: true,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, _) => Scaffold(
        key: const Key('fullscreen-preview'),
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              maxScale: 5,
              child: Center(child: PuzzleImage(image)),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton.filled(
                    key: const Key('fullscreen-close'),
                    tooltip: 'Zmenšit',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.fullscreen_exit),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}
