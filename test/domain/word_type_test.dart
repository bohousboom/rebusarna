import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/domain/models/word_type.dart';

void main() {
  test('město je samostatný druh slova s popiskem', () {
    expect(WordType.city.label, 'město');
    expect(WordType.fromName('city'), WordType.city);
  });

  test('neznámý název = jiné', () {
    expect(WordType.fromName('nesmysl'), WordType.other);
    expect(WordType.fromName(null), WordType.other);
  });

  test('všechny druhy mají unikátní název a popisek', () {
    expect(WordType.values.map((t) => t.name).toSet().length, WordType.values.length);
    expect(WordType.values.map((t) => t.label).toSet().length, WordType.values.length);
  });
}
