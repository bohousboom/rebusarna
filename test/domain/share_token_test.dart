import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/domain/share_token.dart';

void main() {
  test('token je stabilní, neprozradí id a různá id mají různé tokeny', () {
    final t = shareToken('seed-myslenka');
    expect(t, shareToken('seed-myslenka'));
    expect(t, isNot(contains('myslenka')));
    expect(t, isNot(shareToken('seed-myslenky')));
    expect(t, matches(RegExp(r'^k[0-9a-f]{16}$')));
  });
}
