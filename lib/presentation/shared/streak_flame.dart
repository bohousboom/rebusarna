import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

/// Plamínek denní série: oranžový, když dnes už hráč uhodl; šedý, když série čeká na dnešní rébus.
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
            Icon(Icons.local_fire_department, color: color, size: 26),
            const SizedBox(width: 2),
            Text('$days',
                key: const Key('streak-days'),
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

String _dayWord(int n) => n == 1 ? 'den' : (n >= 2 && n <= 4 ? 'dny' : 'dní');

String streakDayWord(int n) => _dayWord(n);
