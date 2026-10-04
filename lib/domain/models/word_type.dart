enum WordType {
  verb('sloveso'),
  noun('podstatné jméno'),
  adjective('přídavné jméno'),
  city('město / místo'),
  plural('množné číslo'),
  other('jiné');

  const WordType(this.label);
  final String label;

  /// Seznam druhů ze seznamu názvů; když chybí, použije se starý jediný druh.
  static List<WordType> listFrom(Object? names, String? single) {
    final list = [
      if (names is List)
        for (final n in names) fromName(n as String?),
    ];
    return list.isEmpty ? [fromName(single)] : list.toSet().toList();
  }

  static WordType fromName(String? name) => WordType.values.firstWhere(
        (t) => t.name == name,
        orElse: () => WordType.other,
      );
}
