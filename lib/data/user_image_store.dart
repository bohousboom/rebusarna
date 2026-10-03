import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Vybraný obrázek: cesta pro náhled a data pro nahrání.
class PickedImage {
  const PickedImage({required this.path, required this.bytes, required this.extension});

  final String path;
  final Uint8List bytes;
  final String extension;
}

/// Výběr obrázku z galerie.
abstract class UserImageStore {
  /// Vrátí vybraný obrázek, nebo null, když uživatel výběr zrušil.
  Future<PickedImage?> pick();
}

class GalleryUserImageStore implements UserImageStore {
  @override
  Future<PickedImage?> pick() async {
    // Obrázek se při výběru zmenší, aby se vešel do limitu 1 MB.
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      imageQuality: 80,
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    final name = picked.name.toLowerCase();
    final dot = name.lastIndexOf('.');
    final ext = (dot >= 0 && name.length - dot <= 5) ? name.substring(dot + 1) : 'jpg';

    var path = picked.path;
    if (!kIsWeb) {
      // trvalá kopie (lokální režim bez Supabase)
      final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/user_images');
      await dir.create(recursive: true);
      path = '${dir.path}/${DateTime.now().microsecondsSinceEpoch}.$ext';
      await File(picked.path).copy(path);
    }
    return PickedImage(path: path, bytes: bytes, extension: ext);
  }
}

final userImageStoreProvider =
    Provider<UserImageStore>((ref) => GalleryUserImageStore());
