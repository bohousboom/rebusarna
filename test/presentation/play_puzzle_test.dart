import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/data/providers.dart';
import 'package:rebusarna/domain/models/puzzle.dart';
import 'package:rebusarna/domain/models/word_type.dart';
import 'package:rebusarna/presentation/play/play_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _puzzle = Puzzle(
  id: 't1',
  image: 'assets/images/neexistuje.png', // chybějící obrázek -> ikona, test běží dál
  solution: 'poranit',
  meaning: 'způsobit zranění',
  explanation: 'pór + a + nit',
  wordType: WordType.verb,
  difficulty: 2,
  authorName: 'test',
  createdAt: DateTime(2026),
);

Future<void> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(360 * 3, 800 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      puzzlesProvider.overrideWith((ref) async => [_puzzle]),
    ],
    child: const MaterialApp(home: Scaffold(body: PlayScreen())),
  ));
  await tester.pumpAndSettle();
}

String _streak(WidgetTester tester) =>
    (tester.widget<Chip>(find.byKey(const Key('streak'))).label as Text).data!;

void main() {
  testWidgets('hraní jednoho puzzle: štítek, špatný tip, nápověda, výhra, série',
      (tester) async {
    await _pump(tester);

    // štítek: "poranit" nemá čárku -> ±, druh slova sloveso
    expect(find.text('?'), findsOneWidget);
    expect(find.byKey(const Key('badge-plusminus')), findsOneWidget);
    expect(find.text('sloveso'), findsOneWidget);
    expect(_streak(tester), 'Série: 0');

    // špatný tip
    await tester.enterText(find.byKey(const Key('tip-field')), 'zranit');
    await tester.tap(find.byKey(const Key('submit-button')));
    await tester.pump();
    expect(find.text('Zkus to znovu'), findsOneWidget);
    expect(_streak(tester), 'Série: 0');

    // nápověda: 1. klik počet písmen, 2. klik první písmeno
    await tester.tap(find.byKey(const Key('hint-button')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('hint-text'))).data, '_ _ _ _ _ _ _');
    await tester.tap(find.byKey(const Key('hint-button')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('hint-text'))).data, 'p _ _ _ _ _ _');

    // správný tip (velká písmena a mezery navíc nevadí)
    await tester.enterText(find.byKey(const Key('tip-field')), '  PORANIT ');
    await tester.tap(find.byKey(const Key('submit-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Správně!'), findsOneWidget);
    expect(find.text('způsobit zranění'), findsOneWidget);
    expect(find.text('Vysvětlení: pór + a + nit'), findsOneWidget);
    expect(_streak(tester), 'Série: 1');

    // reset jednoho rébusu: vrátí se pole pro tip
    await tester.ensureVisible(find.byKey(const Key('reset-one-button')));
    await tester.tap(find.byKey(const Key('reset-one-button')));
    await tester.pump();
    expect(find.byKey(const Key('tip-field')), findsOneWidget);
  });

  testWidgets('ukázat řešení přeruší sérii', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('reveal-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.widget<Text>(find.byKey(const Key('solution-text'))).data, 'poranit');
    expect(_streak(tester), 'Série: 0');
  });
}
