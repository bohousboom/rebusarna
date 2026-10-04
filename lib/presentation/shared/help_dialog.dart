import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/models/word_type.dart';
import 'puzzle_card.dart';

/// Otevře nápovědu: co na kartách hledat, na ukázce se slovem Hřebík.
Future<void> showHelpDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const _HelpDialog(),
    );

class _HelpDialog extends StatelessWidget {
  const _HelpDialog();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 700),
        child: ListView(
          padding: const EdgeInsets.all(20),
          shrinkWrap: true,
          children: [
            Text('Jak to funguje', style: text.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Na obrázku je schované slovo nebo výraz. Zkus ho uhodnout '
              'a napsat. Na kartě pomůže štítek v levém horním rohu.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                height: 300,
                width: 300 * 2 / 3 + 12,
                child: const PuzzleCard(
                  image: 'assets/images/Hřebík_v1.1.jpeg',
                  wordTypes: [WordType.noun],
                  difficulty: 1,
                  plusMinus: true,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text('Ukázka: řešení je „Hřebík"', style: text.bodySmall),
            ),
            const SizedBox(height: 16),
            const _Row(leading: _Symbol('?'), text: 'Hádej skryté slovo nebo výraz z obrázku.'),
            const _Row(
              leading: _Symbol('±'),
              text: 'Čárky nehrají roli: délka samohlásek se neřeší (např. ó = o).',
            ),
            _Row(
              leading: Icon(wordTypeIcon(WordType.noun), size: 24),
              text: 'Ikona říká druh slova (zde podstatné jméno). '
                  'Další: sloveso, přídavné jméno, město, jiné.',
            ),
            _Row(
              leading: Row(mainAxisSize: MainAxisSize.min, children: [
                for (final d in [1, 2, 3])
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                        color: difficultyColor(d), shape: BoxShape.circle),
                  ),
              ]),
              text: 'Barva štítku je obtížnost: tyrkysová lehká, žlutá střední, červená těžká.',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Rozumím'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Symbol extends StatelessWidget {
  const _Symbol(this.char);
  final String char;

  @override
  Widget build(BuildContext context) => Text(
        char,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.leading, required this.text});
  final Widget leading;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 56, child: Center(child: leading)),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
