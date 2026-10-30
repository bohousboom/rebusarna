import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/difficulty.dart';
import '../../data/likes.dart';
import '../../data/providers.dart';
import '../../data/supabase_client.dart';
import '../../domain/adult_filter.dart';
import '../../domain/difficulty.dart';
import '../../domain/feed_plan.dart';
import '../../domain/hints.dart';
import '../../domain/models/puzzle.dart';
import '../../domain/text_logic.dart';
import '../shared/difficulty_dialog.dart';
import '../shared/help_dialog.dart';
import '../shared/puzzle_card.dart';
import '../shared/streak_flame.dart';
import 'puzzle_actions.dart';

/// Pořadí feedu: nevyřešené první (podle nastavené obtížnosti), potom vyřešené.
/// Statistiky a postup se čtou jen jednou, aby se feed neposouval během hraní.
final feedProvider = FutureProvider<List<Puzzle>>((ref) async {
  final all = visiblePuzzles(
    await ref.watch(puzzlesProvider.future),
    showAdult: ref.watch(showAdultProvider),
  );
  final setting = ref.watch(difficultySettingProvider);
  final stats = await ref.read(difficultyStatsProvider.future);
  final solved = ref.read(progressProvider).solved;
  return orderFeed(
    all: all,
    solved: solved,
    levelOf: (p) {
      final s = stats[p.id];
      return s == null
          ? p.difficulty
          : computeDifficulty(authorDifficulty: p.difficulty, n: s.n, avgScore: s.avgScore);
    },
    mix: setting.mixFor(solvedCount: solved.length),
  );
});

final _compactIcon = IconButton.styleFrom(
  padding: EdgeInsets.zero,
  minimumSize: const Size(36, 32),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
);

