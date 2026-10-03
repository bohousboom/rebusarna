enum WordType {
  verb('sloveso'),
  noun('podstatné jméno'),
  adjective('přídavné jméno'),
  city('město'),
  other('jiné');

  const WordType(this.label);
  final String label;

  static WordType fromName(String? name) => WordType.values.firstWhere(
        (t) => t.name == name,
        orElse: () => WordType.other,
      );
}
