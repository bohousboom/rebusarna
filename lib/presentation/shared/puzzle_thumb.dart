import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/difficulty.dart';
import '../../domain/models/puzzle.dart';
import 'puzzle_card.dart';

/// Náhled rébusu v mřížce: puntík s barvou obtížnosti; vyřešené ukazují řešení.
class PuzzleThumb extends ConsumerWidget {
  const PuzzleThumb({super.key, required this.puzzle, required this.solved});

  final Puzzle puzzle;
  final bool solved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final difficulty = ref.watch(effectiveDifficultyProvider((puzzle.id, puzzle.difficulty)));
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/puzzle/${puzzle.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: solved ? Colors.green : Colors.black12,
            width: solved ? 3 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PuzzleImage(puzzle.image, fit: BoxFit.cover, cacheWidth: 360),
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                key: const Key('difficulty-dot'),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: difficultyColor(difficulty),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
            if (solved)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  color: Colors.green.shade700,
                  child: Text(
                    puzzle.solution,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
