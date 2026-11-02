import 'dart:convert';
import 'dart:io';

class StorageService {
  static const String _folderName = 'EasyTables';
  static const String _libraryFileName = 'library.json';

  String get _separator => Platform.pathSeparator;

  Future<Directory> _baseDirectory() async {
    final environment = Platform.environment;
    if (Platform.isWindows) {
      final appData = environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) return Directory(appData);
    }
    final home = environment['HOME'] ?? environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) return Directory(home);
    return Directory.current;
  }

  Future<Directory> _dataDirectory() async {
    final base = await _baseDirectory();
    return _ensureDirectory('${base.path}$_separator$_folderName');
  }

  Future<Directory> _ensureDirectory(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<Map<String, dynamic>?> loadLibrary() async {
    try {
      final directory = await _dataDirectory();
      final file = File('${directory.path}$_separator$_libraryFileName');
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  Future<void> saveLibrary(Map<String, dynamic> data) async {
    final directory = await _dataDirectory();
    final file = File('${directory.path}$_separator$_libraryFileName');
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(data), flush: true);
  }

  Future<String> exportCsv({
    required String tableName,
    required String csv,
  }) async {
    final home = Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'];
    final candidates = <Directory>[];
    if (home != null && home.isNotEmpty) {
      final documents = Directory('$home${_separator}Documents');
      if (await documents.exists()) {
        try {
          candidates.add(await _ensureDirectory(
            '${documents.path}$_separator$_folderName',
          ));
        } on FileSystemException {
          // Fall through to the app data directory.
        }
      }
    }
    candidates.add(await _dataDirectory());

    Object? lastError;
    for (final directory in candidates) {
      try {
        final baseName = _sanitizeFileName(tableName);
        var file = File('${directory.path}$_separator$baseName.csv');
        var counter = 2;
        while (await file.exists()) {
          file = File(
            '${directory.path}$_separator$baseName ($counter).csv',
          );
          counter++;
        }
        await file.writeAsString('\uFEFF$csv', flush: true);
        return file.path;
      } on FileSystemException catch (error) {
        lastError = error;
      }
    }
    throw lastError is FileSystemException
        ? lastError
        : FileSystemException('Could not export this table.');
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
