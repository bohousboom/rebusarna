import 'models/emoji_entry.dart';
import 'text_logic.dart';

const kImageExtensions = ['.png', '.jpg', '.jpeg', '.webp'];

/// Z cesty assetu udělá české slovo: "assets/images/Pór.png" -> "Pór".
String? imageWordFromPath(String path) {
  if (!path.startsWith(kImageAssetPrefix)) return null;
  final file = path.substring(kImageAssetPrefix.length);
  final dot = file.lastIndexOf('.');
  if (dot <= 0 || file.contains('/')) return null;
  if (!kImageExtensions.contains(file.substring(dot).toLowerCase())) return null;
  return file.substring(0, dot).replaceAll(RegExp(r'[_-]+'), ' ').trim();
}

/// Přiřadí vlastní obrázky k záznamům knihovny (podle jména nebo synonyma,
/// bez diakritiky). Obrázek bez odpovídajícího záznamu se přidá jako nový.
List<EmojiEntry> mergeImages(List<EmojiEntry> library, Iterable<String> assetPaths) {
  final result = [...library];
  for (final path in assetPaths) {
    final word = imageWordFromPath(path);
    if (word == null || word.isEmpty) continue;
    final key = normalize(word);
    var i = result.indexWhere((e) => normalize(e.cs) == key);
    if (i < 0) {
      i = result.indexWhere((e) => e.synonyms.any((s) => normalize(s) == key));
    }
    if (i >= 0) {
      result[i] = result[i].withImage(path);
    } else {
      result.add(EmojiEntry(cs: word, image: path));
    }
  }
  return result;
}
