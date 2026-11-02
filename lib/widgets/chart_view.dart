import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/table_data.dart';
import '../theme.dart';
import '../utils/chart_data.dart';
import '../utils/currencies.dart';
import '../utils/values.dart';
import 'chart_painters.dart';

enum ChartKind { bar, line, donut }

class ChartView extends StatefulWidget {
  const ChartView({
    super.key,
    required this.table,
    required this.rows,
    required this.query,
  });

  final TableData table;
  final List<RowData> rows;
  final String query;

  @override
  State<ChartView> createState() => _ChartViewState();
}

class _ChartViewState extends State<ChartView> {
  ChartKind _kind = ChartKind.bar;
  Aggregation _aggregation = Aggregation.sum;
  String? _categoryId;
  String? _valueId;

  List<ColumnDef> get _numericColumns => widget.table.columns
      .where(
        (column) =>
            column.type == ColumnType.number ||
            column.type == ColumnType.currency,
      )
      .toList();

  @override
  void initState() {
    super.initState();
    _ensureSelections();
  }

  @override
  void didUpdateWidget(covariant ChartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureSelections();
  }

  void _ensureSelections() {
    final columns = widget.table.columns;
    if (columns.isEmpty) {
      _categoryId = null;
      _valueId = null;
      _aggregation = Aggregation.count;
      return;
    }
    if (widget.table.columnById(_categoryId) == null) {
      _categoryId = _defaultCategoryId();
    }
    final numeric = _numericColumns;
    final currentValue = widget.table.columnById(_valueId);
    if (currentValue == null || currentValue.type != ColumnType.number) {
      _valueId = numeric.isNotEmpty ? numeric.first.id : null;
    }
    if (numeric.isEmpty && _aggregation != Aggregation.count) {
      _aggregation = Aggregation.count;
    }
  }

