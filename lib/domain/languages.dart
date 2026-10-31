/// Jazyky nabízené u rébusů druhu „cizí jazyk“ (název a vlajka).
const kLanguages = <(String, String)>[
  ('angličtina', '🇬🇧'),
  ('španělština', '🇪🇸'),
  ('němčina', '🇩🇪'),
  ('francouzština', '🇫🇷'),
  ('italština', '🇮🇹'),
];

/// Vlajka pro název jazyka (bez ohledu na velikost písmen); u neznámého jazyka null.
String? languageFlag(String? name) {
  final n = name?.trim().toLowerCase();
  for (final (label, flag) in kLanguages) {
    if (label == n) return flag;
  }
  return null;
}

/// „🇬🇧 angličtina“ (bez vlajky jen název).
String languageLabel(String name) {
  final flag = languageFlag(name);
  return flag == null ? name : '$flag $name';
}
