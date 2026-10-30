import 'dart:io' show File;
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../domain/models/puzzle.dart';

/// Přípona a MIME typ podle koncovky obrázku (výchozí: JPEG).
({String ext, MimeType mime}) imageFormatOf(String image) {
  final path = image.split('?').first.toLowerCase();
  if (path.endsWith('.webp')) return (ext: 'webp', mime: MimeType.webp);
  if (path.endsWith('.png')) return (ext: 'png', mime: MimeType.png);
  return (ext: 'jpg', mime: MimeType.jpeg);
}

/// Název souboru z řešení: bez diakritiky a mezer, aby šel bezpečně uložit všude.
String imageFileName(Puzzle p) {
  const from = 'áäčďéěëíňóöřšťúůüýž';
  const to = 'aacdeeeinoorstuuuyz';
  final base = p.solution.toLowerCase().split('').map((c) {
    final i = from.indexOf(c);
    return i >= 0 ? to[i] : c;
  }).join().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  return 'rebus_${base.isEmpty ? p.id : base}';
}

Future<Uint8List> _loadBytes(String image) async {
  if (image.startsWith(kImageAssetPrefix)) {
    return (await rootBundle.load(image)).buffer.asUint8List();
  }
  if (kIsWeb || image.startsWith('http')) {
    final res = await http.get(Uri.parse(image));
    if (res.statusCode != 200) {
      throw Exception('Server vrátil ${res.statusCode}');
    }
    return res.bodyBytes;
  }
  return File(image).readAsBytes();
}

/// Uloží obrázek rébusu do zařízení (web = stažení souboru, mobil = výběr místa/Soubory).
Future<void> downloadPuzzleImage(Puzzle p) async {
  final fmt = imageFormatOf(p.image);
  await FileSaver.instance.saveFile(
    name: imageFileName(p),
    bytes: await _loadBytes(p.image),
    fileExtension: fmt.ext,
    mimeType: fmt.mime,
  );
}
