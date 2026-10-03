import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/moderation.dart';
import '../../data/providers.dart';
import '../shared/puzzle_card.dart';

/// Karta v záložce Moje: kolik rébusů čeká na posouzení. Jen pro správce.
class ReportsCard extends ConsumerWidget {
  const ReportsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(reportsProvider).value ?? const [];
    if (groups.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        child: ListTile(
          key: const Key('reports-card'),
          leading: const Icon(Icons.flag),
          title: Text('Nahlášené rébusy (${groups.length})'),
          subtitle: const Text('Čekají na tvoje posouzení'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/reports'),
        ),
      ),
    );
  }
}

/// Přehled nahlášených rébusů pro správce.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(reportsProvider);
    final puzzles = ref.watch(puzzlesProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Nahlášené rébusy')),
      body: SafeArea(
        child: groups.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (list) {
            if (list.isEmpty) {
              return const Center(child: Text('Žádná nahlášení.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, i) {
                final g = list[i];
                final puzzle = puzzles.where((p) => p.id == g.puzzleId).firstOrNull;
                return ListTile(
                  key: Key('report-${g.puzzleId}'),
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(
                    width: 48,
                    height: 72,
                    child: puzzle == null
                        ? const Icon(Icons.help_outline)
                        : PuzzleImage(puzzle.image, fit: BoxFit.cover, cacheWidth: 200),
                  ),
                  title: Text(puzzle?.solution ?? '(rébus už neexistuje)'),
                  subtitle: Text([
                    for (final e in g.counts.entries) '${e.key.label}: ${e.value}×',
                    ...g.notes.map((n) => '„$n"'),
                  ].join('\n')),
                  isThreeLine: g.notes.isNotEmpty || g.counts.length > 1,
                  onTap: puzzle == null ? null : () => context.push('/puzzle/${g.puzzleId}'),
                  trailing: TextButton(
                    key: Key('dismiss-${g.puzzleId}'),
                    onPressed: () => ref.read(moderationProvider).dismiss(g.puzzleId),
                    child: const Text('Zamítnout'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
