import 'dart:io';

import 'package:flutter/services.dart';

Future<void> loadTestFonts() async {
  Future<void> load(String family, File f) async {
    if (!f.existsSync()) return;
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    await loader.load();
  }

  final root = Platform.environment['FLUTTER_ROOT'] ?? '/home/box/flutter';
  final mf = '$root/bin/cache/artifacts/material_fonts';
  await load('Doto', File('assets/fonts/Doto.ttf'));
  await load('MaterialIcons', File('$mf/MaterialIcons-Regular.otf'));
  await load('Roboto', File('$mf/Roboto-Regular.ttf'));
}
