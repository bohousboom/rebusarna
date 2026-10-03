/// Validace rozpracovaného rébusu. Vrací chybové hlášky (prázdný seznam = OK).
/// Vysvětlení je povinné při vytvoření; při úpravě (např. importovaného rébusu) ne.
List<String> validateDraft({
  required String? image,
  required String solution,
  required String explanation,
  bool requireExplanation = true,
}) {
  final errors = <String>[];
  if (image == null || image.isEmpty) errors.add('Vyber obrázek rébusu.');
  if (solution.trim().isEmpty) errors.add('Zadej řešení.');
  if (requireExplanation && explanation.trim().isEmpty) {
    errors.add('Napiš vysvětlení, jak se k řešení dospěje.');
  }
  return errors;
}
