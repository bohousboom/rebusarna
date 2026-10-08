import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/image_shrink.dart';

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
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    var bytes = await picked.readAsBytes();
    final name = picked.name.toLowerCase();
    final dot = name.lastIndexOf('.');
    var ext = (dot >= 0 && name.length - dot <= 5) ? name.substring(dot + 1) : 'jpg';

    // Velké obrázky se zmenší a převedou na JPEG, aby se vešly do limitu 1 MB.
    final shrunk = await compute(shrinkImage, bytes);
    if (shrunk != null) {
      bytes = shrunk;
      ext = 'jpg';
    }

    var path = picked.path;
    if (!kIsWeb) {
      // trvalá kopie (lokální režim bez Supabase)
      final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/user_images');
      await dir.create(recursive: true);
      path = '${dir.path}/${DateTime.now().microsecondsSinceEpoch}.$ext';
      await File(path).writeAsBytes(bytes);
    }
    return PickedImage(path: path, bytes: bytes, extension: ext);
  }
}

final userImageStoreProvider =
    Provider<UserImageStore>((ref) => GalleryUserImageStore());
