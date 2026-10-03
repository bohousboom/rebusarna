import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/models/puzzle.dart';
import '../../data/supabase_client.dart';
import '../shared/account_bar.dart';
import 'import_builtin_card.dart';
import '../shared/puzzle_thumb.dart';

/// Moje: vytvořené, vyřešené a oblíbené rébusy.
class MineScreen extends ConsumerWidget {
  const MineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzles = ref.watch(puzzlesProvider);
    final progress = ref.watch(progressProvider);
    final userId = ref.watch(currentUserProvider).value?.id;
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const AccountBar(),
          const ImportBuiltInCard(),
          const TabBar(tabs: [
            Tab(text: 'Vytvořené'),
            Tab(text: 'Vyřešené'),
            Tab(text: 'Oblíbené'),
          ]),
          Expanded(
            child: puzzles.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Nepodařilo se načíst.\n$e')),
              data: (all) => TabBarView(children: [
                _Grid(
                  puzzles: all
                      .where((p) =>
                          p.id.startsWith('user-') ||
                          (userId != null && p.ownerId == userId))
                      .toList(),
                  solved: progress.solved,
                  empty: 'Zatím jsi nic nevytvořil. Zkus záložku Tvořit.',
                ),
                _Grid(
                  puzzles: all.where((p) => progress.solved.contains(p.id)).toList(),
                  solved: progress.solved,
                  empty: 'Zatím jsi nic nevyřešil.',
                ),
                _Grid(
                  puzzles: all.where((p) => progress.favorites.contains(p.id)).toList(),
                  solved: progress.solved,
                  empty: 'Žádné oblíbené. Klepni na srdíčko na kartě.',
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.puzzles, required this.solved, required this.empty});

  final List<Puzzle> puzzles;
  final Set<String> solved;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (puzzles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(empty, textAlign: TextAlign.center),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 170,
        childAspectRatio: 2 / 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: puzzles.length,
      itemBuilder: (context, i) =>
          PuzzleThumb(puzzle: puzzles[i], solved: solved.contains(puzzles[i].id)),
    );
  }
}
