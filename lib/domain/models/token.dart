enum TokenType { image, operator, text }

class PuzzleToken {
  const PuzzleToken({required this.type, required this.value});

  const PuzzleToken.image(String emoji)
      : type = TokenType.image,
        value = emoji;
  const PuzzleToken.operator(String op)
      : type = TokenType.operator,
        value = op;
  const PuzzleToken.text(String text)
      : type = TokenType.text,
        value = text;

  final TokenType type;
  final String value;

  Map<String, dynamic> toJson() => {'type': type.name, 'value': value};

  factory PuzzleToken.fromJson(Map<String, dynamic> json) => PuzzleToken(
        type: TokenType.values.firstWhere((t) => t.name == json['type']),
        value: json['value'] as String,
      );

  @override
  bool operator ==(Object other) =>
      other is PuzzleToken && other.type == type && other.value == value;

  @override
  int get hashCode => Object.hash(type, value);
}
