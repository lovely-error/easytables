import '../models/table_data.dart';

final RegExp _numberNoise = RegExp(r'[\s\u00A0$\u20AC\u00A3\u00A5\u20BD]');

final RegExp _isoDateTime = RegExp(
  r'^(\d{4})-(\d{1,2})-(\d{1,2})'
  r'(?:[T ](\d{1,2}):(\d{2})(?::(\d{2})(?:\.(\d{1,6}))?)?'
  r'(Z|[+-]\d{2}:?\d{2})?)?$',
);

double? parseNumber(String? raw) {
  if (raw == null) return null;
  var text = raw.trim();
  if (text.isEmpty) return null;
  final isPercent = text.endsWith('%');
  if (isPercent) text = text.substring(0, text.length - 1);
  text = text
      .replaceAll(_numberNoise, '')
      .replaceAll(',', '')
      .replaceAll('\u2212', '-');
  final value = double.tryParse(text);
  if (value == null || !value.isFinite) return null;
  return isPercent ? value / 100 : value;
}

DateTime? parseDate(String? raw) {
  if (raw == null) return null;
  final text = raw.trim();
  if (text.isEmpty) return null;
  final match = _isoDateTime.firstMatch(text);
  if (match == null) return null;

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (month < 1 || month > 12) return null;
  final daysInMonth = DateTime.utc(year, month + 1, 0).day;
  if (day < 1 || day > daysInMonth) return null;

  final hourText = match.group(4);
  final minuteText = match.group(5);
  final secondText = match.group(6);
  final fractionText = match.group(7);
  final zoneText = match.group(8);
  final hour = hourText == null ? 0 : int.parse(hourText);
  final minute = minuteText == null ? 0 : int.parse(minuteText);
  final second = secondText == null ? 0 : int.parse(secondText);
  if (hour > 23 || minute > 59 || second > 59) return null;
  final microsecond = fractionText == null
      ? 0
      : int.parse(fractionText.padRight(6, '0'));

  if (zoneText == null) {
    return DateTime(year, month, day, hour, minute, second, 0, microsecond);
  }
  final base = DateTime.utc(
    year,
    month,
    day,
    hour,
    minute,
    second,
    0,
    microsecond,
  );
  if (zoneText == 'Z') return base;
  final sign = zoneText.startsWith('-') ? -1 : 1;
  final digits = zoneText.substring(1).replaceAll(':', '');
  final offsetHours = int.parse(digits.substring(0, 2));
  final offsetMinutes = int.parse(digits.substring(2));
  if (offsetHours > 23 || offsetMinutes > 59) return null;
  return base.subtract(
    Duration(hours: sign * offsetHours, minutes: sign * offsetMinutes),
  );
}

bool isInvalidCellValue(
  String? raw,
  ColumnType type, {
  List<String> options = const [],
}) {
  final text = (raw ?? '').trim();
  if (text.isEmpty) return false;
  switch (type) {
    case ColumnType.text:
      return false;
    case ColumnType.number:
    case ColumnType.currency:
      return parseNumber(text) == null;
    case ColumnType.date:
      return parseDate(text) == null;
    case ColumnType.select:
      return !options.contains(text);
  }
}

int countInvalidColumnCells(TableData table, ColumnDef column) {
  if (column.type == ColumnType.text) return 0;
  var count = 0;
  for (final row in table.rows) {
    if (isInvalidCellValue(
      row.cells[column.id],
      column.type,
      options: column.options,
    )) {
      count++;
    }
  }
  return count;
}

int countInvalidCells(TableData table) {
  var count = 0;
  for (final column in table.columns) {
    count += countInvalidColumnCells(table, column);
  }
  return count;
}

List<String> normalizeOptions(Iterable<String> options) {
  final seen = <String>{};
  final result = <String>[];
  for (final raw in options) {
    final value = raw.trim();
    if (value.isEmpty || !seen.add(value.toLowerCase())) continue;
    result.add(value);
  }
  return result;
}

List<String> distinctColumnValues(TableData table, ColumnDef column) {
  final seen = <String>{};
  final values = <String>[];
  for (final row in table.rows) {
    final value = (row.cells[column.id] ?? '').trim();
    if (value.isEmpty || !seen.add(value.toLowerCase())) continue;
    values.add(value);
  }
  values.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return values;
}

int compareCells(String a, String b, ColumnType type) {
  switch (type) {
    case ColumnType.number:
    case ColumnType.currency:
      final numberA = parseNumber(a);
      final numberB = parseNumber(b);
      if (numberA != null && numberB != null) {
        return numberA.compareTo(numberB);
      }
      if (numberA != null) return -1;
      if (numberB != null) return 1;
      break;
    case ColumnType.date:
      final dateA = parseDate(a);
      final dateB = parseDate(b);
      if (dateA != null && dateB != null) {
        return dateA.compareTo(dateB);
      }
      if (dateA != null) return -1;
      if (dateB != null) return 1;
      break;
    case ColumnType.text:
    case ColumnType.select:
      break;
  }
  return a.trim().toLowerCase().compareTo(b.trim().toLowerCase());
}

bool rowMatches(RowData row, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  for (final value in row.cells.values) {
    if (value.toLowerCase().contains(needle)) return true;
  }
  return false;
}

List<RowData> filterRows(TableData table, String query) {
  if (query.trim().isEmpty) return List<RowData>.of(table.rows);
  return table.rows.where((row) => rowMatches(row, query)).toList();
}

String formatNumber(double value, {int maxDecimals = 2}) {
  if (!value.isFinite) return '\u2014';
  if (value.abs() >= 1e15) {
    return value.toStringAsExponential(2);
  }
  var text = value.toStringAsFixed(maxDecimals);
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
  }
  final negative = text.startsWith('-');
  final unsigned = negative ? text.substring(1) : text;
  final parts = unsigned.split('.');
  final digits = parts.first;
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
    grouped.write(digits[i]);
  }
  final decimals = parts.length > 1 ? '.${parts[1]}' : '';
  return '${negative ? '-' : ''}$grouped$decimals';
}

String formatCompactNumber(double value) {
  if (!value.isFinite) return '\u2014';
  final abs = value.abs();
  if (abs >= 1e9) return '${_trimCompact(value / 1e9)}B';
  if (abs >= 1e6) return '${_trimCompact(value / 1e6)}M';
  if (abs >= 1e3) return '${_trimCompact(value / 1e3)}k';
  return _trimCompact(value);
}

String _trimCompact(double value) {
  var text = value.toStringAsFixed(1);
  if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
  return text;
}

String relativeTime(DateTime time) {
  final difference = DateTime.now().difference(time);
  if (difference.inSeconds < 45) return 'just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 30) return '${difference.inDays}d ago';
  final day = time.day.toString().padLeft(2, '0');
  final month = time.month.toString().padLeft(2, '0');
  return '$day.$month.${time.year}';
}
