import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Výběr obrázku z galerie a jeho trvalé uložení do složky aplikace.
abstract class UserImageStore {
  /// Vrátí cestu k uloženému obrázku, nebo null, když uživatel výběr zrušil.
  Future<String?> pickAndStore();
}

class GalleryUserImageStore implements UserImageStore {
  @override
  Future<String?> pickAndStore() async {
    // Obrázek se při výběru zmenší (úspora místa).
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return null;
    if (kIsWeb) return picked.path; // na webu jen dočasná URL (náhled)
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/user_images');
    await dir.create(recursive: true);
    final target = '${dir.path}/${DateTime.now().microsecondsSinceEpoch}.jpg';
    await File(picked.path).copy(target);
    return target;
  }
}

final userImageStoreProvider =
    Provider<UserImageStore>((ref) => GalleryUserImageStore());
