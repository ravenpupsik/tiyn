import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the Glina fonts for tests (pubspec fonts are not loaded in tests).
Future<void> loadGlinaFonts() async {
  Future<void> load(String family, String file) async {
    final bytes = File('assets/fonts/$file').readAsBytesSync();
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
    await loader.load();
  }

  await load('GolosText', 'GolosText-VariableFont_wght.ttf');
  await load('Literata', 'Literata-VariableFont_opsz_wght.ttf');
  await load('Nunito', 'Nunito-VariableFont_wght.ttf');
  final icons = File(
    '${Platform.environment['FLUTTER_ROOT'] ?? '/home/box/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(
          ByteData.sublistView(Uint8List.fromList(icons.readAsBytesSync())),
        ),
      );
    await loader.load();
  }
}
