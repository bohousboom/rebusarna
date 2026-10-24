import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/difficulty.dart';
import '../../data/providers.dart';
import '../../domain/adult_filter.dart';
import '../../domain/difficulty.dart';
import '../../domain/feed_plan.dart';
import '../../domain/models/puzzle.dart';

const _hints = {
  DifficultyMode.gradual: 'Začneš lehkými, těžší přibývají s tím, jak hádáš.',
  DifficultyMode.easy: 'Jen lehké rébusy.',
  DifficultyMode.medium: 'Jen střední rébusy.',
  DifficultyMode.hard: 'Jen těžké rébusy.',
  DifficultyMode.custom: 'Sám určíš, kolik karet z každé obtížnosti jde za sebou.',
  DifficultyMode.all: 'Všechno promíchané.',
};

Future<void> showDifficultyDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const _DifficultyDialog(),
    );

class _DifficultyDialog extends ConsumerWidget {
  const _DifficultyDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(difficultySettingProvider);
    final notifier = ref.read(difficultySettingProvider.notifier);

    // Kolik rébusů se v daném režimu vůbec nabídne (stejné pravidlo jako ve feedu).
    final all = visiblePuzzles(
      ref.watch(puzzlesProvider).value ?? const [],
      showAdult: ref.watch(showAdultProvider),
    );
    final stats = ref.watch(difficultyStatsProvider).value ?? const {};
    final solvedCount = ref.watch(progressProvider).solved.length;
    int levelOf(Puzzle p) {
      final s = stats[p.id];
      return s == null
          ? p.difficulty
          : computeDifficulty(authorDifficulty: p.difficulty, n: s.n, avgScore: s.avgScore);
    }

    String availability(DifficultyMode m) {
      final mix = setting.copyWith(mode: m).mixFor(solvedCount: solvedCount);
      final n = all.where((p) => isAllowedByMix(mix, levelOf(p))).length;
      final unlock = m == DifficultyMode.gradual && solvedCount < 10
          ? ' Těžké se odemknou po 10 vyřešených.'
          : '';
      return 'Nyní k dispozici: $n z ${all.length}.$unlock';
    }

    return AlertDialog(
      key: const Key('difficulty-dialog'),
      title: const Text('Obtížnost'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RadioGroup<DifficultyMode>(
              groupValue: setting.mode,
              onChanged: (m) {
                if (m != null) notifier.set(setting.copyWith(mode: m));
              },
              child: Column(
                children: [
                  for (final m in DifficultyMode.values)
                    RadioListTile<DifficultyMode>(
                      key: Key('difficulty-${m.name}'),
                      dense: true,
                      value: m,
                      title: Text(m.label),
                      subtitle: Text('${_hints[m]!}\n${availability(m)}'),
                    ),
                ],
              ),
            ),
            if (setting.mode == DifficultyMode.custom) ...[
              const Divider(),
              _Stepper(
                label: 'Lehké',
                color: Colors.green,
                value: setting.custom.easy,
                onChanged: (v) => notifier.set(setting.copyWith(
                    custom: DifficultyMix(v, setting.custom.medium, setting.custom.hard))),
              ),
              _Stepper(
                label: 'Střední',
                color: Colors.orange,
                value: setting.custom.medium,
                onChanged: (v) => notifier.set(setting.copyWith(
                    custom: DifficultyMix(setting.custom.easy, v, setting.custom.hard))),
              ),
              _Stepper(
                label: 'Těžké',
                color: Colors.red,
                value: setting.custom.hard,
                onChanged: (v) => notifier.set(setting.copyWith(
                    custom: DifficultyMix(setting.custom.easy, setting.custom.medium, v))),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  setting.custom.isEmpty
                      ? 'Nastav aspoň jednu obtížnost, jinak se karty promíchají.'
                      : 'Pořadí dokola: ${setting.custom.easy}× lehká, '
                          '${setting.custom.medium}× střední, ${setting.custom.hard}× těžká.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hotovo'),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final Color color;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(Icons.circle, size: 12, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          IconButton(
            key: Key('mix-$label-minus'),
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 24,
            child: Text('$value', textAlign: TextAlign.center),
          ),
          IconButton(
            key: Key('mix-$label-plus'),
            onPressed: value < 9 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      );
}
