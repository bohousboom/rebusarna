import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/feed_plan.dart';
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

const _kDifficultyMode = 'difficulty_mode';
const _kDifficultyMix = 'difficulty_mix';

/// Jak se řadí karty podle obtížnosti (výchozí: postupně). Ukládá se v zařízení.
class DifficultySettingNotifier extends Notifier<DifficultySetting> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  DifficultySetting build() {
    final name = _prefs.getString(_kDifficultyMode);
    final mix = _prefs.getStringList(_kDifficultyMix)?.map(int.tryParse).toList();
    return DifficultySetting(
      mode: DifficultyMode.values.where((m) => m.name == name).firstOrNull ??
          DifficultyMode.gradual,
      custom: mix != null && mix.length == 3 && !mix.contains(null)
          ? DifficultyMix(mix[0]!, mix[1]!, mix[2]!)
          : DifficultyMix.defaultCustom,
    );
  }

  Future<void> set(DifficultySetting value) async {
    state = value;
    await _prefs.setString(_kDifficultyMode, value.mode.name);
    await _prefs.setStringList(_kDifficultyMix,
        [for (final c in value.custom.counts) c.toString()]);
  }
}

final difficultySettingProvider =
    NotifierProvider<DifficultySettingNotifier, DifficultySetting>(
        DifficultySettingNotifier.new);

const _kThemeMode = 'theme_mode';

/// Režim vzhledu: výchozí podle systému, uživatel může vynutit světlý/noční.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => switch (ref.read(sharedPreferencesProvider).getString(_kThemeMode)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_kThemeMode, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

final progressProvider =
    NotifierProvider<ProgressNotifier, PlayerProgress>(ProgressNotifier.new);
