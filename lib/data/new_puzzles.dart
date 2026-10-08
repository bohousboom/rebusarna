import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/puzzle.dart';
import '../domain/new_puzzles.dart';
import 'providers.dart';
import 'supabase_client.dart';

const _kLastReviewed = 'new_puzzles_reviewed_at';

/// Kdy správce naposledy označil nové karty za zkontrolované (ukládá se v zařízení).
class LastReviewedNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    final ms = ref.read(sharedPreferencesProvider).getInt(_kLastReviewed);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> markAllReviewed() async {
    final now = DateTime.now();
    state = now;
    await ref.read(sharedPreferencesProvider).setInt(_kLastReviewed, now.millisecondsSinceEpoch);
  }
}

final lastReviewedProvider =
    NotifierProvider<LastReviewedNotifier, DateTime?>(LastReviewedNotifier.new);

/// Nové cizí karty z posledních 7 dní pro správce (ostatním prázdné).
final newPuzzlesProvider = Provider<List<Puzzle>>((ref) {
  final isAdmin = ref.watch(isAdminProvider).value ?? false;
  if (!isAdmin) return const [];
  final all = ref.watch(puzzlesProvider).value ?? const <Puzzle>[];
  return recentUserPuzzles(
    all,
    now: DateTime.now(),
    excludeOwnerId: ref.watch(currentUserProvider).value?.id,
  );
});

/// Kolik z nových karet správce ještě neoznačil za zkontrolované.
final unreviewedCountProvider = Provider<int>((ref) {
  final since = ref.watch(lastReviewedProvider);
  final list = ref.watch(newPuzzlesProvider);
  return since == null ? list.length : list.where((p) => p.createdAt.isAfter(since)).length;
});
