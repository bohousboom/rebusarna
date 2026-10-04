import '../text_logic.dart';
import 'word_type.dart';

/// Cesta k vestavěným obrázkům (assets).
const kImageAssetPrefix = 'assets/images/';

/// Rébus = jeden hotový obrázek + skryté řešení.
class Puzzle {
  const Puzzle({
    required this.id,
    required this.image,
    required this.solution,
    required this.wordTypes,
    required this.difficulty,
    required this.authorName,
    required this.createdAt,
    this.meaning,
    this.explanation,
    this.ownerId,
    this.adult = false,
    this.plusMinus = false,
    this.ratingSum = 0,
    this.ratingCount = 0,
  });

  final String id;

  /// Asset (`assets/images/...`) nebo cesta k souboru v zařízení.
  final String image;
  final String solution;
  final String? meaning;

  /// Vysvětlení, jak se od obrázku dospěje k řešení.
  final String? explanation;

  /// Id autora (Supabase uživatel); u vestavěných rébusů null.
  final String? ownerId;

  /// Obsah pro dospělé (18+): v hádání se ukáže jen po zapnutí uživatelem.
  final bool adult;

  /// Štítek ± (řešení se píše jinak, než se vyslovuje); nastavuje autor.
  final bool plusMinus;
  /// Jeden nebo více druhů slova (vždy aspoň jeden); první je hlavní.
  final List<WordType> wordTypes;

  /// 1 = lehká, 2 = střední, 3 = těžká.
  final int difficulty;
  final String authorName;
  final DateTime createdAt;
  final int ratingSum;
  final int ratingCount;

  WordType get wordType => wordTypes.first;

  bool get isAssetImage => image.startsWith(kImageAssetPrefix);

  Map<String, dynamic> toJson() => {
        'id': id,
        'image': image,
        'solution': solution,
        if (meaning != null) 'meaning': meaning,
        if (explanation != null) 'explanation': explanation,
        if (ownerId != null) 'ownerId': ownerId,
        if (adult) 'adult': true,
        if (plusMinus) 'plusMinus': true,
        'wordType': wordType.name,
        'wordTypes': [for (final t in wordTypes) t.name],
        'difficulty': difficulty,
        'authorName': authorName,
        'createdAt': createdAt.toIso8601String(),
        'ratingSum': ratingSum,
        'ratingCount': ratingCount,
      };

  factory Puzzle.fromJson(Map<String, dynamic> json) => Puzzle(
        id: json['id'] as String,
        image: json['image'] as String,
        solution: json['solution'] as String,
        meaning: json['meaning'] as String?,
        explanation: json['explanation'] as String?,
        ownerId: json['ownerId'] as String?,
        adult: json['adult'] as bool? ?? false,
        // starší záznamy bez příznaku: odvodit z řešení
        plusMinus: json['plusMinus'] as bool? ?? hasNoAcute(json['solution'] as String),
        wordTypes: WordType.listFrom(json['wordTypes'], json['wordType'] as String?),
        difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
        authorName: json['authorName'] as String? ?? 'Neznámý',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        ratingSum: (json['ratingSum'] as num?)?.toInt() ?? 0,
        ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      );
}
