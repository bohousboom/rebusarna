import 'package:flutter/material.dart' show IconData, Icons;

/// Sada (téma) rébusu. Hráč ji uvidí ve výběru sady, v nápovědě a po vyřešení;
/// na kartě se záměrně nezobrazuje (prozrazovala by řešení).
/// Seznam sad je v databázi (tabulka `puzzle_categories`) a spravuje ho správce;
/// [builtIn] je základní sada, která se používá i bez připojení k serveru.
class PuzzleCategory {
  const PuzzleCategory(this.id, this.label, {this.iconName});

  /// Hodnota ve sloupci `category` (malá písmena, číslice, podtržítko).
  final String id;
  final String label;

  /// Název ikony z [_icons]; neznámý nebo prázdný = obecná ikona.
  final String? iconName;

  IconData get icon => _icons[iconName] ?? Icons.folder_outlined;

  /// „Ostatní“ nic nevypovídá: nezobrazuje se v nápovědě ani po vyřešení.
  bool get isInformative => id != otherId;

  static const otherId = 'other';
  static const other = PuzzleCategory(otherId, 'Ostatní', iconName: 'more_horiz');

  static const builtIn = <PuzzleCategory>[
    PuzzleCategory('cesko', 'Česko: města a místa', iconName: 'location_city'),
    PuzzleCategory('svet', 'Svět: státy a města', iconName: 'public'),
    PuzzleCategory('priroda', 'Zvířata a příroda', iconName: 'pets'),
    PuzzleCategory('jidlo', 'Jídlo a pití', iconName: 'restaurant'),
    PuzzleCategory('domov', 'Domov a věci', iconName: 'chair_alt'),
    PuzzleCategory('doprava', 'Doprava a technika', iconName: 'directions_car'),
    PuzzleCategory('lide', 'Lidé a povolání', iconName: 'groups'),
    PuzzleCategory('mista', 'Místa a stavby', iconName: 'home_work'),
    PuzzleCategory('kultura', 'Kultura a sport', iconName: 'theater_comedy'),
    PuzzleCategory('pohadky', 'Pohádky a fantasy', iconName: 'auto_awesome'),
    PuzzleCategory('veda', 'Věda a tělo', iconName: 'science'),
    PuzzleCategory('cinnosti', 'Činnosti (slovesa)', iconName: 'directions_run'),
    PuzzleCategory('pojmy', 'Pojmy a čas', iconName: 'lightbulb_outline'),
    other,
  ];

  /// Id z názvu nové sady: bez diakritiky, malá písmena, mezery a znaky jako „_“.
  /// Prázdný výsledek = název se nedá použít.
  static String idFromLabel(String label) {
    const from = 'áäčďéěëíňóöřšťúůüýž';
    const to = 'aacdeeeinoorstuuuyz';
    final b = StringBuffer();
    for (final ch in label.trim().toLowerCase().split('')) {
      final i = from.indexOf(ch);
      b.write(i >= 0 ? to[i] : ch);
    }
    return b
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static const _icons = <String, IconData>{
    'location_city': Icons.location_city,
    'public': Icons.public,
    'pets': Icons.pets,
    'restaurant': Icons.restaurant,
    'chair_alt': Icons.chair_alt,
    'directions_car': Icons.directions_car,
    'groups': Icons.groups,
    'home_work': Icons.home_work,
    'theater_comedy': Icons.theater_comedy,
    'auto_awesome': Icons.auto_awesome,
    'science': Icons.science,
    'directions_run': Icons.directions_run,
    'lightbulb_outline': Icons.lightbulb_outline,
    'more_horiz': Icons.more_horiz,
  };
}
