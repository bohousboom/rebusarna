import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../domain/adult_filter.dart';
import '../../domain/models/puzzle.dart';
import '../../domain/text_logic.dart';
import '../../data/supabase_client.dart';
import '../shared/account_bar.dart';
import '../shared/difficulty_dialog.dart';
import 'import_builtin_card.dart';
import 'new_puzzles_screen.dart';
import 'reports_screen.dart';
import '../shared/puzzle_thumb.dart';
import '../shared/streak_flame.dart';

/// Moje: vytvořené, vyřešené a oblíbené rébusy.
class MineScreen extends ConsumerWidget {
  const MineScreen({super.key});

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resetovat postup?'),
        content: const Text(
            'Všechny uhodnuté rébusy se znovu skryjí. Oblíbené zůstanou.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Zrušit')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Resetovat')),
        ],
      ),
    );
    if (ok == true) await ref.read(progressProvider.notifier).resetAll();
  }

  Future<void> _toggleAdult(BuildContext context, WidgetRef ref, bool value) async {
    if (value) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Zobrazit obsah 18+?'),
          content: const Text('Rébusy označené 18+ nejsou vhodné pro mladší 18 let. Je ti 18 a více?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ne')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ano, je mi 18+')),
          ],
        ),
      );
      if (ok != true) return;
    }
    await ref.read(showAdultProvider.notifier).set(value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAdult = ref.watch(showAdultProvider);
    final puzzles = ref.watch(puzzlesProvider);
    final progress = ref.watch(progressProvider);
    final userId = ref.watch(currentUserProvider).value?.id;
    final collapsed = ref.watch(mineCollapsedProvider);
    final days = progress.activeStreak(DateTime.now());
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const AccountBar(),
          InkWell(
            key: const Key('mine-collapse-toggle'),
            onTap: () => ref.read(mineCollapsedProvider.notifier).toggle(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      days > 0
                          ? 'Nastavení · série $days ${streakDayWord(days)}'
                          : 'Nastavení',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Icon(collapsed ? Icons.expand_more : Icons.expand_less),
                ],
              ),
            ),
          ),
          if (!collapsed)
            // Na malém displeji panel nesmí sebrat všechno místo kartám.
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.4),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const ImportBuiltInCard(),
                    const ReportsCard(),
                    const NewPuzzlesCard(),
                    if (userId != null)
                      Builder(builder: (context) {
                        final likes = (puzzles.value ?? const <Puzzle>[])
                            .where((p) => p.ownerId == userId)
                            .fold<int>(0, (a, p) => a + p.ratingCount);
                        if (likes == 0) return const SizedBox.shrink();
                        return ListTile(
                          key: const Key('my-likes-tile'),
                          dense: true,
                          leading: const Icon(Icons.favorite, color: Colors.red),
                          title: Text('Tvé rébusy se hráčům líbily: $likes×'),
                          subtitle: const Text('Klepni a uvidíš kdo a které'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/likes'),
                        );
                      }),
                    SwitchListTile(
                      key: const Key('dark-mode-switch'),
                      dense: true,
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Noční režim'),
                      value: Theme.of(context).brightness == Brightness.dark,
                      onChanged: (v) => ref
                          .read(themeModeProvider.notifier)
                          .set(v ? ThemeMode.dark : ThemeMode.light),
                    ),
                    ListTile(
                      key: const Key('difficulty-tile'),
                      dense: true,
                      leading: const Icon(Icons.tune),
                      title: const Text('Obtížnost'),
                      subtitle: Text(ref.watch(difficultySettingProvider).mode.label),
                      onTap: () => showDifficultyDialog(context),
                    ),
                    SwitchListTile(
                      key: const Key('show-adult-switch'),
                      dense: true,
                      title: const Text('Zobrazovat rébusy 18+'),
                      subtitle:
                          userId == null ? const Text('Dostupné po přihlášení') : null,
                      value: showAdult,
                      onChanged:
                          userId == null ? null : (v) => _toggleAdult(context, ref, v),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TextButton.icon(
                          key: const Key('reset-all-button'),
                          onPressed: progress.solved.isEmpty
                              ? null
                              : () => _confirmReset(context, ref),
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Resetovat postup'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                _SolvedTab(
                  puzzles: visiblePuzzles(all, showAdult: showAdult)
                      .where((p) => progress.solved.contains(p.id))
                      .toList(),
                  solved: progress.solved,
                ),
                _Grid(
                  puzzles: visiblePuzzles(all, showAdult: showAdult)
                      .where((p) => progress.favorites.contains(p.id))
                      .toList(),
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

/// Vyřešené rébusy s hledáním podle řešení.
class _SolvedTab extends StatefulWidget {
  const _SolvedTab({required this.puzzles, required this.solved});

  final List<Puzzle> puzzles;
  final Set<String> solved;

  @override
  State<_SolvedTab> createState() => _SolvedTabState();
}

class _SolvedTabState extends State<_SolvedTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final found = searchBySolution(widget.puzzles, _query);
    return Column(
      children: [
        if (widget.puzzles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              key: const Key('solved-search-field'),
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Hledat podle řešení',
                isDense: true,
              ),
            ),
          ),
        Expanded(
          child: _Grid(
            puzzles: found,
            solved: widget.solved,
            empty: widget.puzzles.isEmpty
                ? 'Zatím jsi nic nevyřešil.'
                : 'Nic nenalezeno.',
          ),
        ),
      ],
    );
  }
}
