import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

/// System "Save as" and "Pick file" dialogs, exposed as fields so tests and
/// previews can substitute their own.
class BackupIO {
  static Future<bool> Function(String name, Uint8List bytes) saveFile =
      _saveFile;

  static Future<({String name, Uint8List bytes})?> Function() pickFile =
      _pickFile;

  static Future<bool> _saveFile(String name, Uint8List bytes) async {
    // mimeType json, otherwise Android appends its own extension to the name.
    final uri = await FilePicker.saveFile(
      fileName: name,
      bytes: bytes,
      mimeType: 'application/json',
      dialogTitle: 'Сохранить копию',
    );
    return uri != null;
  }

  static Future<({String name, Uint8List bytes})?> _pickFile() async {
    // No json filter: the MIME type of files from Telegram can be anything.
    final f = await FilePicker.pickFile(type: FileType.any);
    if (f == null) return null;
    return (name: f.name, bytes: await f.readAsBytes());
  }
}
