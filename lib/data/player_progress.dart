import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers.dart';
import 'remote_progress.dart';
import 'supabase_client.dart';

const _kSolved = 'progress_solved';
const _kFavorites = 'progress_favorites';
const _kStreak = 'progress_streak';

/// Stav hráče: vyřešené a oblíbené rébusy a aktuální série.
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

/// Lokální stav (shared_preferences) + synchronizace se Supabase, když je hráč přihlášený.
class ProgressNotifier extends Notifier<PlayerProgress> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  PlayerProgress build() {
    // Po přihlášení sloučí postup z účtu s tím v zařízení.
    ref.listen(currentUserProvider, (prev, next) {
      final id = next.value?.id;
      if (id != null && id != prev?.value?.id) _pullAndMerge();
    });
    return PlayerProgress(
      solved: (_prefs.getStringList(_kSolved) ?? const []).toSet(),
      favorites: (_prefs.getStringList(_kFavorites) ?? const []).toSet(),
      streak: _prefs.getInt(_kStreak) ?? 0,
    );
  }

  RemoteProgress? get _remote {
    final client = ref.read(supabaseClientProvider);
    final user = ref.read(currentUserProvider).value;
    return (client != null && user != null) ? RemoteProgress(client) : null;
  }

  /// Chyba sítě nesmí rozbít hru; lokální stav zůstává platný.
  Future<void> _sync(Future<void> Function(RemoteProgress r) op) async {
    final r = _remote;
    if (r == null) return;
    try {
      await op(r);
    } catch (_) {}
  }

  Future<void> _pullAndMerge() async {
    final r = _remote;
    if (r == null) return;
    try {
      final remote = await r.fetch();
      state = PlayerProgress(
        solved: {...state.solved, ...remote.solved},
        favorites: {...state.favorites, ...remote.favorites},
        streak: state.streak > remote.streak ? state.streak : remote.streak,
      );
      await _save();
      await r.pushAll(state);
    } catch (_) {}
  }

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
    final streak = state.streak;
    await _sync((r) async {
      await r.addSolved(id);
      await r.setStreak(streak);
    });
  }

  /// Hráč se vzdal a ukázal řešení – série se přeruší.
  Future<void> resetStreak() async {
    if (state.streak == 0) return;
    state = PlayerProgress(
        solved: state.solved, favorites: state.favorites, streak: 0);
    await _save();
    await _sync((r) => r.setStreak(0));
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
    await _sync((r) => r.removeSolved(id));
  }

  /// Smaže všechny uhodnuté rébusy a sérii (oblíbené zůstává).
  Future<void> resetAll() async {
    state = PlayerProgress(favorites: state.favorites);
    await _save();
    await _sync((r) async {
      await r.clearSolved();
      await r.setStreak(0);
    });
  }

  Future<void> toggleFavorite(String id) async {
    final favs = {...state.favorites};
    final nowFavorite = !favs.remove(id);
    if (nowFavorite) favs.add(id);
    state = PlayerProgress(
        solved: state.solved, favorites: favs, streak: state.streak);
    await _save();
    await _sync((r) => r.setFavorite(id, nowFavorite));
  }
}
