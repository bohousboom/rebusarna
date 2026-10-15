import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'supabase_client.dart';

/// Rébusy, kterým přihlášený hráč dal "líbí se mi".
class LikesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final client = ref.watch(supabaseClientProvider);
    final user = ref.watch(currentUserProvider).value;
    if (client == null || user == null) return {};
    try {
      final rows = await client.from('puzzle_likes').select('puzzle_id');
      return {for (final r in rows) r['puzzle_id'] as String};
    } catch (_) {
      return {};
    }
  }

  /// Přepne hlas; při chybě vrátí původní stav a chybu předá dál.
  Future<void> toggle(String puzzleId) async {
    final client = ref.read(supabaseClientProvider);
    final user = ref.read(currentUserProvider).value;
    if (client == null || user == null) {
      throw StateError('Pro hodnocení se musíš přihlásit.');
    }
    final before = state.value ?? {};
    final liked = before.contains(puzzleId);
    state = AsyncData(liked ? ({...before}..remove(puzzleId)) : {...before, puzzleId});
    try {
      if (liked) {
        await client
            .from('puzzle_likes')
            .delete()
            .eq('user_id', user.id)
            .eq('puzzle_id', puzzleId);
      } else {
        await client
            .from('puzzle_likes')
            .upsert({'puzzle_id': puzzleId, 'user_id': user.id}, ignoreDuplicates: true);
      }
      ref.invalidate(puzzlesProvider); // obnoví počty
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }
}

final likesProvider =
    AsyncNotifierProvider<LikesNotifier, Set<String>>(LikesNotifier.new);
