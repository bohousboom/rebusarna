import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/app.dart';
import 'package:rebusarna/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('spodní navigace přepíná záložky', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        puzzlesProvider.overrideWith((ref) async => []),
      ],
      child: const RebusarnaApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Hrát'), findsWidgets);
    await tester.tap(find.byIcon(Icons.grid_view));
    await tester.pumpAndSettle();
    expect(find.text('Knihovna rébusů'), findsOneWidget);
  });
}
