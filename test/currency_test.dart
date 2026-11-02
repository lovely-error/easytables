import 'package:easytables/models/table_data.dart';
import 'package:easytables/theme.dart';
import 'package:easytables/utils/currencies.dart';
import 'package:easytables/utils/values.dart';
import 'package:easytables/widgets/table_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('currency columns persist their currency code', () {
    final column = ColumnDef.create(
      name: 'Price',
      type: ColumnType.currency,
      currencyCode: 'EUR',
    );
    final table = TableData(
      id: 't',
      name: 'Currencies',
      columns: [column],
      rows: [RowData(id: 'r1', cells: {column.id: '12.50'})],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final restored = TableData.fromJson(table.toJson());
    expect(restored.columns.single.type, ColumnType.currency);
    expect(restored.columns.single.currencyCode, 'EUR');
    expect(restored.rows.single.cells[column.id], '12.50');

    final copy = table.deepCopy();
    expect(copy.columns.single.currencyCode, 'EUR');
  });

  test('currency values validate and sort numerically', () {
    expect(
      isInvalidCellValue(r'$12.50', ColumnType.currency),
      isFalse,
    );
    expect(
      isInvalidCellValue('not money', ColumnType.currency),
      isTrue,
    );
    expect(
      isInvalidCellValue('', ColumnType.currency),
      isFalse,
    );
    expect(
      compareCells('10', '9', ColumnType.currency),
      greaterThan(0),
    );
  });

  test('currency formatting uses the column symbol', () {
    expect(formatCurrency(1234.5, 'USD'), r'$1,234.5');
    expect(formatCurrency(1234.5, 'RUB'), '₽1,234.5');
    expect(formatCurrency(1234.5, 'KGS'), 'сом 1,234.5');
    expect(formatCurrency(-12, 'EUR'), '-€12');
  });

  test('per-cell currencies survive json and deep copy', () {
    final price = ColumnDef.create(
      name: 'Price',
      type: ColumnType.currency,
      currencyCode: 'RUB',
    );
    final note = ColumnDef.create(name: 'Note', type: ColumnType.text);
    final table = TableData(
      id: 't',
      name: 'Mixed currencies',
      columns: [price, note],
      rows: [
        RowData(
          id: 'r1',
          cells: {price.id: '10'},
          currencies: {price.id: 'USD'},
        ),
        RowData(id: 'r2', cells: {price.id: '20'}),
      ],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final restored = TableData.fromJson(table.toJson());
    final restoredPrice = restored.columns.first;
    expect(restored.rows[0].currencies[restoredPrice.id], 'USD');
    expect(restored.rows[0].currencyFor(restoredPrice), 'USD');
    expect(restored.rows[1].currencyFor(restoredPrice), 'RUB');
    expect(restored.rows[1].currencies, isEmpty);

    final copy = table.deepCopy();
    final copiedPrice = copy.columns.first;
    expect(copy.rows[0].currencies[copiedPrice.id], 'USD');
    expect(copy.rows[0].currencies.containsKey(price.id), isFalse);
  });

  test('converts currency amounts using built-in rates', () {
    expect(convertCurrency(100, from: 'USD', to: 'USD'), 100);
    expect(
      convertCurrency(100, from: 'USD', to: 'RUB'),
      closeTo(9090.91, 0.1),
    );
    expect(
      convertCurrency(100, from: 'EUR', to: 'USD'),
      closeTo(108, 0.001),
    );
  });

  test('currency sorting compares converted values', () {
    final price = ColumnDef.create(
      name: 'Price',
      type: ColumnType.currency,
      currencyCode: 'RUB',
    );
    RowData row(String id, String amount, [String? code]) {
      return RowData(
        id: id,
        cells: {price.id: amount},
        currencies: code == null ? null : {price.id: code},
      );
    }

    final rows = [
      row('usd', '200', 'USD'),
      row('rub', '5000'),
      row('eur', '30', 'EUR'),
    ];
    rows.sort((a, b) => compareCurrencyRows(a, b, price));
    expect(rows.map((row) => row.id), ['eur', 'rub', 'usd']);
    expect(
      compareCurrencyRows(row('bad', 'oops'), row('usd', '1', 'USD'), price),
      greaterThan(0),
    );
  });

  test('currency rows can be converted for aggregation', () {
    final price = ColumnDef.create(
      name: 'Price',
      type: ColumnType.currency,
      currencyCode: 'RUB',
    );
    final original = RowData(
      id: 'r1',
      cells: {price.id: '100'},
      currencies: {price.id: 'USD'},
    );

    final converted = convertCurrencyColumn([original], price);
    expect(converted.single.id, 'r1');
    expect(
      parseNumber(converted.single.cells[price.id]),
      closeTo(9090.91, 0.1),
    );
    expect(converted.single.currencies, isEmpty);
    expect(original.currencies[price.id], 'USD');
  });

  testWidgets('currency sorting converts each cell to the column currency', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026, 1, 1);
    final price = ColumnDef(
      id: 'price',
      name: 'Price',
      type: ColumnType.currency,
      currencyCode: 'RUB',
    );
    final table = TableData(
      id: 't',
      name: 'Currencies',
      columns: [price],
      rows: [
        RowData(
          id: 'usd',
          cells: {'price': '200'},
          currencies: {'price': 'USD'},
        ),
        RowData(id: 'rub', cells: {'price': '5000'}),
        RowData(
          id: 'eur',
          cells: {'price': '30'},
          currencies: {'price': 'EUR'},
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: TableGrid(
            table: table,
            rows: table.rows,
            query: '',
            onClearFilter: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Price'));
    await tester.pump();

    final eurTop = tester.getTopLeft(find.text('30')).dy;
    final rubTop = tester.getTopLeft(find.text('5000')).dy;
    final usdTop = tester.getTopLeft(find.text('200')).dy;
    expect(eurTop, lessThan(rubTop));
    expect(rubTop, lessThan(usdTop));
  });

  testWidgets('currency cells expose an independent currency menu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026, 1, 1);
    final price = ColumnDef(
      id: 'price',
      name: 'Price',
      type: ColumnType.currency,
      currencyCode: 'RUB',
    );
    final table = TableData(
      id: 't',
      name: 'Currencies',
      columns: [price],
      rows: [
        RowData(
          id: 'r1',
          cells: {'price': '350'},
          currencies: {'price': 'USD'},
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: TableGrid(
            table: table,
            rows: table.rows,
            query: '',
            onClearFilter: () {},
          ),
        ),
      ),
    );

    expect(find.text(r'$'), findsOneWidget);
    await tester.tap(find.text(r'$'));
    await tester.pumpAndSettle();

    expect(find.text('EUR · €'), findsOneWidget);
    expect(find.text('Use column currency (RUB)'), findsOneWidget);
  });
}
