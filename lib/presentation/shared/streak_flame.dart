import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

/// Hořící puzzle: dílek skládačky s plamenem nahoře. [lit] = svítí, jinak je šedé.
class BurningPuzzle extends StatelessWidget {
  const BurningPuzzle({super.key, this.size = 28, this.lit = true});

  final double size;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    Widget img = Image.asset(
      'assets/icons/streak_puzzle.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
    if (!lit) {
      // Nesvítí: černobílá a trochu průhledná.
      img = Opacity(
        opacity: 0.6,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0, //
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: img,
        ),
      );
    }
    return SizedBox(width: size, height: size, child: img);
  }
}

/// Hořící puzzle s počtem dní denní série: oranžový, když dnes už hráč uhodl; šedý, když série čeká na dnešní rébus.
class StreakFlame extends ConsumerWidget {
  const StreakFlame({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final now = DateTime.now();
    final days = progress.activeStreak(now);
    final lit = progress.solvedToday(now);
    final color = lit ? Colors.deepOrange : Theme.of(context).disabledColor;
    return Tooltip(
      message: days == 0
          ? 'Uhodni dnes rébus a zapal sérii'
          : lit
          ? 'Série: $days ${_dayWord(days)} v řadě'
          : 'Série $days ${_dayWord(days)}, uhodni dnes rébus a neztratíš ji',
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        key: const Key('streak-flame'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BurningPuzzle(size: 26, lit: lit),
            const SizedBox(width: 2),
            Text(
              '$days',
              key: const Key('streak-days'),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _dayWord(int n) => n == 1 ? 'den' : (n >= 2 && n <= 4 ? 'dny' : 'dní');

String streakDayWord(int n) => _dayWord(n);
