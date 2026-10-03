import 'token.dart';
import 'word_type.dart';

class Puzzle {
  const Puzzle({
    required this.id,
    required this.tokens,
    required this.solution,
    required this.wordType,
    required this.difficulty,
    required this.authorName,
    required this.createdAt,
    this.meaning,
    this.ratingSum = 0,
    this.ratingCount = 0,
  });

  final String id;
  final List<PuzzleToken> tokens;
  final String solution;
  final String? meaning;
  final WordType wordType;

  /// 1 = lehká, 2 = střední, 3 = těžká.
  final int difficulty;
  final String authorName;
  final DateTime createdAt;
  final int ratingSum;
  final int ratingCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tokens': tokens.map((t) => t.toJson()).toList(),
        'solution': solution,
        if (meaning != null) 'meaning': meaning,
        'wordType': wordType.name,
        'difficulty': difficulty,
        'authorName': authorName,
        'createdAt': createdAt.toIso8601String(),
        'ratingSum': ratingSum,
        'ratingCount': ratingCount,
      };

  factory Puzzle.fromJson(Map<String, dynamic> json) => Puzzle(
        id: json['id'] as String,
        tokens: (json['tokens'] as List)
            .map((t) => PuzzleToken.fromJson(t as Map<String, dynamic>))
            .toList(),
        solution: json['solution'] as String,
        meaning: json['meaning'] as String?,
        wordType: WordType.fromName(json['wordType'] as String?),
        difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
        authorName: json['authorName'] as String? ?? 'Neznámý',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        ratingSum: (json['ratingSum'] as num?)?.toInt() ?? 0,
        ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      );
}
