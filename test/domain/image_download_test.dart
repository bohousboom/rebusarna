import 'package:file_saver/file_saver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/data/image_download.dart';
import 'package:rebusarna/domain/models/puzzle.dart';
import 'package:rebusarna/domain/models/word_type.dart';

Puzzle _p(String solution) => Puzzle(
      id: 'x1',
      image: 'a.webp',
      solution: solution,
      wordTypes: [WordType.noun],
      difficulty: 1,
      authorName: 'a',
      createdAt: DateTime(2026),
    );

void main() {
  test('přípona a typ podle koncovky', () {
    expect(imageFormatOf('assets/images/Brána.webp').ext, 'webp');
    expect(imageFormatOf('https://x/y/a.PNG?t=1').mime, MimeType.png);
    expect(imageFormatOf('/data/1.jpg').ext, 'jpg');
    expect(imageFormatOf('bez-pripony').ext, 'jpg');
  });
  test('název souboru bez diakritiky', () {
    expect(imageFileName(_p('Řeřicha na louce')), 'rebus_rericha_na_louce');
    expect(imageFileName(_p('???')), 'rebus_x1');
  });
}
