import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import 'play_screen.dart';

/// Jeden rébus otevřený z Knihovny nebo ze záložky Moje.
class PuzzleDetailScreen extends ConsumerWidget {
  const PuzzleDetailScreen({super.key, required this.puzzleId});

  final String puzzleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzles = ref.watch(puzzlesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Rébus')),
      body: SafeArea(
        child: puzzles.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (all) {
            final p = all.where((x) => x.id == puzzleId).firstOrNull;
            if (p == null) return const Center(child: Text('Rébus nenalezen'));
            return PuzzlePage(
              key: ValueKey(p.id),
              puzzle: p,
              onNext: () => context.pop(),
              nextLabel: 'Zpět',
              showSkip: false,
            );
          },
        ),
      ),
    );
  }
}