class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() => _pages.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

  @override
  Widget build(BuildContext context) {
    // Nové pořadí po změně obtížnosti: začít znovu od první karty.
    ref.listen(difficultySettingProvider, (_, _) {
      setState(() => _index = 0);
      if (_pages.hasClients) _pages.jumpToPage(0);
    });
    final feed = ref.watch(feedProvider);
    final solved = ref.watch(progressProvider.select((p) => p.solved));
    final list = feed.value;
    final current = list != null && _index < list.length ? list[_index] : null;
    final perms = PuzzlePermissions.of(ref, current);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  feed.maybeWhen(
                    data: (l) => 'Rébus ${min(_index + 1, l.length)} / ${l.length}',
                    orElse: () => '',
                  ),
                  maxLines: 2,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const StreakFlame(),
              Flexible(
                child: Chip(
                key: const Key('solved-count'),
                avatar: const Icon(Icons.check_circle, color: Colors.green),
                label: Text(feed.maybeWhen(
                  data: (l) =>
                      'Uhodnuto ${l.where((p) => solved.contains(p.id)).length} / ${l.length}',
                  orElse: () => 'Uhodnuto',
                )),
              ),
              ),
              const SizedBox(width: 4),
              if (perms.canReport)
                IconButton(
                  key: const Key('report-button'),
                  tooltip: 'Nahlásit',
                  style: _compactIcon,
                  onPressed: () => reportPuzzle(context, ref, current!),
                  icon: const Icon(Icons.flag_outlined),
                ),
              if (perms.canEdit)
                IconButton(
                  key: const Key('edit-button'),
                  tooltip: 'Upravit',
                  style: _compactIcon,
                  onPressed: () => context.push('/puzzle/${current!.id}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (perms.canDelete)
                IconButton(
                  key: const Key('delete-button'),
                  tooltip: 'Smazat',
                  style: _compactIcon,
                  onPressed: () => confirmDeletePuzzle(context, ref, current!),
                  icon: const Icon(Icons.delete_outline),
                ),
              IconButton(
                key: const Key('difficulty-button'),
                tooltip: 'Obtížnost',
                style: _compactIcon,
                onPressed: () => showDifficultyDialog(context),
                icon: const Icon(Icons.tune),
              ),
              IconButton(
                key: const Key('help-button'),
                tooltip: 'Nápověda',
                style: _compactIcon,
                onPressed: () => showHelpDialog(context),
                icon: const Icon(Icons.help_outline),
              ),
            ],
          ),
        ),
        if (feed.hasValue && ref.read(puzzleRepositoryProvider).loadFailed)
          Container(
            key: const Key('offline-banner'),
            width: double.infinity,
            color: Colors.amber.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: const Text(
              'Nepodařilo se spojit se serverem, zobrazuji jen základní rébusy.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        Expanded(
          child: feed.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Nepodařilo se načíst rébusy.\n$e')),
            data: (puzzles) {
              if (puzzles.isEmpty) {
                return const Center(child: Text('Zatím tu nejsou žádné rébusy.'));
              }
              return PageView.builder(
                controller: _pages,
                itemCount: puzzles.length + 1,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => i == puzzles.length
                    ? const _EndPage()
                    : PuzzlePage(
                        key: ValueKey(puzzles[i].id),
                        puzzle: puzzles[i],
                        onNext: _next,
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EndPage extends StatelessWidget {
  const _EndPage();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'To je zatím vše. Zkus změnit obtížnost (ikona vpravo nahoře) '
            'nebo vytvoř vlastní rébus v záložce Tvořit!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
}

enum _Status { playing, solved, revealed }

class PuzzlePage extends ConsumerStatefulWidget {
  const PuzzlePage({
    super.key,
    required this.puzzle,
    required this.onNext,
    this.nextLabel = 'Další',
    this.showSkip = true,
  });

  final Puzzle puzzle;
  final VoidCallback onNext;
  final String nextLabel;
  final bool showSkip;

  @override
  ConsumerState<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends ConsumerState<PuzzlePage>
    with AutomaticKeepAliveClientMixin {
  final _tip = TextEditingController();
  int _hintLevel = 0;
  int _wrongCount = 0;
  bool _wrong = false;
  late _Status _status =
      ref.read(progressProvider).solved.contains(widget.puzzle.id)
          ? _Status.solved
          : _Status.playing;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _tip.dispose();
    super.dispose();
  }

  void _submit() {
    if (_status != _Status.playing || _tip.text.trim().isEmpty) return;
    if (isCorrect(_tip.text, widget.puzzle.solution)) {
      setState(() {
        _status = _Status.solved;
        _wrong = false;
      });
      ref.read(progressProvider.notifier).markSolved(widget.puzzle.id);
      _report(revealed: false);
    } else {
      _wrongCount++;
      setState(() => _wrong = true);
    }
  }

  void _reveal() {
    setState(() {
      _status = _Status.revealed;
      _wrong = false;
    });
    _report(revealed: true);
  }

  /// Výsledek prvního pokusu do statistik obtížnosti (jen přihlášení hráči).
  void _report({required bool revealed}) {
    ref.read(resultReporterProvider).report(
          puzzleId: widget.puzzle.id,
          wrong: _wrongCount,
          hints: _hintLevel,
          revealed: revealed,
        );
  }

  void _resetThis() {
    ref.read(progressProvider.notifier).resetOne(widget.puzzle.id);
    setState(() {
      _status = _Status.playing;
      _hintLevel = 0;
      _wrongCount = 0;
      _wrong = false;
      _tip.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = widget.puzzle;
    final fav = ref.watch(progressProvider.select((s) => s.favorites.contains(p.id)));
    final cardHeight = (MediaQuery.sizeOf(context).height * 0.48).clamp(220.0, 520.0);
    final playing = _status == _Status.playing;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              height: cardHeight,
              width: cardHeight * 2 / 3 + 12,
              child: PuzzleCard(
                image: p.image,
                plusMinus: p.plusMinus,
                wordTypes: p.wordTypes,
                adult: p.adult,
                difficulty: ref.watch(effectiveDifficultyProvider((p.id, p.difficulty))),
                favorite: fav,
                onFavorite: () =>
                    ref.read(progressProvider.notifier).toggleFavorite(p.id),
                highlight: _status == _Status.solved,
                onExpand: () => showPuzzleFullscreen(context, p.image),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_hintLevel > 0 && playing)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                hintMask(p.solution, _hintLevel),
                key: const Key('hint-text'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          if (playing) ..._playingControls(p) else _resultPanel(p),
          TextButton.icon(
            key: const Key('share-button'),
            onPressed: () => sharePuzzle(context, p),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Sdílet odkaz na tento rébus'),
          ),
        ],
      ),
    );
  }

  List<Widget> _playingControls(Puzzle p) {
    return [
      TextField(
        key: const Key('tip-field'),
        controller: _tip,
        textInputAction: TextInputAction.done,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          labelText: 'Tvůj tip',
          errorText: _wrong ? 'Zkus to znovu' : null,
        ),
        onChanged: (_) {
          if (_wrong) setState(() => _wrong = false);
        },
        onSubmitted: (_) => _submit(),
      ),
      const SizedBox(height: 12),
      FilledButton(
        key: const Key('submit-button'),
        onPressed: _submit,
        child: const Text('Zkusit'),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('hint-button'),
              onPressed: _hintLevel >= 2 ? null : () => setState(() => _hintLevel++),
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(_hintLevel == 0
                  ? 'Nápověda'
                  : _hintLevel == 1
                      ? 'První písmeno'
                      : 'Hotovo'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              key: const Key('reveal-button'),
              onPressed: _reveal,
              child: const Text('Ukázat řešení'),
            ),
          ),
        ],
      ),
      if (widget.showSkip)
        TextButton.icon(
          key: const Key('skip-button'),
          onPressed: widget.onNext,
          icon: const Icon(Icons.casino_outlined),
          label: const Text('Jiná karta'),
        ),
    ];
  }

  Widget _resultPanel(Puzzle p) {
    final solved = _status == _Status.solved;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TweenAnimationBuilder<double>(
          key: Key(solved ? 'success' : 'revealed'),
          tween: Tween(begin: 0.3, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: solved ? Colors.green.shade600 : scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(solved ? Icons.celebration : Icons.visibility,
                    size: 40, color: solved ? Colors.white : scheme.onSecondaryContainer),
                const SizedBox(height: 4),
                Text(
                  solved ? 'Správně!' : 'Řešení',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: solved ? Colors.white : scheme.onSecondaryContainer,
                  ),
                ),
                Consumer(builder: (context, ref, _) {
                  final days = ref.watch(progressProvider).activeStreak(DateTime.now());
                  if (!solved || days == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '🔥 $days ${streakDayWord(days)} v řadě',
                      key: const Key('streak-message'),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  );
                }),
                Text(
                  p.solution,
                  key: const Key('solution-text'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: solved ? Colors.white : scheme.onSecondaryContainer,
                  ),
                ),
                if (p.meaning != null && p.meaning!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      p.meaning!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: solved ? Colors.white : scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                if (p.explanation != null && p.explanation!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Vysvětlení: ${p.explanation!}',
                      key: const Key('explanation-text'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: solved ? Colors.white : scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        _LikeRow(puzzle: p),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('next-button'),
          onPressed: widget.onNext,
          child: Text(widget.nextLabel),
        ),
        if (solved)
          TextButton(
            key: const Key('reset-one-button'),
            onPressed: _resetThis,
            child: const Text('Resetovat tento rébus'),
          ),
      ],
    );
  }
}


/// Po vyřešení: hráč může rébus ohodnotit ("líbí se mi"); autor vidí počet.
class _LikeRow extends ConsumerWidget {
  const _LikeRow({required this.puzzle});

  final Puzzle puzzle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider).value?.id;
    final isOwner = userId != null && puzzle.ownerId == userId;
    // Hodnotit jde jen rébus uložený v databázi (má autora), cizí a přihlášeným.
    final canLike = userId != null && puzzle.ownerId != null && !isOwner;
    final count = puzzle.ratingCount;
    if (!canLike) {
      if (count == 0) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('♥ $count',
            key: const Key('like-count'), textAlign: TextAlign.center),
      );
    }
    final liked = ref.watch(likesProvider).value?.contains(puzzle.id) ?? false;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        key: const Key('like-button'),
        onPressed: () async {
          try {
            await ref.read(likesProvider.notifier).toggle(puzzle.id);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Hodnocení se nepovedlo: $e')));
            }
          }
        },
        icon: Icon(liked ? Icons.favorite : Icons.favorite_border,
            color: liked ? Colors.red : null),
        label: Text(liked ? 'Líbilo se mi' : 'Líbí se mi'
            '${count > 0 ? '  ($count)' : ''}'),
      ),
    );
  }
}
