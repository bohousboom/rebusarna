import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/data/providers.dart';
import 'package:rebusarna/data/user_image_store.dart';
import 'package:rebusarna/domain/puzzle_validation.dart';
import 'package:rebusarna/presentation/create/create_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeStore implements UserImageStore {
  @override
  Future<String?> pickAndStore() async => '/tmp/fake.jpg';
}

void main() {
  group('validateDraft', () {
    test('chybí obojí', () => expect(validateDraft(image: null, solution: ' ', explanation: ''), hasLength(3)));
    test('chybí řešení', () => expect(validateDraft(image: 'a.png', solution: '', explanation: 'x'), hasLength(1)));
    test('chybí obrázek', () => expect(validateDraft(image: '', solution: 'pes', explanation: 'x'), hasLength(1)));
    test('OK', () => expect(validateDraft(image: 'a.png', solution: 'pes', explanation: 'x'), isEmpty));
  });

  testWidgets('Zveřejnit bez obrázku a řešení ukáže chyby; po výběru obrázku jen chybu řešení',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(360 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        userImageStoreProvider.overrideWithValue(_FakeStore()),
      ],
      child: const MaterialApp(home: Scaffold(body: CreateScreen())),
    ));

    await tester.ensureVisible(find.byKey(const Key('publish-button')));
    await tester.tap(find.byKey(const Key('publish-button')));
    await tester.pump();
    var errors = tester.widget<Text>(find.byKey(const Key('create-errors'))).data!;
    expect(errors, contains('obrázek'));
    expect(errors, contains('řešení'));

    await tester.ensureVisible(find.byKey(const Key('pick-image-button')));
    await tester.tap(find.byKey(const Key('pick-image-button')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('publish-button')));
    await tester.tap(find.byKey(const Key('publish-button')));
    await tester.pump();
    errors = tester.widget<Text>(find.byKey(const Key('create-errors'))).data!;
    expect(errors, isNot(contains('obrázek')));
    expect(errors, contains('řešení'));
  });
}
