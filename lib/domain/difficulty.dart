/// Očekávaná „cena" řešení (špatné tipy + nápovědy + odhalení) pro obtížnost zadanou autorem.
const _priorScore = {1: 0.5, 2: 2.5, 3: 6.0};

/// Váha autorova odhadu: odpovídá počtu hráčů, kteří ho „přebijí".
const kDifficultyPriorWeight = 8;

/// Cena jednoho řešení: špatné tipy (nejvýše 5) + 2 za každou nápovědu + 6 za ukázané řešení.
/// Musí odpovídat generovanému sloupci `score` v tabulce `puzzle_results`.
int resultScore({required int wrong, required int hints, required bool revealed}) =>
    (wrong < 5 ? wrong : 5) + 2 * hints + (revealed ? 6 : 0);

/// Výsledná obtížnost 1–3: autorův odhad vyhlazený průměrem skóre hráčů.
/// Bez hráčů ([n] == 0) platí obtížnost od autora.
int computeDifficulty({
  required int authorDifficulty,
  required int n,
  required double avgScore,
}) {
  final prior = _priorScore[authorDifficulty] ?? _priorScore[2]!;
  final s = (kDifficultyPriorWeight * prior + n * avgScore) /
      (kDifficultyPriorWeight + n);
  if (s < 1.5) return 1;
  if (s < 4) return 2;
  return 3;
}
