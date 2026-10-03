import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/puzzle.dart';
import 'local_puzzle_repository.dart';
import 'player_progress.dart';
import 'puzzle_repository.dart';

const kSeedPuzzlesAsset = 'assets/seed_puzzles.json';

/// Přepisuje se v main() a v testech.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider není nastaven'),
);

final puzzleRepositoryProvider = Provider<PuzzleRepository>((ref) {
  return LocalPuzzleRepository(
    ref.watch(sharedPreferencesProvider),
    loadSeed: () => rootBundle.loadString(kSeedPuzzlesAsset),
  );
});

final puzzlesProvider = FutureProvider<List<Puzzle>>(
  (ref) => ref.watch(puzzleRepositoryProvider).getAll(),
);

final progressProvider =
    NotifierProvider<ProgressNotifier, PlayerProgress>(ProgressNotifier.new);
