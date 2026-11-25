import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/data/app_version.dart';

void main() {
  test('porovnání verzí', () {
    expect(isNewerVersion('0.1.5', '0.1.3'), isTrue);
    expect(isNewerVersion('v0.2.0', '0.1.9+4'), isTrue);
    expect(isNewerVersion('0.1.5', '0.1.5'), isFalse);
    expect(isNewerVersion('0.1.3', '0.1.5'), isFalse);
    expect(isNewerVersion('?', '0.1.5'), isFalse);
  });

  test('parseLatestRelease čte tag a datum', () {
    final r = parseLatestRelease(
      '{"tag_name":"v0.1.5","published_at":"2026-11-25T12:44:49Z"}',
    );
    expect(r?.version, '0.1.5');
    expect(r?.publishedAt?.year, 2026);
    expect(parseLatestRelease('nesmysl'), isNull);
    expect(parseLatestRelease('{"message":"rate limit"}'), isNull);
  });
}
