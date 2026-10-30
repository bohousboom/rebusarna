import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/streak.dart' as streak_logic;
import 'providers.dart';
import 'remote_progress.dart';
import 'supabase_client.dart';

const _kSolved = 'progress_solved';
const _kFavorites = 'progress_favorites';
const _kStreak = 'progress_streak';
const _kStreakDay = 'progress_streak_day';

/// Stav hráče: vyřešené a oblíbené rébusy a denní série (dny v řadě s aspoň jedním
/// uhodnutým rébusem); [lastDay] je poslední den (`yyyy-MM-dd`), kdy hráč uhodl.
class PlayerProgress {
  const PlayerProgress({
    this.solved = const {},
    this.favorites = const {},
    this.streak = 0,
    this.lastDay,
  });

  final Set<String> solved;
  final Set<String> favorites;
  final int streak;
  final String? lastDay;

  /// Série k zobrazení (0, když se už přerušila).
  int activeStreak(DateTime now) =>
      streak_logic.activeStreak(streak: streak, lastDay: lastDay, now: now);

  bool solvedToday(DateTime now) =>
      streak_logic.solvedToday(lastDay: lastDay, now: now);

  PlayerProgress copyWith({
    Set<String>? solved,
    Set<String>? favorites,
    int? streak,
    String? lastDay,
  }) =>
      PlayerProgress(
        solved: solved ?? this.solved,
        favorites: favorites ?? this.favorites,
        streak: streak ?? this.streak,
        lastDay: lastDay ?? this.lastDay,
      );
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
      lastDay: _prefs.getString(_kStreakDay),
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
      // Série platí z toho zařízení, kde se hrálo naposledy (při stejném dni vyšší).
      final remoteWins = remote.lastDay != null &&
          (state.lastDay == null ||
              remote.lastDay!.compareTo(state.lastDay!) > 0 ||
              (remote.lastDay == state.lastDay && remote.streak > state.streak));
      state = PlayerProgress(
        solved: {...state.solved, ...remote.solved},
        favorites: {...state.favorites, ...remote.favorites},
        streak: remoteWins ? remote.streak : state.streak,
        lastDay: remoteWins ? remote.lastDay : state.lastDay,
      );
      await _save();
      await r.pushAll(state);
    } catch (_) {}
  }

  Future<void> _save() async {
    await _prefs.setStringList(_kSolved, state.solved.toList());
    await _prefs.setStringList(_kFavorites, state.favorites.toList());
    await _prefs.setInt(_kStreak, state.streak);
    final day = state.lastDay;
    if (day == null) {
      await _prefs.remove(_kStreakDay);
    } else {
      await _prefs.setString(_kStreakDay, day);
    }
  }

  /// Vyřešeno: přidá do vyřešených a prodlouží denní sérii (jen při prvním vyřešení rébusu).
  Future<void> markSolved(String id) async {
    if (state.solved.contains(id)) return;
    final now = DateTime.now();
    state = state.copyWith(
      solved: {...state.solved, id},
      streak: streak_logic.streakAfterSolve(
          streak: state.streak, lastDay: state.lastDay, now: now),
      lastDay: streak_logic.dayKey(now),
    );
    await _save();
    final streak = state.streak;
    final day = state.lastDay;
    await _sync((r) async {
      await r.addSolved(id);
      await r.setStreak(streak, day);
    });
  }

  /// Smaže uhodnutý stav jednoho rébusu (oblíbené i série zůstávají).
  Future<void> resetOne(String id) async {
    if (!state.solved.contains(id)) return;
    state = state.copyWith(solved: {...state.solved}..remove(id));
    await _save();
    await _sync((r) => r.removeSolved(id));
  }

  /// Smaže všechny uhodnuté rébusy a sérii (oblíbené zůstává).
  Future<void> resetAll() async {
    state = PlayerProgress(favorites: state.favorites);
    await _save();
    await _sync((r) async {
      await r.clearSolved();
      await r.setStreak(0, null);
    });
  }

  Future<void> toggleFavorite(String id) async {
    final favs = {...state.favorites};
    final nowFavorite = !favs.remove(id);
    if (nowFavorite) favs.add(id);
    state = state.copyWith(favorites: favs);
    await _save();
    await _sync((r) => r.setFavorite(id, nowFavorite));
  }
}
