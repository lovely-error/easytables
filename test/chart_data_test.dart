import 'package:easytables/models/table_data.dart';
import 'package:easytables/utils/chart_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final category = ColumnDef(id: 'cat', name: 'Category', type: ColumnType.text);
  final value = ColumnDef(id: 'val', name: 'Amount', type: ColumnType.number);

  List<RowData> rows() => [
        RowData(id: 'r1', cells: {category.id: 'Food', value.id: '10'}),
        RowData(id: 'r2', cells: {category.id: 'Food', value.id: '20'}),
        RowData(id: 'r3', cells: {category.id: 'Office', value.id: '5'}),
        RowData(id: 'r4', cells: {category.id: 'Travel', value.id: '40'}),
        RowData(id: 'r5', cells: {category.id: 'Misc', value.id: '7'}),
        RowData(id: 'r6', cells: {category.id: 'Empty'}),
      ];

  test('aggregates groups by category', () {
    final sum = buildSeries(
      rows: rows(),
      category: category,
      value: value,
      aggregation: Aggregation.sum,
      limit: 20,
    );
    expect(sum.groups.first.label, 'Travel');
    expect(sum.groups.first.value, 40);
    expect(sum.groups.length, 4);
    expect(
      sum.groups.firstWhere((group) => group.label == 'Food').value,
      30,
    );

    final average = buildSeries(
      rows: rows(),
      category: category,
      value: value,
      aggregation: Aggregation.average,
      limit: 20,
    );
    expect(
      average.groups.firstWhere((group) => group.label == 'Food').value,
      15,
    );

    final count = buildSeries(
      rows: rows(),
      category: category,
      value: null,
      aggregation: Aggregation.count,
      limit: 20,
    );
    expect(count.totalGroups, 5);
    expect(count.groups.first.value, 2);
    expect(
      count.groups.firstWhere((group) => group.label == 'Empty').value,
      1,
    );
  });

  test('merges the remainder into an Other group', () {
    final series = buildSeries(
      rows: rows(),
      category: category,
      value: value,
      aggregation: Aggregation.sum,
      limit: 3,
    );
    expect(series.truncated, isTrue);
    expect(series.groups.length, 3);
    expect(series.groups.last.label, startsWith('Other'));
    expect(series.groups.last.value, 5 + 7 + 0);
  });

  test('orders line data by category label', () {
    final series = buildSeries(
      rows: rows(),
      category: category,
      value: value,
      aggregation: Aggregation.sum,
      limit: 20,
      orderByLabel: true,
    );
    expect(series.groups.first.label, 'Food');
    expect(series.groups.last.label, 'Travel');
  });

  test('summarizes numeric values', () {
    final summary = summarizeNumeric(rows(), value);
    expect(summary.numericCount, 5);
    expect(summary.sum, 82);
    expect(summary.average, closeTo(16.4, 0.0001));
    expect(summary.min, 5);
    expect(summary.max, 40);
  });

  test('axis scale includes zero and data range', () {
    final positive = buildAxisScale(0, 82);
    expect(positive.min, 0);
    expect(positive.max, greaterThanOrEqualTo(82));
    expect(positive.ticks.first, 0);
    expect(positive.ticks.last, positive.max);

    final negative = buildAxisScale(-25, 40);
    expect(negative.min, lessThanOrEqualTo(-25));
    expect(negative.max, greaterThanOrEqualTo(40));
    expect(negative.ticks.any((tick) => tick == 0), isTrue);
  });
}
