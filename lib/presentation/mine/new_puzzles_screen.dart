import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/new_puzzles.dart';
import '../shared/puzzle_card.dart';

/// Karta v záložce Moje: nové cizí rébusy ke kontrole. Jen pro správce.
class NewPuzzlesCard extends ConsumerWidget {
  const NewPuzzlesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(newPuzzlesProvider);
    if (recent.isEmpty) return const SizedBox.shrink();
    final unreviewed = ref.watch(unreviewedCountProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        child: ListTile(
          key: const Key('new-puzzles-card'),
          leading: Badge(
            isLabelVisible: unreviewed > 0,
            label: Text('$unreviewed'),
            child: const Icon(Icons.fiber_new),
          ),
          title: const Text('Nové karty'),
          subtitle: Text(unreviewed > 0
              ? '$unreviewed ke kontrole (za 7 dní celkem ${recent.length})'
              : 'Vše zkontrolováno (za 7 dní ${recent.length})'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/new'),
        ),
      ),
    );
  }
}

/// Karty vytvořené ostatními za posledních 7 dní, nejnovější první.
class NewPuzzlesScreen extends ConsumerWidget {
  const NewPuzzlesScreen({super.key});

  String _age(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return 'před ${d.inMinutes.clamp(1, 59)} min';
    if (d.inHours < 24) return 'před ${d.inHours} h';
    return 'před ${d.inDays} d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(newPuzzlesProvider);
    final since = ref.watch(lastReviewedProvider);
    final unreviewed = ref.watch(unreviewedCountProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nové karty'),
        actions: [
          TextButton(
            key: const Key('mark-reviewed'),
            onPressed: unreviewed == 0
                ? null
                : () => ref.read(lastReviewedProvider.notifier).markAllReviewed(),
            child: const Text('Vše zkontrolováno'),
          ),
        ],
      ),
      body: SafeArea(
        child: list.isEmpty
            ? const Center(child: Text('Za posledních 7 dní nic nového.'))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, i) {
                  final p = list[i];
                  final isNew = since == null || p.createdAt.isAfter(since);
                  return ListTile(
                    key: Key('new-${p.id}'),
                    contentPadding: EdgeInsets.zero,
                    leading: SizedBox(
                      width: 48,
                      height: 72,
                      child: PuzzleImage(p.image, fit: BoxFit.cover, cacheWidth: 200),
                    ),
                    title: Text(p.solution),
                    subtitle: Text('${p.authorName} · ${_age(p.createdAt)}'
                        '${p.hidden ? ' · skryto' : ''}'),
                    trailing: isNew
                        ? const Icon(Icons.circle, size: 12, color: Colors.orange)
                        : null,
                    onTap: () => context.push('/puzzle/${p.id}'),
                  );
                },
              ),
      ),
    );
  }
}
