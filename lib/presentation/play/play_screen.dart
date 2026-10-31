import 'dart:async';

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

class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

enum _Menu { report, download, edit, delete, difficulty, help }

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

  void _onMenu(_Menu item, Puzzle? current) {
    switch (item) {
      case _Menu.report:
        reportPuzzle(context, ref, current!);
      case _Menu.download:
        downloadImage(context, current!);
      case _Menu.edit:
        context.push('/puzzle/${current!.id}/edit');
      case _Menu.delete:
        confirmDeletePuzzle(context, ref, current!);
      case _Menu.difficulty:
        showDifficultyDialog(context);
      case _Menu.help:
        showHelpDialog(context);
    }
  }

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
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
          child: Row(
            children: [
              const StreakFlame(),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Uhodnuto / všech rébusů',
                triggerMode: TooltipTriggerMode.tap,
                child: Chip(
                  key: const Key('solved-count'),
                  avatar: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text(feed.maybeWhen(
                    data: (l) =>
                        '${l.where((p) => solved.contains(p.id)).length} / ${l.length}',
                    orElse: () => '',
                  )),
                ),
              ),
              const Spacer(),
              PopupMenuButton<_Menu>(
                key: const Key('more-menu'),
                tooltip: 'Další akce',
                onSelected: (m) => _onMenu(m, current),
                itemBuilder: (_) => [
                  if (perms.canReport)
                    const PopupMenuItem(
                        key: Key('report-button'),
                        value: _Menu.report,
                        child: Text('Nahlásit')),
                  if (perms.canDownload)
                    const PopupMenuItem(
                        key: Key('download-button'),
                        value: _Menu.download,
                        child: Text('Stáhnout obrázek')),
                  if (perms.canEdit)
                    const PopupMenuItem(
                        key: Key('edit-button'), value: _Menu.edit, child: Text('Upravit')),
                  if (perms.canDelete)
                    const PopupMenuItem(
                        key: Key('delete-button'), value: _Menu.delete, child: Text('Smazat')),
                  const PopupMenuItem(
                      key: Key('difficulty-button'),
                      value: _Menu.difficulty,
                      child: Text('Obtížnost')),
                  const PopupMenuItem(
                      key: Key('help-button'), value: _Menu.help, child: Text('Nápověda')),
                ],
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
                        autoAdvance: i == _index,
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
            'To je zatím vše. Zkus změnit obtížnost (nabídka ⋮ vpravo nahoře) '
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
    this.autoAdvance = false,
  });

  final Puzzle puzzle;
  final VoidCallback onNext;
  final String nextLabel;

  /// Po uhodnutí se po chvíli samo přejde na další kartu (klepnutí kamkoli to zruší).
  /// Má být true jen pro právě zobrazenou kartu.
  final bool autoAdvance;

  @override
  ConsumerState<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends ConsumerState<PuzzlePage>
    with AutomaticKeepAliveClientMixin {
  final _tip = TextEditingController();
  final _controlsKey = GlobalKey();
  int _hintLevel = 0;
  int _wrongCount = 0;
  bool _wrong = false;
  bool _showExplanation = false;
  Timer? _autoTimer;
  Duration? _autoDuration;
  late _Status _status =
      ref.read(progressProvider).solved.contains(widget.puzzle.id)
          ? _Status.solved
          : _Status.playing;

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(PuzzlePage old) {
    super.didUpdateWidget(old);
    if (!widget.autoAdvance) _cancelAuto();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _tip.dispose();
    super.dispose();
  }

  /// Čas na přečtení: delší, když rébus má vysvětlení nebo význam.
  void _startAuto() {
    if (!widget.autoAdvance) return;
    final p = widget.puzzle;
    final hasText =
        (p.explanation?.isNotEmpty ?? false) || (p.meaning?.isNotEmpty ?? false);
    final d = Duration(seconds: hasText ? 12 : 4);
    _autoTimer?.cancel();
    _autoTimer = Timer(d, () {
      _autoTimer = null;
      if (mounted && widget.autoAdvance) widget.onNext();
    });
    setState(() => _autoDuration = d);
  }

  void _cancelAuto() {
    _autoTimer?.cancel();
    _autoTimer = null;
    if (_autoDuration != null && mounted) setState(() => _autoDuration = null);
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
      _startAuto();
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
    _cancelAuto();
    ref.read(progressProvider.notifier).resetOne(widget.puzzle.id);
    setState(() {
      _status = _Status.playing;
      _hintLevel = 0;
      _wrongCount = 0;
      _wrong = false;
      _showExplanation = false;
      _tip.clear();
    });
  }

  Widget _card(double height) {
    final p = widget.puzzle;
    final fav = ref.watch(progressProvider.select((s) => s.favorites.contains(p.id)));
    return SizedBox(
      height: height,
      width: height * 2 / 3 + 12,
      child: PuzzleCard(
        image: p.image,
        plusMinus: p.plusMinus,
        wordTypes: p.wordTypes,
        adult: p.adult,
        difficulty: ref.watch(effectiveDifficultyProvider((p.id, p.difficulty))),
        favorite: fav,
        onFavorite: () => ref.read(progressProvider.notifier).toggleFavorite(p.id),
        onShare: () => sharePuzzle(context, p),
        highlight: _status == _Status.solved,
        onExpand: () => showPuzzleFullscreen(context, p.image),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = widget.puzzle;
    final playing = _status == _Status.playing;

    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hintLevel > 0 && playing && (p.language?.isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Hledej v jazyce: ${p.language}',
              key: const Key('hint-language'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        if (_hintLevel > 0 && playing)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
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
      ],
    );

    // Při zobrazení klávesnice se přepne rozvržení níže; GlobalKey zachová
    // pole i jeho fokus, jinak by se klávesnice hned zavřela.
    final controlsKeyed = KeyedSubtree(key: _controlsKey, child: controls);

    // Klepnutí kamkoli zruší automatický přechod na další kartu.
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _cancelAuto(),
      child: LayoutBuilder(builder: (context, c) {
        // Nízké okno (např. s klávesnicí): malá karta a celé se dá posunout.
        if (c.maxHeight < 460) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: _card(200)),
                const SizedBox(height: 12),
                controlsKeyed,
              ],
            ),
          );
        }
        // Jinak karta vyplní zbývající místo a ovládání je pod ní bez posouvání.
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, cc) {
                    final byWidth = (cc.maxWidth - 12) * 1.5;
                    return Center(
                      child: _card(cc.maxHeight < byWidth ? cc.maxHeight : byWidth),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: c.maxHeight * 0.6),
                child: SingleChildScrollView(child: controlsKeyed),
              ),
            ],
          ),
        );
      }),
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
          isDense: true,
          errorText: _wrong ? 'Zkus to znovu' : null,
        ),
        onChanged: (_) {
          if (_wrong) setState(() => _wrong = false);
        },
        onSubmitted: (_) => _submit(),
      ),
      const SizedBox(height: 8),
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
    ];
  }

  Widget _resultPanel(Puzzle p) {
    final solved = _status == _Status.solved;
    final scheme = Theme.of(context).colorScheme;
    final fg = solved ? Colors.white : scheme.onSecondaryContainer;
    final hasMeaning = p.meaning != null && p.meaning!.isNotEmpty;
    final hasExplanation = p.explanation != null && p.explanation!.isNotEmpty;
    final days = ref.watch(progressProvider).activeStreak(DateTime.now());
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: solved ? Colors.green.shade600 : scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  children: [
                    Text(
                      solved ? 'Správně!' : 'Řešení',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fg),
                    ),
                    if (solved && days > 0)
                      Row(
                        key: const Key('streak-message'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BurningPuzzle(size: 18),
                          const SizedBox(width: 4),
                          Text('$days ${streakDayWord(days)} v řadě',
                              style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
                        ],
                      ),
                  ],
                ),
                Text(
                  p.solution,
                  key: const Key('solution-text'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: fg),
                ),
                if (hasMeaning)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(p.meaning!,
                        textAlign: TextAlign.center, style: TextStyle(color: fg)),
                  ),
                if (hasExplanation) ...[
                  TextButton.icon(
                    key: const Key('explanation-toggle'),
                    style: TextButton.styleFrom(
                      foregroundColor: fg,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => setState(() => _showExplanation = !_showExplanation),
                    icon: Icon(_showExplanation ? Icons.expand_less : Icons.expand_more),
                    label: const Text('Vysvětlení'),
                  ),
                  if (_showExplanation)
                    Text(
                      'Vysvětlení: ${p.explanation!}',
                      key: const Key('explanation-text'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: fg),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                key: const Key('next-button'),
                onPressed: widget.onNext,
                child: Text(widget.nextLabel),
              ),
            ),
            _LikeRow(puzzle: p),
            if (solved)
              IconButton(
                key: const Key('reset-one-button'),
                tooltip: 'Resetovat tento rébus',
                onPressed: _resetThis,
                icon: const Icon(Icons.restart_alt),
              ),
          ],
        ),
        if (_autoDuration != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TweenAnimationBuilder<double>(
              key: const Key('auto-next-bar'),
              tween: Tween(begin: 0, end: 1),
              duration: _autoDuration!,
              builder: (context, v, _) => LinearProgressIndicator(value: v, minHeight: 3),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text('♥ $count', key: const Key('like-count')),
      );
    }
    final liked = ref.watch(likesProvider).value?.contains(puzzle.id) ?? false;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('like-button'),
          tooltip: liked ? 'Líbilo se mi' : 'Líbí se mi',
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
        ),
        if (count > 0) Text('$count'),
      ],
    );
  }
}
