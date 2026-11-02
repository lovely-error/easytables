import '../utils/ids.dart';

enum ColumnType {
  text('Text'),
  number('Number'),
  date('Date'),
  select('Select'),
  currency('Currency');

  const ColumnType(this.label);

  final String label;

  static ColumnType fromName(String? name) {
    for (final type in ColumnType.values) {
      if (type.name == name) return type;
    }
    return ColumnType.text;
  }
}

class ColumnDef {
  ColumnDef({
    required this.id,
    required this.name,
    required this.type,
    List<String>? options,
    String? currencyCode,
  })  : options = options ?? <String>[],
        currencyCode = currencyCode ?? 'USD';

  final String id;
  String name;
  ColumnType type;
  List<String> options;
  String currencyCode;

  factory ColumnDef.create({
    required String name,
    required ColumnType type,
    List<String>? options,
    String? currencyCode,
  }) {
    return ColumnDef(
      id: newId('c_'),
      name: name,
      type: type,
      options: options == null ? null : List<String>.from(options),
      currencyCode: currencyCode,
    );
  }

  factory ColumnDef.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return ColumnDef(
      id: json['id'] as String? ?? newId('c_'),
      name: json['name'] as String? ?? 'Column',
      type: ColumnType.fromName(json['type'] as String?),
      options: rawOptions is List ? _normalizedOptions(rawOptions) : null,
      currencyCode: json['currencyCode'] as String?,
    );
  }

  ColumnDef copy({
    String? id,
    String? name,
    ColumnType? type,
    List<String>? options,
    String? currencyCode,
  }) {
    return ColumnDef(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      options: options ?? List<String>.from(this.options),
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'options': options,
        'currencyCode': currencyCode,
      };
}

List<String> _normalizedOptions(List<dynamic> raw) {
  final seen = <String>{};
  final result = <String>[];
  for (final entry in raw) {
    final value = entry?.toString().trim() ?? '';
    if (value.isEmpty || !seen.add(value.toLowerCase())) continue;
    result.add(value);
  }
  return result;
}

class RowData {
  RowData({
    required this.id,
    Map<String, String>? cells,
    Map<String, String>? currencies,
  })  : cells = cells ?? <String, String>{},
        currencies = currencies ?? <String, String>{};

  final String id;
  final Map<String, String> cells;
  final Map<String, String> currencies;

  factory RowData.create([
    Map<String, String>? cells,
    Map<String, String>? currencies,
  ]) {
    return RowData(id: newId('r_'), cells: cells, currencies: currencies);
  }

  factory RowData.fromJson(Map<String, dynamic> json) {
    final rawCells = json['cells'];
    final rawCurrencies = json['currencies'];
    return RowData(
      id: json['id'] as String? ?? newId('r_'),
      cells: rawCells is Map
          ? rawCells.map(
              (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
            )
          : null,
      currencies: rawCurrencies is Map
          ? rawCurrencies.map(
              (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
            )
          : null,
    );
  }

  String currencyFor(ColumnDef column) {
    return currencies[column.id] ?? column.currencyCode;
  }

  RowData copyWithNewId() {
    return RowData(
      id: newId('r_'),
      cells: Map<String, String>.from(cells),
      currencies: Map<String, String>.from(currencies),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cells': cells,
        if (currencies.isNotEmpty) 'currencies': currencies,
      };
}

class TableData {
  TableData({
    required this.id,
    required this.name,
    required this.columns,
    required this.rows,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  String name;
  final List<ColumnDef> columns;
  final List<RowData> rows;
  final DateTime createdAt;
  DateTime updatedAt;

  factory TableData.create(
    String name, {
    List<ColumnDef>? columns,
    List<RowData>? rows,
    String? id,
  }) {
    final now = DateTime.now();
    return TableData(
      id: id ?? newId('t_'),
      name: name,
      columns: columns ??
          [
            ColumnDef.create(name: 'Item', type: ColumnType.text),
            ColumnDef.create(name: 'Category', type: ColumnType.text),
            ColumnDef.create(name: 'Amount', type: ColumnType.number),
          ],
      rows: rows ?? <RowData>[],
      createdAt: now,
      updatedAt: now,
    );
  }

  factory TableData.fromJson(Map<String, dynamic> json) {
    final rawColumns = json['columns'];
    final rawRows = json['rows'];
    final createdAt =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now();
    return TableData(
      id: json['id'] as String? ?? newId('t_'),
      name: json['name'] as String? ?? 'Untitled table',
      columns: rawColumns is List
          ? rawColumns
              .whereType<Map>()
              .map((raw) => ColumnDef.fromJson(raw.cast<String, dynamic>()))
              .toList()
          : <ColumnDef>[],
      rows: rawRows is List
          ? rawRows
              .whereType<Map>()
              .map((raw) => RowData.fromJson(raw.cast<String, dynamic>()))
              .toList()
          : <RowData>[],
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? createdAt,
    );
  }

  ColumnDef? columnById(String? id) {
    if (id == null) return null;
    for (final column in columns) {
      if (column.id == id) return column;
    }
    return null;
  }

  TableData deepCopy({String? name}) {
    final copiedColumns =
        columns.map((column) => column.copy(id: newId('c_'))).toList();
    final idMap = <String, String>{
      for (var i = 0; i < columns.length; i++)
        columns[i].id: copiedColumns[i].id,
    };
    final now = DateTime.now();
    return TableData(
      id: newId('t_'),
      name: name ?? this.name,
      columns: copiedColumns,
      rows: rows.map((row) {
        return RowData.create(
          {
            for (final entry in row.cells.entries)
              if (idMap[entry.key] != null) idMap[entry.key]!: entry.value,
          },
          {
            for (final entry in row.currencies.entries)
              if (idMap[entry.key] != null) idMap[entry.key]!: entry.value,
          },
        );
      }).toList(),
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'columns': columns.map((column) => column.toJson()).toList(),
        'rows': rows.map((row) => row.toJson()).toList(),
      };
}
