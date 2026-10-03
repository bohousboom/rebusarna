import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/domain/image_merge.dart';
import 'package:rebusarna/domain/models/emoji_entry.dart';

void main() {
  const lib = [
    EmojiEntry(emoji: '🧅', cs: 'cibule', synonyms: ['pór']),
    EmojiEntry(emoji: '🐶', cs: 'pes'),
  ];

  test('imageWordFromPath', () {
    expect(imageWordFromPath('assets/images/Pór.png'), 'Pór');
    expect(imageWordFromPath('assets/images/velky_pes.JPG'), 'velky pes');
    expect(imageWordFromPath('assets/images/.gitkeep'), isNull);
    expect(imageWordFromPath('assets/images/README.txt'), isNull);
    expect(imageWordFromPath('assets/other/pes.png'), isNull);
  });

  test('obrázek se přiřadí podle jména i synonyma, bez diakritiky', () {
    final r = mergeImages(lib, ['assets/images/PES.png', 'assets/images/por.png']);
    expect(r.length, 2);
    expect(r[0].tokenValue, 'assets/images/por.png');
    expect(r[1].tokenValue, 'assets/images/PES.png');
    expect(r[0].emoji, '🧅');
  });

  test('neznámý obrázek se přidá jako nový pojem', () {
    final r = mergeImages(lib, ['assets/images/nit.png']);
    expect(r.length, 3);
    expect(r.last.cs, 'nit');
    expect(r.last.emoji, '');
    expect(isImageAsset(r.last.tokenValue), isTrue);
  });
}
