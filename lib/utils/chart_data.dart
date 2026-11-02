import 'dart:math' as math;

import '../models/table_data.dart';
import 'values.dart';

enum Aggregation {
  sum('Sum'),
  average('Average'),
  count('Count'),
  min('Min'),
  max('Max');

  const Aggregation(this.label);

  final String label;
}

class ChartGroup {
  const ChartGroup({required this.label, required this.value});

  final String label;
  final double value;
}

class ChartSeries {
  const ChartSeries({
    required this.groups,
    required this.rowCount,
    required this.totalGroups,
    required this.truncated,
  });

  final List<ChartGroup> groups;
  final int rowCount;
  final int totalGroups;
  final bool truncated;

  bool get isEmpty => groups.isEmpty;

  double get total => groups.fold(0, (sum, group) => sum + group.value);
}

class NumericSummary {
  const NumericSummary({
    required this.rowCount,
    required this.numericCount,
    required this.sum,
    required this.average,
    required this.min,
    required this.max,
  });

  final int rowCount;
  final int numericCount;
  final double? sum;
  final double? average;
  final double? min;
  final double? max;

  bool get hasNumbers => numericCount > 0;
}

class _Bucket {
  int rows = 0;
  int numeric = 0;
  double sum = 0;
  double min = 0;
  double max = 0;

  void add(double? value) {
    rows++;
    if (value == null) return;
    if (numeric == 0) {
      min = value;
      max = value;
    } else {
      min = math.min(min, value);
      max = math.max(max, value);
    }
    numeric++;
    sum += value;
  }

  void merge(_Bucket other) {
    rows += other.rows;
    final hadValues = numeric > 0;
    numeric += other.numeric;
    if (other.numeric > 0) {
      if (!hadValues) {
        min = other.min;
        max = other.max;
      } else {
        min = math.min(min, other.min);
        max = math.max(max, other.max);
      }
    }
    sum += other.sum;
  }

  double? valueFor(Aggregation aggregation) {
    switch (aggregation) {
      case Aggregation.count:
        return rows.toDouble();
      case Aggregation.sum:
        return numeric == 0 ? null : sum;
      case Aggregation.average:
        return numeric == 0 ? null : sum / numeric;
      case Aggregation.min:
        return numeric == 0 ? null : min;
      case Aggregation.max:
        return numeric == 0 ? null : max;
    }
  }
}

ChartSeries buildSeries({
  required List<RowData> rows,
  required ColumnDef category,
  required ColumnDef? value,
  required Aggregation aggregation,
  int limit = 12,
  bool orderByLabel = false,
  bool mergeRemainder = true,
  String otherLabel = 'Other',
}) {
  final useValues = aggregation != Aggregation.count && value != null;
  final buckets = <String, _Bucket>{};
  var considered = 0;

  for (final row in rows) {
    final rawLabel = (row.cells[category.id] ?? '').trim();
    final label = rawLabel.isEmpty ? '(empty)' : rawLabel;
    final bucket = buckets.putIfAbsent(label, _Bucket.new);
    final numeric = useValues ? parseNumber(row.cells[value.id]) : null;
    bucket.add(numeric);
    considered++;
  }

  var entries = buckets.entries
      .where((entry) => entry.value.valueFor(aggregation) != null)
      .toList();

  entries.sort((a, b) {
    if (orderByLabel) {
      final aLabel = a.key == '(empty)' ? '' : a.key;
      final bLabel = b.key == '(empty)' ? '' : b.key;
      return compareCells(aLabel, bLabel, category.type);
    }
    final aValue = a.value.valueFor(aggregation) ?? 0;
    final bValue = b.value.valueFor(aggregation) ?? 0;
    return bValue.compareTo(aValue);
  });

  final totalGroups = entries.length;
  var truncated = false;
  if (entries.length > limit) {
    truncated = true;
    if (mergeRemainder) {
      final keep = entries.take(limit - 1).toList();
      final rest = entries.skip(limit - 1).toList();
      final merged = _Bucket();
      for (final entry in rest) {
        merged.merge(entry.value);
      }
      entries = [
        ...keep,
        MapEntry('$otherLabel (${rest.length})', merged),
      ];
    } else {
      entries = entries.take(limit).toList();
    }
  }

  return ChartSeries(
    groups: [
      for (final entry in entries)
        ChartGroup(
          label: entry.key,
          value: entry.value.valueFor(aggregation) ?? 0,
        ),
    ],
    rowCount: considered,
    totalGroups: totalGroups,
    truncated: truncated,
  );
}

NumericSummary summarizeNumeric(List<RowData> rows, ColumnDef? column) {
  var count = 0;
  var sum = 0.0;
  double? min;
  double? max;
  if (column != null) {
    for (final row in rows) {
      final value = parseNumber(row.cells[column.id]);
      if (value == null) continue;
      count++;
      sum += value;
      min = min == null ? value : math.min(min, value);
      max = max == null ? value : math.max(max, value);
    }
  }
  return NumericSummary(
    rowCount: rows.length,
    numericCount: count,
    sum: count == 0 ? null : sum,
    average: count == 0 ? null : sum / count,
    min: min,
    max: max,
  );
}

class AxisScale {
  const AxisScale({required this.min, required this.max, required this.ticks});

  final double min;
  final double max;
  final List<double> ticks;
}

AxisScale buildAxisScale(double dataMin, double dataMax) {
  var minValue = math.min(0, dataMin);
  var maxValue = math.max(0, dataMax);
  if (!minValue.isFinite || !maxValue.isFinite) {
    minValue = 0;
    maxValue = 1;
  }
  if (minValue == maxValue) {
    maxValue = minValue == 0 ? 1 : minValue.abs();
    minValue = math.min(0, minValue);
  }
  final range = maxValue - minValue;
  final roughStep = range / 4;
  final magnitude =
      math.pow(10, (math.log(roughStep) / math.ln10).floor()).toDouble();
  final normalized = roughStep / magnitude;
  final double step;
  if (normalized <= 1) {
    step = magnitude;
  } else if (normalized <= 2) {
    step = 2 * magnitude;
  } else if (normalized <= 2.5) {
    step = 2.5 * magnitude;
  } else if (normalized <= 5) {
    step = 5 * magnitude;
  } else {
    step = 10 * magnitude;
  }

  final niceMin = (minValue / step).floor() * step;
  final niceMax = (maxValue / step).ceil() * step;
  final ticks = <double>[];
  final count = ((niceMax - niceMin) / step).round();
  for (var i = 0; i <= count; i++) {
    ticks.add(niceMin + i * step);
  }
  return AxisScale(min: niceMin, max: niceMax, ticks: ticks);
}
