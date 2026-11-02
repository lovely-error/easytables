import 'package:easytables/utils/csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a simple csv', () {
    final parsed = parseCsv('Name,Amount\nCoffee,4.5\nTea,3\n');
    expect(parsed, isNotNull);
    expect(parsed!.headers, ['Name', 'Amount']);
    expect(parsed.rows.length, 2);
    expect(parsed.rows.first, ['Coffee', '4.5']);
  });

  test('handles quoted commas, quotes, and newlines', () {
    final parsed = parseCsv('Name,Notes\n"Smith, John","Said ""hi""\nand left"');
    expect(parsed, isNotNull);
    expect(parsed!.rows.single[0], 'Smith, John');
    expect(parsed.rows.single[1], 'Said "hi"\nand left');
  });

  test('detects tab separated text', () {
    final parsed = parseCsv('A\tB\tC\n1\t2\t3');
    expect(parsed, isNotNull);
    expect(parsed!.headers, ['A', 'B', 'C']);
    expect(parsed.rows.single, ['1', '2', '3']);
  });

  test('detects semicolon separated text', () {
    final parsed = parseCsv('A;B\n1;2');
    expect(parsed, isNotNull);
    expect(parsed!.headers, ['A', 'B']);
  });

  test('uniques duplicate headers', () {
    final parsed = parseCsv('Name,Name\nA,B');
    expect(parsed!.headers, ['Name', 'Name (1)']);
  });

  test('pads ragged rows to the header width', () {
    final parsed = parseCsv('A,B,C\n1,2\n3,4,5,6');
    expect(parsed!.rows, [
      ['1', '2', ''],
      ['3', '4', '5'],
    ]);
  });

  test('builds and re-parses escaped csv', () {
    final csv = buildCsv(['a', 'b'], [
      ['x,y', 'q"z'],
      ['line\nbreak', ''],
    ]);
    expect(csv, 'a,b\n"x,y","q""z"\n"line\nbreak",');
    final parsed = parseCsv(csv)!;
    expect(parsed.rows.first, ['x,y', 'q"z']);
    expect(parsed.rows.last, ['line\nbreak', '']);
  });

  test('returns null for empty input', () {
    expect(parseCsv(''), isNull);
    expect(parseCsv('   \n\t'), isNull);
  });
}
