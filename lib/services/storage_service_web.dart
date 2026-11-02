import 'dart:js_interop';

import 'package:sembast_web/sembast_web.dart';
import 'package:web/web.dart' as web;

class StorageService {
  static const String _databaseName = 'easytables';
  static const String _storeName = 'library';
  static const String _recordKey = 'main';

  final _store = stringMapStoreFactory.store(_storeName);
  Database? _database;

  Future<Database> _openDatabase() async {
    final existing = _database;
    if (existing != null) return existing;
    final database = await databaseFactoryWeb.openDatabase(_databaseName);
    _database = database;
    return database;
  }

  Future<Map<String, dynamic>?> loadLibrary() async {
    final database = await _openDatabase();
    final value = await _store.record(_recordKey).get(database);
    if (value == null) return null;
    return Map<String, dynamic>.from(value);
  }

  Future<void> saveLibrary(Map<String, dynamic> data) async {
    final database = await _openDatabase();
    await _store
        .record(_recordKey)
        .put(database, data.cast<String, Object?>());
  }

  Future<String> exportCsv({
    required String tableName,
    required String csv,
  }) async {
    final fileName = '${_sanitizeFileName(tableName)}.csv';
    _downloadCsv(fileName, csv);
    return fileName;
  }

  void _downloadCsv(String fileName, String csv) {
    final blob = web.Blob(
      <web.BlobPart>['\uFEFF$csv'.toJS].toJS,
      web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName
      ..style.display = 'none';
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }

  String _sanitizeFileName(String name) {
    var sanitized =
        name.replaceAll(RegExp(r'[<>:"/\\|?*\u0000-\u001F]'), '_').trim();
    sanitized = sanitized.replaceAll(RegExp(r'[. ]+$'), '');
    if (sanitized.isEmpty) sanitized = 'table';
    if (sanitized.length > 80) sanitized = sanitized.substring(0, 80);
    const reserved = {
      'CON',
      'PRN',
      'AUX',
      'NUL',
      'COM1',
      'COM2',
      'COM3',
      'COM4',
      'COM5',
      'COM6',
      'COM7',
      'COM8',
      'COM9',
      'LPT1',
      'LPT2',
      'LPT3',
      'LPT4',
      'LPT5',
      'LPT6',
      'LPT7',
      'LPT8',
      'LPT9',
    };
    if (reserved.contains(sanitized.toUpperCase())) {
      sanitized = '_$sanitized';
    }
    return sanitized;
  }
}
