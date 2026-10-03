import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/difficulty.dart';
import 'supabase_client.dart';

/// Souhrn výsledků hráčů u jednoho rébusu.
class DifficultyStat {
  const DifficultyStat({required this.n, required this.avgScore});

  final int n;
  final double avgScore;
}

/// Statistiky všech rébusů (puzzle_id -> souhrn). Bez Supabase nebo při chybě prázdné.
final difficultyStatsProvider = FutureProvider<Map<String, DifficultyStat>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return {};
  try {
    final rows = await client.from('puzzle_difficulty').select();
    return {
      for (final r in rows)
        r['puzzle_id'] as String: DifficultyStat(
          n: (r['n'] as num).toInt(),
          avgScore: (r['avg_score'] as num).toDouble(),
        ),
    };
  } catch (_) {
    return {};
  }
});

/// Obtížnost zobrazená na kartě; klíč = (id rébusu, obtížnost od autora).
final effectiveDifficultyProvider = Provider.family<int, (String, int)>((ref, key) {
  final stat = ref.watch(difficultyStatsProvider).value?[key.$1];
  if (stat == null) return key.$2;
  return computeDifficulty(authorDifficulty: key.$2, n: stat.n, avgScore: stat.avgScore);
});

/// Odešle výsledek přihlášeného hráče (jen první pokus; opakování se ignoruje).
class ResultReporter {
  ResultReporter(this._ref);

  final Ref _ref;

  Future<void> report({
    required String puzzleId,
    required int wrong,
    required int hints,
    required bool revealed,
  }) async {
    final client = _ref.read(supabaseClientProvider);
    final user = _ref.read(currentUserProvider).value;
    if (client == null || user == null) return;
    try {
      await client.from('puzzle_results').upsert(
        {
          'user_id': user.id,
          'puzzle_id': puzzleId,
          'wrong': wrong,
          'hints': hints,
          'revealed': revealed,
        },
        ignoreDuplicates: true,
      );
      _ref.invalidate(difficultyStatsProvider);
    } catch (_) {
      // statistika nesmí rozbít hru
    }
  }
}

final resultReporterProvider = Provider<ResultReporter>((ref) => ResultReporter(ref));