  String _defaultCategoryId() {
    final columns = widget.table.columns;
    final candidates = columns
        .where(
          (column) =>
              column.type != ColumnType.number &&
              column.type != ColumnType.currency,
        )
        .toList();
    if (candidates.isEmpty) return columns.first.id;

    String? bestId;
    var bestDistinct = 0;
    var bestAverageLength = double.infinity;
    var bestIsDate = false;
    for (final column in candidates) {
      final distinct = <String>{};
      var totalLength = 0;
      for (final row in widget.table.rows) {
        final value = (row.cells[column.id] ?? '').trim();
        if (value.isEmpty) continue;
        distinct.add(value.toLowerCase());
        totalLength += value.length;
      }
      if (distinct.isEmpty) continue;
      final isDate = column.type == ColumnType.date;
      final averageLength = totalLength / distinct.length;
      final useful = distinct.length >= 2;
      final bestUseful = bestDistinct >= 2;
      var better = bestId == null;
      if (!better) {
        if (useful && !bestUseful) {
          better = true;
        } else if (useful == bestUseful) {
          if (distinct.length < bestDistinct) {
            better = true;
          } else if (distinct.length == bestDistinct) {
            if (bestIsDate && !isDate) {
              better = true;
            } else if (isDate == bestIsDate &&
                averageLength < bestAverageLength) {
              better = true;
            }
          }
        }
      }
      if (better) {
        bestId = column.id;
        bestDistinct = distinct.length;
        bestAverageLength = averageLength;
        bestIsDate = isDate;
      }
    }
    return bestId ?? candidates.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final columns = widget.table.columns;
    if (columns.isEmpty) {
      return Container(
        decoration: panelDecoration(context),
        child: _ChartMessage(
          icon: Icons.view_column_outlined,
          title: l10n.chartNothingToVisualize,
          message: l10n.chartNothingToVisualizeMessage,
        ),
      );
    }

    final category = widget.table.columnById(_categoryId);
    final value = widget.table.columnById(_valueId);
    final chartRows = value != null && value.type == ColumnType.currency
        ? convertCurrencyColumn(widget.rows, value)
        : widget.rows;
    final isLine = _kind == ChartKind.line;
    final series = category == null
        ? const ChartSeries(
            groups: <ChartGroup>[],
            rowCount: 0,
            totalGroups: 0,
            truncated: false,
          )
        : buildSeries(
            rows: chartRows,
            category: category,
            value: value,
            aggregation: _aggregation,
            limit: isLine ? 60 : 12,
            orderByLabel: isLine,
            mergeRemainder: !isLine,
            otherLabel: l10n.chartOther,
          );

    NumericSummary? summary;
    if (value != null && _aggregation != Aggregation.count) {
      summary = summarizeNumeric(chartRows, value);
    }

    final hasNegative =
        series.groups.any((group) => group.value < 0);
    _ChartIssue? issue;
    if (widget.rows.isEmpty) {
      issue = _ChartIssue(
        icon: widget.query.trim().isEmpty
            ? Icons.table_rows_outlined
            : Icons.search_off_rounded,
        title: widget.query.trim().isEmpty
            ? l10n.chartNoRows
            : l10n.chartNoRowsFilter,
        message: widget.query.trim().isEmpty
            ? l10n.chartNoRowsMessage
            : l10n.chartNoRowsFilterMessage,
      );
    } else if (category == null) {
      issue = _ChartIssue(
        icon: Icons.category_outlined,
        title: l10n.chartChooseCategory,
        message: l10n.chartChooseCategoryMessage,
      );
    } else if (series.isEmpty) {
      if (summary != null && !summary.hasNumbers) {
        issue = _ChartIssue(
          icon: Icons.numbers_rounded,
          title: l10n.chartNoNumeric,
          message: l10n.chartNoNumericMessage(
            value?.name ?? l10n.chooseColumn,
          ),
        );
      } else {
        issue = _ChartIssue(
          icon: Icons.filter_alt_off_outlined,
          title: l10n.chartNothingToChart,
          message: l10n.chartNothingToChartMessage,
        );
      }
    } else if (_kind == ChartKind.donut && hasNegative) {
      issue = _ChartIssue(
        icon: Icons.pie_chart_outline_rounded,
        title: l10n.chartDonutPositive,
        message: l10n.chartDonutPositiveMessage,
      );
    } else if (_kind == ChartKind.donut && series.total <= 0) {
      issue = _ChartIssue(
        icon: Icons.pie_chart_outline_rounded,
        title: l10n.chartNothingToChart,
        message: l10n.chartZeroMessage,
      );
    }

    final title = _titleFor(category, value, l10n);
    final subtitle = l10n.chartSubtitle(
      widget.rows.length,
      series.groups.length,
      widget.query.trim().isNotEmpty,
    );

    return Column(
      children: [
        _buildControls(context, scheme),
        const SizedBox(height: 14),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: panelDecoration(context),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (issue == null) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: _buildStats(series, value, summary),
                  ),
                ],
                const SizedBox(height: 14),
                Expanded(
                  child: issue != null
                      ? _ChartMessage(
                          icon: issue.icon,
                          title: issue.title,
                          message: issue.message,
                        )
                      : _buildChartBody(series, scheme),
                ),
                if (issue == null && series.truncated) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _kind == ChartKind.line
                              ? l10n.chartLineTruncated(
                                  series.groups.length,
                                  series.totalGroups,
                                )
                              : l10n.chartOtherTruncated(
                                  series.groups.length - 1,
                                  series.totalGroups -
                                      (series.groups.length - 1),
                                ),
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _titleFor(
    ColumnDef? category,
    ColumnDef? value,
    AppLocalizations l10n,
  ) {
    if (category == null) return l10n.chartsView;
    if (_aggregation == Aggregation.count) {
      return l10n.chartCountTitle(category.name);
    }
    return l10n.chartAggregateTitle(
      _aggregationLabel(l10n, _aggregation),
      value?.name ?? l10n.chooseColumn,
      category.name,
    );
  }

  String _aggregationLabel(
    AppLocalizations l10n,
    Aggregation aggregation,
  ) {
    switch (aggregation) {
      case Aggregation.sum:
        return l10n.aggregationSum;
      case Aggregation.average:
        return l10n.aggregationAverage;
      case Aggregation.count:
        return l10n.aggregationCount;
      case Aggregation.min:
        return l10n.aggregationMin;
      case Aggregation.max:
        return l10n.aggregationMax;
    }
  }

  String _formatValue(double? value, ColumnDef? column) {
    if (value == null) return '—';
    if (column?.type == ColumnType.currency) {
      return formatCurrency(value, column!.currencyCode);
    }
    return formatNumber(value);
  }

  List<Widget> _buildStats(
    ChartSeries series,
    ColumnDef? value,
    NumericSummary? summary,
  ) {
    final l10n = context.l10n;
    if (_aggregation == Aggregation.count || value == null) {
      final groups = series.totalGroups;
      final largest = series.groups.isEmpty
          ? null
          : series.groups
              .map((group) => group.value)
              .reduce(math.max);
      final average = series.totalGroups == 0
          ? null
          : series.rowCount / series.totalGroups;
      return [
        _StatCard(
          label: l10n.rowsStatLabel,
          value: formatNumber(series.rowCount.toDouble()),
        ),
        _StatCard(label: l10n.groupsStatLabel, value: '$groups'),
        _StatCard(
          label: l10n.largestGroup,
          value: largest == null ? '—' : formatNumber(largest),
        ),
        _StatCard(
          label: l10n.avgPerGroup,
          value: average == null ? '—' : formatNumber(average),
        ),
      ];
    }
    return [
      _StatCard(
        label: l10n.rowsStatLabel,
        value: formatNumber(series.rowCount.toDouble()),
      ),
      _StatCard(
        label: l10n.sumStat,
        value: _formatValue(summary?.sum, value),
      ),
      _StatCard(
        label: l10n.averageStat,
        value: _formatValue(summary?.average, value),
      ),
      _StatCard(
        label: l10n.maxStat,
        value: _formatValue(summary?.max, value),
      ),
    ];
  }

  Widget _buildChartBody(ChartSeries series, ColorScheme scheme) {
    final style = ChartStyle(
      gridColor: scheme.outlineVariant.withValues(alpha: 0.55),
      axisColor: scheme.outline.withValues(alpha: 0.8),
      labelColor: scheme.onSurfaceVariant,
      valueColor: scheme.onSurface,
      surfaceColor: scheme.surface,
      palette: chartPalette,
    );
    switch (_kind) {
      case ChartKind.bar:
        return SizedBox.expand(
          child: CustomPaint(
            painter: BarChartPainter(groups: series.groups, style: style),
          ),
        );
      case ChartKind.line:
        return SizedBox.expand(
          child: CustomPaint(
            painter: LineChartPainter(groups: series.groups, style: style),
          ),
        );
      case ChartKind.donut:
        return _buildDonut(series, style);
    }
  }

  Widget _buildDonut(ChartSeries series, ChartStyle style) {
    final l10n = context.l10n;
    final value = widget.table.columnById(_valueId);
    final useCurrency =
        value?.type == ColumnType.currency &&
        _aggregation != Aggregation.count;
    String valueFormatter(double amount) {
      if (useCurrency) {
        return formatCurrency(amount, value!.currencyCode);
      }
      return formatNumber(amount);
    }

    final showPercent = _aggregation == Aggregation.sum ||
        _aggregation == Aggregation.count;
    final legend = _DonutLegend(
      groups: series.groups,
      total: series.total,
      showPercent: showPercent,
      palette: chartPalette,
      valueFormatter: valueFormatter,
    );

    String centerLabel;
    String centerValue;
    if (_aggregation == Aggregation.count) {
      centerLabel = l10n.rowsStatLabel;
      centerValue = formatNumber(series.total);
    } else if (_aggregation == Aggregation.sum) {
      centerLabel = l10n.totalLabel;
      centerValue = useCurrency
          ? formatCurrency(series.total, value!.currencyCode)
          : formatNumber(series.total);
    } else {
      centerLabel = l10n.groupsStatLabel;
      centerValue = '${series.groups.length}';
    }

    final painter = DonutChartPainter(
      groups: series.groups,
      style: style,
      centerLabel: centerLabel,
      centerValue: centerValue,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 660;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: CustomPaint(painter: painter)),
              const SizedBox(width: 26),
              SizedBox(
                width: math.min(300, constraints.maxWidth * 0.34),
                child: Scrollbar(
                  child: SingleChildScrollView(child: legend),
                ),
              ),
            ],
          );
        }
        final chartHeight =
            math.min(260.0, constraints.maxHeight * 0.62);
        return Column(
          children: [
            SizedBox(
              height: chartHeight,
              width: double.infinity,
              child: CustomPaint(painter: painter),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Scrollbar(
                child: SingleChildScrollView(child: legend),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls(BuildContext context, ColorScheme scheme) {
    final l10n = context.l10n;
    final numeric = _numericColumns;
    return Container(
      width: double.infinity,
      decoration: panelDecoration(context, radius: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          _LabeledControl(
            label: l10n.chartType,
            child: SegmentedButton<ChartKind>(
              segments: [
                ButtonSegment(
                  value: ChartKind.bar,
                  icon: const Icon(Icons.bar_chart_rounded, size: 17),
                  label: Text(l10n.chartBar),
                ),
                ButtonSegment(
                  value: ChartKind.line,
                  icon: const Icon(Icons.show_chart_rounded, size: 17),
                  label: Text(l10n.chartLine),
                ),
                ButtonSegment(
                  value: ChartKind.donut,
                  icon: const Icon(Icons.pie_chart_outline_rounded, size: 17),
                  label: Text(l10n.chartDonut),
                ),
              ],
              selected: {_kind},
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onSelectionChanged: (selection) {
                setState(() => _kind = selection.first);
              },
            ),
          ),
          _LabeledDropdown<String>(
            label: l10n.categoryAxis,
            width: 196,
            value: _categoryId,
            items: [
              for (final column in widget.table.columns)
                DropdownMenuItem(
                  value: column.id,
                  child: Text(
                    column.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _categoryId = value);
            },
          ),
          _LabeledDropdown<String>(
            label: l10n.valueAxis,
            width: 196,
            value: _aggregation == Aggregation.count ? null : _valueId,
            hint: numeric.isEmpty
                ? l10n.noNumberColumns
                : (_aggregation == Aggregation.count
                    ? l10n.notUsedForCount
                    : l10n.chooseColumn),
            items: [
              for (final column in numeric)
                DropdownMenuItem(
                  value: column.id,
                  child: Text(
                    column.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _aggregation == Aggregation.count
                ? null
                : (value) {
                    if (value != null) setState(() => _valueId = value);
                  },
          ),
          _LabeledDropdown<Aggregation>(
            label: l10n.aggregate,
            width: 146,
            value: _aggregation,
            items: [
              for (final aggregation in Aggregation.values)
                DropdownMenuItem(
                  value: aggregation,
                  enabled:
                      aggregation == Aggregation.count || numeric.isNotEmpty,
                  child: Text(_aggregationLabel(l10n, aggregation)),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _aggregation = value);
            },
          ),
        ],
      ),
    );
  }
}

class _ChartIssue {
  const _ChartIssue({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;
}

class _LabeledControl extends StatelessWidget {
  const _LabeledControl({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 1, bottom: 5),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.width,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final double width;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onChanged != null && items.isNotEmpty;
    return _LabeledControl(
      label: label,
      child: SizedBox(
        width: width,
        height: 42,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: enabled
                ? scheme.surfaceContainerLowest
                : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              isDense: true,
              borderRadius: BorderRadius.circular(12),
              menuMaxHeight: 340,
              icon: Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              hint: Text(
                hint ?? context.l10n.chooseColumn,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              style: TextStyle(
                fontSize: 12.5,
                color: enabled ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
              onChanged: enabled ? onChanged : null,
              items: items,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutLegend extends StatelessWidget {
  const _DonutLegend({
    required this.groups,
    required this.total,
    required this.showPercent,
    required this.palette,
    required this.valueFormatter,
  });

  final List<ChartGroup> groups;
  final double total;
  final bool showPercent;
  final List<Color> palette;
  final String Function(double value) valueFormatter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < groups.length; index++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: palette[index % palette.length],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    groups[index].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  valueFormatter(groups[index].value),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                if (showPercent && total > 0) ...[
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 42,
                    child: Text(
                      '${(groups[index].value / total * 100).toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ChartMessage extends StatelessWidget {
  const _ChartMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Icon(
                icon,
                size: 24,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
