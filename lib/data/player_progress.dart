import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers.dart';

const _kSolved = 'progress_solved';
const _kFavorites = 'progress_favorites';
const _kStreak = 'progress_streak';

/// Stav hráče: vyřešené a oblíbené rébusy a aktuální série (jen lokálně).
class PlayerProgress {
  const PlayerProgress({
    this.solved = const {},
    this.favorites = const {},
    this.streak = 0,
  });

  final Set<String> solved;
  final Set<String> favorites;
  final int streak;
}

class ProgressNotifier extends Notifier<PlayerProgress> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  PlayerProgress build() => PlayerProgress(
        solved: (_prefs.getStringList(_kSolved) ?? const []).toSet(),
        favorites: (_prefs.getStringList(_kFavorites) ?? const []).toSet(),
        streak: _prefs.getInt(_kStreak) ?? 0,
      );

  Future<void> _save() async {
    await _prefs.setStringList(_kSolved, state.solved.toList());
    await _prefs.setStringList(_kFavorites, state.favorites.toList());
    await _prefs.setInt(_kStreak, state.streak);
  }

  /// Vyřešeno: přidá do vyřešených a zvýší sérii (jen při prvním vyřešení).
  Future<void> markSolved(String id) async {
    if (state.solved.contains(id)) return;
    state = PlayerProgress(
      solved: {...state.solved, id},
      favorites: state.favorites,
      streak: state.streak + 1,
    );
    await _save();
  }

  /// Hráč se vzdal a ukázal řešení – série se přeruší.
  Future<void> resetStreak() async {
    if (state.streak == 0) return;
    state = PlayerProgress(
        solved: state.solved, favorites: state.favorites, streak: 0);
    await _save();
  }

  /// Smaže uhodnutý stav jednoho rébusu (oblíbené zůstává).
  Future<void> resetOne(String id) async {
    if (!state.solved.contains(id)) return;
    state = PlayerProgress(
      solved: {...state.solved}..remove(id),
      favorites: state.favorites,
      streak: state.streak,
    );
    await _save();
  }

  /// Smaže všechny uhodnuté rébusy a sérii (oblíbené zůstává).
  Future<void> resetAll() async {
    state = PlayerProgress(favorites: state.favorites);
    await _save();
  }

  Future<void> toggleFavorite(String id) async {
    final favs = {...state.favorites};
    if (!favs.remove(id)) favs.add(id);
    state = PlayerProgress(
        solved: state.solved, favorites: favs, streak: state.streak);
    await _save();
  }
}
