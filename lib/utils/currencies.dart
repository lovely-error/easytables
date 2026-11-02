import '../models/table_data.dart';
import 'values.dart';

class AppCurrency {
  const AppCurrency(this.code, this.symbol);

  final String code;
  final String symbol;
}

const List<AppCurrency> appCurrencies = [
  AppCurrency('USD', r'$'),
  AppCurrency('EUR', '€'),
  AppCurrency('GBP', '£'),
  AppCurrency('RUB', '₽'),
  AppCurrency('KGS', 'сом'),
  AppCurrency('KZT', '₸'),
  AppCurrency('UAH', '₴'),
  AppCurrency('TRY', '₺'),
  AppCurrency('JPY', '¥'),
  AppCurrency('CNY', '¥'),
  AppCurrency('INR', '₹'),
  AppCurrency('CHF', 'CHF'),
  AppCurrency('CAD', r'C$'),
  AppCurrency('AUD', r'A$'),
];

AppCurrency currencyFor(String code) {
  for (final currency in appCurrencies) {
    if (currency.code == code) return currency;
  }
  return appCurrencies.first;
}

String currencySymbol(String code) => currencyFor(code).symbol;

String defaultCurrencyCode(bool isRussian) => isRussian ? 'RUB' : 'USD';

String formatCurrency(double value, String code, {int maxDecimals = 2}) {
  final currency = currencyFor(code);
  final formatted = formatNumber(value, maxDecimals: maxDecimals);
  final negative = formatted.startsWith('-');
  final unsigned = negative ? formatted.substring(1) : formatted;
  final separator = currency.symbol.length > 1 ? ' ' : '';
  return '${negative ? '-' : ''}${currency.symbol}$separator$unsigned';
}

const Map<String, double> _usdPerUnit = {
  'USD': 1.0,
  'EUR': 1.08,
  'GBP': 1.27,
  'RUB': 0.011,
  'KGS': 0.0115,
  'KZT': 0.002,
  'UAH': 0.024,
  'TRY': 0.029,
  'JPY': 0.0065,
  'CNY': 0.138,
  'INR': 0.012,
  'CHF': 1.12,
  'CAD': 0.73,
  'AUD': 0.66,
};

double convertCurrency(
  double amount, {
  required String from,
  required String to,
}) {
  final fromCode = currencyFor(from).code;
  final toCode = currencyFor(to).code;
  if (fromCode == toCode) return amount;
  final fromRate = _usdPerUnit[fromCode] ?? 1;
  final toRate = _usdPerUnit[toCode] ?? 1;
  return amount * fromRate / toRate;
}

int compareCurrencyRows(RowData a, RowData b, ColumnDef column) {
  final aRaw = (a.cells[column.id] ?? '').trim();
  final bRaw = (b.cells[column.id] ?? '').trim();
  final aNumber = parseNumber(aRaw);
  final bNumber = parseNumber(bRaw);
  if (aNumber == null && bNumber == null) {
    return aRaw.toLowerCase().compareTo(bRaw.toLowerCase());
  }
  if (aNumber == null) return 1;
  if (bNumber == null) return -1;
  final aValue = convertCurrency(
    aNumber,
    from: a.currencyFor(column),
    to: column.currencyCode,
  );
  final bValue = convertCurrency(
    bNumber,
    from: b.currencyFor(column),
    to: column.currencyCode,
  );
  return aValue.compareTo(bValue);
}

List<RowData> convertCurrencyColumn(
  Iterable<RowData> rows,
  ColumnDef column,
) {
  if (column.type != ColumnType.currency) {
    return List<RowData>.of(rows);
  }
  final result = <RowData>[];
  for (final row in rows) {
    final cells = Map<String, String>.from(row.cells);
    final raw = cells[column.id];
    if (raw != null) {
      final amount = parseNumber(raw);
      if (amount != null) {
        cells[column.id] = convertCurrency(
          amount,
          from: row.currencyFor(column),
          to: column.currencyCode,
        ).toString();
      }
    }
    final currencies = Map<String, String>.from(row.currencies)
      ..remove(column.id);
    result.add(
      RowData(id: row.id, cells: cells, currencies: currencies),
    );
  }
  return result;
}
