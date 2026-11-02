class ParsedCsv {
  const ParsedCsv({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  int get width => headers.length;
  int get length => rows.length;
}

ParsedCsv? parseCsv(String input) {
  var text = input;
  if (text.startsWith('\uFEFF')) text = text.substring(1);
  if (text.trim().isEmpty) return null;

  final delimiter = _detectDelimiter(text);
  final records = _parseRecords(text, delimiter)
      .where((record) => record.any((cell) => cell.trim().isNotEmpty))
      .toList();
  if (records.isEmpty) return null;

  var headers = records.first.map((cell) => cell.trim()).toList();
  while (headers.isNotEmpty && headers.last.isEmpty) {
    headers.removeLast();
  }
  if (headers.isEmpty) return null;
  headers = _uniqueHeaders(headers);

  final width = headers.length;
  final rows = <List<String>>[];
  for (final record in records.skip(1)) {
    rows.add(List<String>.generate(
      width,
      (index) => index < record.length ? record[index] : '',
    ));
  }
  return ParsedCsv(headers: headers, rows: rows);
}

String buildCsv(List<String> headers, List<List<String>> rows) {
  final lines = <String>[
    headers.map(_escape).join(','),
    ...rows.map((row) => row.map(_escape).join(',')),
  ];
  return lines.join('\n');
}

String _escape(String value) {
  if (value.contains(RegExp('[,"\r\n]'))) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

List<String> _uniqueHeaders(List<String> headers) {
  final seen = <String, int>{};
  final result = <String>[];
  for (var i = 0; i < headers.length; i++) {
    final base = headers[i].isEmpty ? 'Column ${i + 1}' : headers[i];
    final count = seen[base] ?? 0;
    seen[base] = count + 1;
    result.add(count == 0 ? base : '$base ($count)');
  }
  return result;
}

String _detectDelimiter(String text) {
  final lines = text.split('\n').take(5).join('\n');
  var commas = 0;
  var tabs = 0;
  var semicolons = 0;
  var inQuotes = false;
  for (var i = 0; i < lines.length; i++) {
    final char = lines[i];
    if (char == '"') {
      inQuotes = !inQuotes;
    } else if (!inQuotes) {
      switch (char) {
        case ',':
          commas++;
        case '\t':
          tabs++;
        case ';':
          semicolons++;
      }
    }
  }
  if (tabs > commas && tabs >= semicolons) return '\t';
  if (semicolons > commas) return ';';
  return ',';
}

List<List<String>> _parseRecords(String text, String delimiter) {
  final records = <List<String>>[];
  var fields = <String>[];
  final field = StringBuffer();
  var inQuotes = false;

  void endField() {
    fields.add(field.toString());
    field.clear();
  }

  void endRecord() {
    endField();
    records.add(fields);
    fields = <String>[];
  }

  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (inQuotes) {
      if (char == '"') {
        final nextIsQuote = i + 1 < text.length && text[i + 1] == '"';
        if (nextIsQuote) {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(char);
      }
      continue;
    }
    if (char == '"' && field.isEmpty) {
      inQuotes = true;
    } else if (char == delimiter) {
      endField();
    } else if (char == '\r') {
      if (i + 1 < text.length && text[i + 1] == '\n') i++;
      endRecord();
    } else if (char == '\n') {
      endRecord();
    } else {
      field.write(char);
    }
  }
  if (field.isNotEmpty || fields.isNotEmpty) endRecord();
  return records;
}
