import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/domain/models/word_type.dart';

void main() {
  test('město je samostatný druh slova s popiskem', () {
    expect(WordType.city.label, 'město / místo');
    expect(WordType.fromName('city'), WordType.city);
    expect(WordType.plural.label, 'množné číslo');
    expect(WordType.fromName('plural'), WordType.plural);
  });

  test('seznam druhů: z pole, jinak ze starého jediného druhu', () {
    expect(WordType.listFrom(['noun', 'plural'], 'noun'), [WordType.noun, WordType.plural]);
    expect(WordType.listFrom(null, 'verb'), [WordType.verb]);
    expect(WordType.listFrom([], 'city'), [WordType.city]);
    expect(WordType.listFrom(['noun', 'noun'], null), [WordType.noun]);
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
