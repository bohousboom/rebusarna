import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/app.dart';

void main() {
  testWidgets('spodní navigace přepíná záložky', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RebusarnaApp()));
    await tester.pumpAndSettle();
    expect(find.text('Hrát'), findsWidgets);
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    expect(find.text('Tvořit'), findsWidgets);
  });
}
