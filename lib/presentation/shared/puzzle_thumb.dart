import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/puzzle.dart';
import 'puzzle_card.dart';

/// Náhled rébusu v mřížce; vyřešené ukazují řešení a otevírají detail.
class PuzzleThumb extends StatelessWidget {
  const PuzzleThumb({super.key, required this.puzzle, required this.solved});

  final Puzzle puzzle;
  final bool solved;

  @override
  Widget build(BuildContext context) {
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
