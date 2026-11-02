import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import '../models/table_data.dart';
import '../services/storage_service.dart';
import '../utils/currencies.dart';
import '../utils/csv.dart';
import '../utils/values.dart';

class ExportResult {
  const ExportResult({required this.path, required this.csv});

  final String path;
  final String csv;
}

class AppState extends ChangeNotifier {
  AppState(this._storage);

  final StorageService _storage;
  final List<TableData> _tables = <TableData>[];
  String? _selectedId;
  bool _loaded = false;
  String? _loadError;
  ThemeMode _themeMode = ThemeMode.light;
  String _languageCode = 'en';
  Timer? _saveTimer;

  bool get isLoaded => _loaded;
  String? get loadError => _loadError;
  List<TableData> get tables => List.unmodifiable(_tables);
  String? get selectedId => _selectedId;
  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;

  TableData? get selectedTable {
    for (final table in _tables) {
      if (table.id == _selectedId) return table;
    }
    return null;
  }

  int get totalRows =>
      _tables.fold(0, (total, table) => total + table.rows.length);

  Future<void> initialize() async {
    try {
      final data = await _storage.loadLibrary();
      final rawTables = data?['tables'];
      if (rawTables is List) {
        for (final raw in rawTables.whereType<Map>()) {
          _tables.add(TableData.fromJson(raw.cast<String, dynamic>()));
        }
      }
      final savedLanguage = data?['language'];
      if (savedLanguage == 'ru' || savedLanguage == 'en') {
        _languageCode = savedLanguage as String;
      } else {
        _languageCode =
            PlatformDispatcher.instance.locale.languageCode == 'ru'
                ? 'ru'
                : 'en';
      }
      _themeMode = data?['theme'] == 'dark'
          ? ThemeMode.dark
          : ThemeMode.light;
    } catch (error) {
      _loadError = error.toString();
    }
    _selectedId = _tables.isEmpty ? null : _tables.first.id;
    _loaded = true;
    notifyListeners();
  }

  void selectTable(String id) {
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners();
  }

  TableData? tableById(String id) {
    for (final table in _tables) {
      if (table.id == id) return table;
    }
    return null;
  }

  TableData addTable(String name, {List<ColumnDef>? columns}) {
    final table = TableData.create(
      _cleanTableName(name),
      columns: columns,
    );
    _tables.add(table);
    _selectedId = table.id;
    _touch();
    return table;
  }

  void duplicateTable(String id, {String? name}) {
    final source = tableById(id);
    if (source == null) return;
    final copy = source.deepCopy(name: name ?? '${source.name} copy');
    final index = _tables.indexOf(source);
    _tables.insert(index + 1, copy);
    _selectedId = copy.id;
    _touch();
  }

