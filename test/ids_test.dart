import 'package:easytables/utils/ids.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generated ids are unique across prefixes', () {
    final ids = <String>{
      for (var index = 0; index < 10000; index++)
        newId(index.isEven ? 't_' : 'r_'),
    };
    expect(ids.length, 10000);
  });
}
