import 'package:easytables/models/table_data.dart';
import 'package:easytables/utils/values.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('table json round-trip keeps structure and values', () {
    final table = TableData.create('Sales');
    table.rows.add(RowData.create({
      table.columns[0].id: 'Coffee',
      table.columns[1].id: 'Food',
      table.columns[2].id: '4.5',
    }));

    final restored = TableData.fromJson(table.toJson());

    expect(restored.id, table.id);
    expect(restored.name, 'Sales');
    expect(restored.columns.map((c) => c.name), ['Item', 'Category', 'Amount']);
    expect(restored.columns.map((c) => c.type), [
      ColumnType.text,
      ColumnType.text,
      ColumnType.number,
    ]);
    expect(restored.rows.single.cells, table.rows.single.cells);
  });

  test('deep copy assigns fresh ids and keeps values', () {
    final table = TableData.create('Sales');
    table.rows.add(RowData.create({
      table.columns[0].id: 'Coffee',
      table.columns[2].id: '4.5',
    }));

    final copy = table.deepCopy(name: 'Copy');

    expect(copy.id, isNot(table.id));
    expect(copy.name, 'Copy');
    expect(copy.columns.first.id, isNot(table.columns.first.id));
    expect(copy.rows.single.id, isNot(table.rows.single.id));
    expect(copy.rows.single.cells[copy.columns[0].id], 'Coffee');
    expect(copy.rows.single.cells[copy.columns[2].id], '4.5');
  });

  test('number parsing tolerates separators and percent', () {
    expect(parseNumber('1,234.5'), 1234.5);
    expect(parseNumber(r'$1 200'), 1200);
    expect(parseNumber('12%'), 0.12);
    expect(parseNumber('abc'), isNull);
    expect(parseNumber(''), isNull);
    expect(parseNumber('NaN'), isNull);
    expect(parseNumber('Infinity'), isNull);
  });

  test('sorting supports numeric and date columns', () {
    expect(compareCells('2', '10', ColumnType.number), lessThan(0));
    expect(compareCells('2', '10', ColumnType.text), greaterThan(0));
    expect(
      compareCells('2026-01-02', '2026-01-10', ColumnType.date),
      lessThan(0),
    );
  });

  test('filter matches any cell case-insensitively', () {
    final table = TableData.create('Sales');
    table.rows.add(RowData.create({
      table.columns[0].id: 'Espresso',
      table.columns[1].id: 'Drinks',
    }));
    table.rows.add(RowData.create({
      table.columns[0].id: 'Bagel',
      table.columns[1].id: 'Food',
    }));

    expect(filterRows(table, 'esp').single.cells[table.columns[0].id],
        'Espresso');
    expect(filterRows(table, 'food').length, 1);
    expect(filterRows(table, '').length, 2);
  });

  test('formats numbers with grouping and trims zeros', () {
    expect(formatNumber(1234567.5), '1,234,567.5');
    expect(formatNumber(12), '12');
    expect(formatCompactNumber(1500), '1.5k');
    expect(formatCompactNumber(2000000), '2M');
  });

  test('soft validation flags invalid numbers and dates only', () {
    expect(isInvalidCellValue('', ColumnType.number), isFalse);
    expect(isInvalidCellValue('  ', ColumnType.date), isFalse);
    expect(isInvalidCellValue('12.5', ColumnType.number), isFalse);
    expect(isInvalidCellValue(r'$1,200', ColumnType.number), isFalse);
    expect(isInvalidCellValue('twelve', ColumnType.number), isTrue);
    expect(isInvalidCellValue('2026-01-31', ColumnType.date), isFalse);
    expect(isInvalidCellValue('2026-13-01', ColumnType.date), isTrue);
    expect(isInvalidCellValue('2026-02-30', ColumnType.date), isTrue);
    expect(isInvalidCellValue('2024-02-29', ColumnType.date), isFalse);
    expect(isInvalidCellValue('2026-01-31T10:30:00Z', ColumnType.date),
        isFalse);
    expect(isInvalidCellValue('anything', ColumnType.text), isFalse);
  });

  test('counts invalid cells across typed columns', () {
    final table = TableData.create('Validation');
    final number = table.columns[2].id;
    final text = table.columns[0].id;
    final date = ColumnDef(id: 'date', name: 'Date', type: ColumnType.date);
    table.columns.add(date);
    table.rows.add(RowData(id: 'r1', cells: {
      text: 'Coffee',
      number: '4.5',
      date.id: '2026-01-31',
    }));
    table.rows.add(RowData(id: 'r2', cells: {
      text: 'Tea',
      number: 'not a number',
      date.id: '2026-13-01',
    }));

    expect(countInvalidCells(table), 2);
    expect(countInvalidColumnCells(table, table.columns[2]), 1);
    expect(countInvalidColumnCells(table, table.columns[0]), 0);
  });

  test('select options survive json and deep copy', () {
    final table = TableData.create(
      'Choices',
      columns: [
        ColumnDef.create(
          name: 'Priority',
          type: ColumnType.select,
          options: ['Low', 'Medium', 'High'],
        ),
      ],
    );
    table.rows.add(RowData(
      id: 'r1',
      cells: {table.columns.single.id: 'High'},
    ));

    final restored = TableData.fromJson(table.toJson());
    expect(restored.columns.single.type, ColumnType.select);
    expect(restored.columns.single.options, ['Low', 'Medium', 'High']);

    final copy = table.deepCopy();
    expect(copy.columns.single.options, ['Low', 'Medium', 'High']);
  });

  test('normalizes and deduplicates select options', () {
    expect(
      normalizeOptions([' High ', 'low', 'high', '', 'High']),
      ['High', 'low'],
    );
  });

  test('select values are validated against the option set', () {
    expect(
      isInvalidCellValue(
        'High',
        ColumnType.select,
        options: ['Low', 'High'],
      ),
      isFalse,
    );
    expect(
      isInvalidCellValue(
        'Urgent',
        ColumnType.select,
        options: ['Low', 'High'],
      ),
      isTrue,
    );
    expect(
      isInvalidCellValue('', ColumnType.select, options: ['Low']),
      isFalse,
    );
    expect(
      isInvalidCellValue(
        ' High ',
        ColumnType.select,
        options: ['High'],
      ),
      isFalse,
    );
  });

  test('collects distinct values for select option prefills', () {
    final table = TableData.create('Prefill');
    final column = table.columns[1];
    table.rows.add(RowData(
      id: 'r1',
      cells: {column.id: 'Beta'},
    ));
    table.rows.add(RowData(
      id: 'r2',
      cells: {column.id: 'alpha'},
    ));
    table.rows.add(RowData(
      id: 'r3',
      cells: {column.id: 'Beta '},
    ));

    expect(distinctColumnValues(table, column), ['alpha', 'Beta']);
  });
}