  void renameTable(String id, String name) {
    final table = tableById(id);
    if (table == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    table.name = trimmed;
    table.updatedAt = DateTime.now();
    _touch();
  }

  void deleteTable(String id) {
    final table = tableById(id);
    if (table == null) return;
    final index = _tables.indexOf(table);
    _tables.removeAt(index);
    if (_selectedId == id) {
      if (_tables.isEmpty) {
        _selectedId = null;
      } else {
        _selectedId = _tables[index.clamp(0, _tables.length - 1)].id;
      }
    }
    _touch();
  }

  void addColumn(
    String tableId,
    String name,
    ColumnType type, {
    List<String> options = const [],
    String currencyCode = 'USD',
  }) {
    final table = tableById(tableId);
    if (table == null) return;
    final trimmed = name.trim();
    table.columns.add(ColumnDef.create(
      name: trimmed.isEmpty ? 'Column ${table.columns.length + 1}' : trimmed,
      type: type,
      options: normalizeOptions(options),
      currencyCode: currencyCode,
    ));
    table.updatedAt = DateTime.now();
    _touch();
  }

  void updateColumnCurrency(
    String tableId,
    String columnId,
    String currencyCode,
  ) {
    final table = tableById(tableId);
    final column = table?.columnById(columnId);
    if (table == null || column == null) return;
    if (column.currencyCode == currencyCode) return;
    column.currencyCode = currencyCode;
    table.updatedAt = DateTime.now();
    _touch();
  }

  void configureCurrencyColumn(
    String tableId,
    String columnId,
    String currencyCode,
  ) {
    final table = tableById(tableId);
    final column = table?.columnById(columnId);
    if (table == null || column == null) return;
    column.type = ColumnType.currency;
    column.currencyCode = currencyCode;
    table.updatedAt = DateTime.now();
    _touch();
  }

  void updateColumnOptions(
    String tableId,
    String columnId,
    List<String> options,
  ) {
    final table = tableById(tableId);
    final column = table?.columnById(columnId);
    if (table == null || column == null) return;
    final cleaned = normalizeOptions(options);
    if (_sameOptions(column.options, cleaned)) return;
    column.options = cleaned;
    table.updatedAt = DateTime.now();
    _touch();
  }

  void configureSelectColumn(
    String tableId,
    String columnId,
    List<String> options,
  ) {
    final table = tableById(tableId);
    final column = table?.columnById(columnId);
    if (table == null || column == null) return;
    column.type = ColumnType.select;
    column.options = normalizeOptions(options);
    table.updatedAt = DateTime.now();
    _touch();
  }

  bool _sameOptions(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  void renameColumn(String tableId, String columnId, String name) {
    final table = tableById(tableId);
    final column = table?.columnById(columnId);
    if (table == null || column == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    column.name = trimmed;
    table.updatedAt = DateTime.now();
    _touch();
  }

  void changeColumnType(String tableId, String columnId, ColumnType type) {
    final table = tableById(tableId);
    final column = table?.columnById(columnId);
    if (table == null || column == null || column.type == type) return;
    column.type = type;
    table.updatedAt = DateTime.now();
    _touch();
  }

  void deleteColumn(String tableId, String columnId) {
    final table = tableById(tableId);
    final column = table?.columnById(columnId);
    if (table == null || column == null) return;
    table.columns.remove(column);
    for (final row in table.rows) {
      row.cells.remove(columnId);
      row.currencies.remove(columnId);
    }
    table.updatedAt = DateTime.now();
    _touch();
  }

  void addRow(String tableId) {
    final table = tableById(tableId);
    if (table == null) return;
    table.rows.add(RowData.create());
    table.updatedAt = DateTime.now();
    _touch();
  }

  void duplicateRow(String tableId, String rowId) {
    final table = tableById(tableId);
    if (table == null) return;
    final index = table.rows.indexWhere((row) => row.id == rowId);
    if (index < 0) return;
    table.rows.insert(index + 1, table.rows[index].copyWithNewId());
    table.updatedAt = DateTime.now();
    _touch();
  }

  void deleteRow(String tableId, String rowId) {
    final table = tableById(tableId);
    if (table == null) return;
    table.rows.removeWhere((row) => row.id == rowId);
    table.updatedAt = DateTime.now();
    _touch();
  }

  void moveRow(String tableId, String rowId, int delta) {
    final table = tableById(tableId);
    if (table == null) return;
    final index = table.rows.indexWhere((row) => row.id == rowId);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= table.rows.length) return;
    final row = table.rows.removeAt(index);
    table.rows.insert(target, row);
    table.updatedAt = DateTime.now();
    _touch();
  }

  void setCell(String tableId, String rowId, String columnId, String value) {
    final table = tableById(tableId);
    if (table == null) return;
    for (final row in table.rows) {
      if (row.id != rowId) continue;
      if ((row.cells[columnId] ?? '') == value) return;
      row.cells[columnId] = value;
      table.updatedAt = DateTime.now();
      _touch(notify: false);
      return;
    }
  }

  void setCellCurrency(
    String tableId,
    String rowId,
    String columnId,
    String? currencyCode,
  ) {
    final table = tableById(tableId);
    final column = table?.columnById(columnId);
    if (table == null || column == null) return;
    for (final row in table.rows) {
      if (row.id != rowId) continue;
      final hadOverride = row.currencies.containsKey(columnId);
      if (currencyCode == null || currencyCode == column.currencyCode) {
        if (!hadOverride) return;
        row.currencies.remove(columnId);
      } else {
        final code = currencyFor(currencyCode).code;
        if (row.currencies[columnId] == code) return;
        row.currencies[columnId] = code;
      }
      table.updatedAt = DateTime.now();
      _touch();
      return;
    }
  }

  void refresh() {
    notifyListeners();
  }

  TableData importCsv(String tableName, ParsedCsv parsed) {
    final columns = <ColumnDef>[];
    for (var index = 0; index < parsed.headers.length; index++) {
      columns.add(ColumnDef.create(
        name: parsed.headers[index],
        type: _inferColumnType(parsed.rows, index),
      ));
    }
    final rows = parsed.rows.map((cells) {
      final values = <String, String>{};
      for (var index = 0; index < columns.length; index++) {
        values[columns[index].id] =
            index < cells.length ? cells[index] : '';
      }
      return RowData.create(values);
    }).toList();
    final table = TableData.create(
      _cleanTableName(tableName),
      columns: columns,
      rows: rows,
    );
    _tables.add(table);
    _selectedId = table.id;
    _touch();
    return table;
  }

  ColumnType _inferColumnType(List<List<String>> rows, int index) {
    var filled = 0;
    var numeric = 0;
    var dates = 0;
    for (final row in rows) {
      final raw = index < row.length ? row[index].trim() : '';
      if (raw.isEmpty) continue;
      filled++;
      if (parseNumber(raw) != null) {
        numeric++;
      } else if (parseDate(raw) != null) {
        dates++;
      }
      if (filled >= 60) break;
    }
    if (filled == 0) return ColumnType.text;
    if (numeric / filled >= 0.7) return ColumnType.number;
    if (dates / filled >= 0.7) return ColumnType.date;
    return ColumnType.text;
  }

  String csvForTable(TableData table) {
    return buildCsv(
      [for (final column in table.columns) column.name],
      [
        for (final row in table.rows)
          [for (final column in table.columns) row.cells[column.id] ?? ''],
      ],
    );
  }

  Future<ExportResult> exportTableCsv(TableData table) async {
    final csv = csvForTable(table);
    final path = await _storage.exportCsv(tableName: table.name, csv: csv);
    return ExportResult(path: path, csv: csv);
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _scheduleSave();
    notifyListeners();
  }

  void toggleTheme() {
    setThemeMode(
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  void setLanguage(String code) {
    if (code != 'en' && code != 'ru') return;
    if (_languageCode == code) return;
    _languageCode = code;
    _scheduleSave();
    notifyListeners();
  }

  String _cleanTableName(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'Untitled table' : trimmed;
  }

  void _touch({bool notify = true}) {
    _scheduleSave();
    if (notify) notifyListeners();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(_saveNow()),
    );
  }

  Future<void> _saveNow() async {
    _saveTimer = null;
    try {
      await _storage.saveLibrary({
        'version': 1,
        'savedAt': DateTime.now().toIso8601String(),
        'language': _languageCode,
        'theme': _themeMode == ThemeMode.dark ? 'dark' : 'light',
        'tables': [for (final table in _tables) table.toJson()],
      });
    } catch (error) {
      debugPrint('EasyTables: could not save library ($error)');
    }
  }

  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    await _saveNow();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
