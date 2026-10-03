import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/puzzle.dart';
import 'local_puzzle_repository.dart';
import 'player_progress.dart';
import 'puzzle_repository.dart';
import 'supabase_client.dart';
import 'supabase_puzzle_repository.dart';

const kSeedPuzzlesAsset = 'assets/seed_puzzles.json';

/// Přepisuje se v main() a v testech.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider není nastaven'),
);

/// Supabase, když je k dispozici; jinak jen lokální úložiště.
final puzzleRepositoryProvider = Provider<PuzzleRepository>((ref) {
  Future<String> loadSeed() => rootBundle.loadString(kSeedPuzzlesAsset);
  final client = ref.watch(supabaseClientProvider);
  if (client != null) return SupabasePuzzleRepository(client, loadSeed: loadSeed);
  return LocalPuzzleRepository(ref.watch(sharedPreferencesProvider), loadSeed: loadSeed);
});

final puzzlesProvider = FutureProvider<List<Puzzle>>(
  (ref) => ref.watch(puzzleRepositoryProvider).getAll(),
);

const _kShowAdult = 'show_adult';

/// Zobrazovat rébusy 18+ (výchozí: ne). Ukládá se v zařízení.
class ShowAdultNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(_kShowAdult) ?? false;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(_kShowAdult, value);
  }
}

final showAdultProvider = NotifierProvider<ShowAdultNotifier, bool>(ShowAdultNotifier.new);

final progressProvider =
    NotifierProvider<ProgressNotifier, PlayerProgress>(ProgressNotifier.new);
