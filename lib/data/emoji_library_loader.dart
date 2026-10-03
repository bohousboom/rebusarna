import 'dart:convert';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/image_merge.dart';
import '../domain/models/emoji_entry.dart';

const kEmojiLibraryAsset = 'assets/emoji_library.json';

List<EmojiEntry> parseEmojiLibrary(String json) => [
      for (final e in jsonDecode(json) as List)
        EmojiEntry.fromJson(e as Map<String, dynamic>),
    ];

/// Knihovna = emoji ze JSONu + vlastní obrázky nalezené v assets/images/.
final emojiLibraryProvider = FutureProvider<List<EmojiEntry>>((ref) async {
  final library = parseEmojiLibrary(await rootBundle.loadString(kEmojiLibraryAsset));
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final images = manifest.listAssets().where((a) => a.startsWith(kImageAssetPrefix));
  return mergeImages(library, images);
});
