/// Předdefinovaná cesta k vlastním obrázkům (soubory v assets/images/).
const kImageAssetPrefix = 'assets/images/';

/// Hodnota tokenu typu image je buď emoji, nebo cesta k assetu.
bool isImageAsset(String tokenValue) => tokenValue.startsWith(kImageAssetPrefix);

class EmojiEntry {
  const EmojiEntry({
    this.emoji = '',
    required this.cs,
    this.synonyms = const [],
    this.image,
  });

  /// Emoji (může být prázdné, když slovo má jen vlastní obrázek).
  final String emoji;

  /// Hlavní české jméno v 1. pádě.
  final String cs;
  final List<String> synonyms;

  /// Cesta k vlastnímu obrázku; má přednost před emoji.
  final String? image;

  /// Hodnota, která se uloží do tokenu rébusu.
  String get tokenValue => image ?? emoji;

  EmojiEntry withImage(String path) =>
      EmojiEntry(emoji: emoji, cs: cs, synonyms: synonyms, image: path);

  factory EmojiEntry.fromJson(Map<String, dynamic> json) => EmojiEntry(
        emoji: json['emoji'] as String? ?? '',
        cs: json['cs'] as String,
        synonyms: (json['synonyms'] as List? ?? const []).cast<String>(),
        image: json['image'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'cs': cs,
        'synonyms': synonyms,
        if (image != null) 'image': image,
      };
}
