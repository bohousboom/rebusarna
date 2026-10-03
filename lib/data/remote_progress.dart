import 'package:supabase_flutter/supabase_flutter.dart';

import 'player_progress.dart';

/// Postup přihlášeného hráče uložený v Supabase (solved, favorites, profiles).
class RemoteProgress {
  RemoteProgress(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  Future<PlayerProgress> fetch() async {
    final solved = await _client.from('solved').select('puzzle_id');
    final favs = await _client.from('favorites').select('puzzle_id');
    final profile = await _client.from('profiles').select('streak').maybeSingle();
    return PlayerProgress(
      solved: {for (final r in solved) r['puzzle_id'] as String},
      favorites: {for (final r in favs) r['puzzle_id'] as String},
      streak: (profile?['streak'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> pushAll(PlayerProgress p) async {
    if (p.solved.isNotEmpty) {
      await _client.from('solved').upsert([
        for (final id in p.solved) {'user_id': _uid, 'puzzle_id': id},
      ]);
    }
    if (p.favorites.isNotEmpty) {
      await _client.from('favorites').upsert([
        for (final id in p.favorites) {'user_id': _uid, 'puzzle_id': id},
      ]);
    }
    await setStreak(p.streak);
  }

  Future<void> addSolved(String id) =>
      _client.from('solved').upsert({'user_id': _uid, 'puzzle_id': id});

  Future<void> removeSolved(String id) =>
      _client.from('solved').delete().eq('user_id', _uid).eq('puzzle_id', id);

  Future<void> clearSolved() => _client.from('solved').delete().eq('user_id', _uid);

  Future<void> setFavorite(String id, bool favorite) => favorite
      ? _client.from('favorites').upsert({'user_id': _uid, 'puzzle_id': id})
      : _client.from('favorites').delete().eq('user_id', _uid).eq('puzzle_id', id);

  Future<void> setStreak(int streak) =>
      _client.from('profiles').upsert({'user_id': _uid, 'streak': streak});
}
