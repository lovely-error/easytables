import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/table_data.dart';
import '../theme.dart';
import '../utils/currencies.dart';
import '../utils/values.dart';
import 'date_picker_dialog.dart';
import 'dialogs.dart';

const double _rowNumberWidth = 52;
const double _cellWidth = 220;
const double _tailWidth = 52;
const double _headerHeight = 42;
const double _rowHeight = 44;
const String _columnCurrencyDefault = '__column_currency_default__';

enum _ColumnAction {
  sortAscending,
  sortDescending,
  clearSort,
  rename,
  editOptions,
  editCurrency,
  typeText,
  typeNumber,
  typeDate,
  typeSelect,
  typeCurrency,
  delete,
}

enum _RowAction { duplicate, moveUp, moveDown, delete }

class TableGrid extends StatefulWidget {
  const TableGrid({
    super.key,
    required this.table,
    required this.rows,
    required this.query,
    required this.onClearFilter,
  });

  final TableData table;
  final List<RowData> rows;
  final String query;
  final VoidCallback onClearFilter;

  @override
  State<TableGrid> createState() => _TableGridState();
}

class _TableGridState extends State<TableGrid> {
  final ScrollController _horizontal = ScrollController();
  final ScrollController _vertical = ScrollController();
  String? _sortColumnId;
  bool _ascending = true;

  @override
  void didUpdateWidget(covariant TableGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.table.id != widget.table.id) {
      _sortColumnId = null;
      _ascending = true;
      if (_vertical.hasClients) _vertical.jumpTo(0);
      if (_horizontal.hasClients) _horizontal.jumpTo(0);
    }
    if (_sortColumnId != null &&
        widget.table.columnById(_sortColumnId) == null) {
      _sortColumnId = null;
    }
  }

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  List<RowData> _sortedRows() {
    final indexed = <({RowData row, int index})>[
      for (var i = 0; i < widget.rows.length; i++)
        (row: widget.rows[i], index: i),
    ];
    final column = widget.table.columnById(_sortColumnId);
    if (column == null) {
      return [for (final entry in indexed) entry.row];
    }
    indexed.sort((a, b) {
      final result = column.type == ColumnType.currency
          ? compareCurrencyRows(a.row, b.row, column)
          : compareCells(
              a.row.cells[column.id] ?? '',
              b.row.cells[column.id] ?? '',
              column.type,
            );
      if (result != 0) return _ascending ? result : -result;
      return a.index.compareTo(b.index);
    });
    return [for (final entry in indexed) entry.row];
  }

  void _toggleSort(ColumnDef column) {
    setState(() {
      if (_sortColumnId == column.id) {
        _ascending = !_ascending;
      } else {
        _sortColumnId = column.id;
        _ascending = true;
      }
    });
  }

  Future<void> _handleColumnAction(
    ColumnDef column,
    _ColumnAction action,
  ) async {
    final state = AppScope.read(context);
    final l10n = context.l10n;
    switch (action) {
      case _ColumnAction.sortAscending:
        setState(() {
          _sortColumnId = column.id;
          _ascending = true;
        });
      case _ColumnAction.sortDescending:
        setState(() {
          _sortColumnId = column.id;
          _ascending = false;
        });
      case _ColumnAction.clearSort:
        setState(() => _sortColumnId = null);
      case _ColumnAction.rename:
        final name = await showTextPromptDialog(
          context,
          title: l10n.renameColumn,
          initialValue: column.name,
          labelText: l10n.nameLabel,
          confirmLabel: l10n.rename,
        );
        if (name != null) {
          state.renameColumn(widget.table.id, column.id, name);
        }
      case _ColumnAction.editOptions:
        final options = await showColumnOptionsDialog(
          context,
          initialOptions: column.options,
          title: l10n.optionsFor(column.name),
        );
        if (options != null) {
          state.updateColumnOptions(widget.table.id, column.id, options);
        }
      case _ColumnAction.editCurrency:
        final currency = await showCurrencyPickerDialog(
          context,
          initialCode: column.currencyCode,
        );
        if (currency != null) {
          state.updateColumnCurrency(widget.table.id, column.id, currency);
        }
      case _ColumnAction.typeText:
        state.changeColumnType(
            widget.table.id, column.id, ColumnType.text);
      case _ColumnAction.typeNumber:
        state.changeColumnType(
            widget.table.id, column.id, ColumnType.number);
      case _ColumnAction.typeDate:
        state.changeColumnType(
            widget.table.id, column.id, ColumnType.date);
      case _ColumnAction.typeSelect:
        if (column.type == ColumnType.select) return;
        final initialOptions = column.options.isNotEmpty
            ? column.options
            : distinctColumnValues(widget.table, column);
        final options = await showColumnOptionsDialog(
          context,
          initialOptions: initialOptions,
          title: l10n.optionsFor(column.name),
        );
        if (options != null) {
          state.configureSelectColumn(widget.table.id, column.id, options);
        }
      case _ColumnAction.typeCurrency:
        if (column.type == ColumnType.currency) return;
        final currency = await showCurrencyPickerDialog(
          context,
          initialCode: column.currencyCode,
        );
        if (currency != null) {
          state.configureCurrencyColumn(
            widget.table.id,
            column.id,
            currency,
          );
        }
      case _ColumnAction.delete:
        final confirmed = await showConfirmDialog(
          context,
          title: l10n.deleteColumnTitle,
          message: l10n.deleteColumnMessage(column.name),
          confirmLabel: l10n.delete,
        );
        if (confirmed) {
          state.deleteColumn(widget.table.id, column.id);
        }
    }
  }

  void _addRow({bool scrollToBottom = false}) {
    final state = AppScope.read(context);
    final l10n = context.l10n;
    state.addRow(widget.table.id);
    if (widget.query.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.rowAddedHidden),
          action: SnackBarAction(
            label: l10n.clearFilter,
            onPressed: widget.onClearFilter,
          ),
        ),
      );
      return;
    }
    if (!scrollToBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_vertical.hasClients) return;
      _vertical.animateTo(
        _vertical.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final columns = widget.table.columns;
    if (columns.isEmpty) {
      return Container(
        decoration: panelDecoration(context, radius: 14),
        child: _NoColumnsPanel(table: widget.table),
      );
    }

    final rows = _sortedRows();
    final totalWidth =
        _rowNumberWidth + columns.length * _cellWidth + _tailWidth;

    return Container(
      decoration: panelDecoration(context, radius: 14),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = math.max(totalWidth, constraints.maxWidth);
          return Scrollbar(
            controller: _horizontal,
            thumbVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: _horizontal,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderRow(
                      table: widget.table,
                      sortColumnId: _sortColumnId,
                      ascending: _ascending,
                      onToggleSort: _toggleSort,
                      onColumnAction: _handleColumnAction,
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: scheme.outlineVariant,
                    ),
                    Expanded(child: _buildBody(rows, scheme)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(List<RowData> rows, ColorScheme scheme) {
    if (rows.isEmpty) {
      return _EmptyGrid(
        hasQuery: widget.query.trim().isNotEmpty,
        onAddRow: () => _addRow(scrollToBottom: true),
      );
    }
    return ListView.builder(
      controller: _vertical,
      itemCount: rows.length + 1,
      itemBuilder: (context, index) {
        if (index == rows.length) {
          return _AddRowFooter(
            onTap: () => _addRow(scrollToBottom: true),
          );
        }
        return _GridRow(
          key: ValueKey(rows[index].id),
          table: widget.table,
          row: rows[index],
          index: index,
          sortActive: _sortColumnId != null,
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.table,
    required this.sortColumnId,
    required this.ascending,
    required this.onToggleSort,
    required this.onColumnAction,
  });

  final TableData table;
  final String? sortColumnId;
  final bool ascending;
  final ValueChanged<ColumnDef> onToggleSort;
  final Future<void> Function(ColumnDef, _ColumnAction) onColumnAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: _headerHeight,
      color: scheme.surfaceContainerLow,
      child: Row(
        children: [
          SizedBox(
            width: _rowNumberWidth,
            child: Center(
              child: Text(
                '#',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          for (final column in table.columns)
            _ColumnHeaderCell(
              column: column,
              invalidCount: countInvalidColumnCells(table, column),
              sorted: sortColumnId == column.id,
              ascending: ascending,
              onTap: () => onToggleSort(column),
              onAction: (action) => onColumnAction(column, action),
            ),
          SizedBox(
            width: _tailWidth,
            child: IconButton(
              tooltip: context.l10n.addColumn,
              onPressed: () => showAddColumnFlow(context, table),
              icon: const Icon(Icons.add_rounded, size: 18),
              color: scheme.onSurfaceVariant,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnHeaderCell extends StatelessWidget {
  const _ColumnHeaderCell({
    required this.column,
    required this.invalidCount,
    required this.sorted,
    required this.ascending,
    required this.onTap,
    required this.onAction,
  });

  final ColumnDef column;
  final int invalidCount;
  final bool sorted;
  final bool ascending;
  final VoidCallback onTap;
  final ValueChanged<_ColumnAction> onAction;

  IconData get _typeIcon {
    switch (column.type) {
      case ColumnType.text:
        return Icons.text_fields_rounded;
      case ColumnType.number:
        return Icons.numbers_rounded;
      case ColumnType.date:
        return Icons.event_outlined;
      case ColumnType.select:
        return Icons.expand_more_rounded;
      case ColumnType.currency:
        return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Container(
      width: _cellWidth,
      height: _headerHeight,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Tooltip(
                message: l10n.sortBy(column.name),
                waitDuration: const Duration(milliseconds: 700),
                child: Padding(
                  padding: const EdgeInsets.only(left: 11),
                  child: Row(
                    children: [
                      Icon(
                        _typeIcon,
                        size: 13,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          column.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      if (column.type == ColumnType.currency) ...[
                        const SizedBox(width: 4),
                        Text(
                          column.currencyCode,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: scheme.onSurfaceVariant
                                .withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                      if (invalidCount > 0) ...[
                        const SizedBox(width: 4),
                        Tooltip(
                          message: l10n.errorsCount(invalidCount),
                          child: Icon(
                            Icons.error_outline_rounded,
                            size: 13,
                            color: scheme.error,
                          ),
                        ),
                      ],
                      if (sorted)
                        Icon(
                          ascending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 13,
                          color: scheme.primary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          PopupMenuButton<_ColumnAction>(
            tooltip: l10n.columnOptions,
            position: PopupMenuPosition.under,
            onSelected: onAction,
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: 28,
              height: _headerHeight,
              child: Icon(
                Icons.arrow_drop_down_rounded,
                size: 19,
                color: scheme.onSurfaceVariant,
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ColumnAction.sortAscending,
                child: _MenuRow(
                  icon: Icons.arrow_upward_rounded,
                  label: l10n.sortAscending,
                ),
              ),
              PopupMenuItem(
                value: _ColumnAction.sortDescending,
                child: _MenuRow(
                  icon: Icons.arrow_downward_rounded,
                  label: l10n.sortDescending,
                ),
              ),
              if (sorted)
                PopupMenuItem(
                  value: _ColumnAction.clearSort,
                  child: _MenuRow(
                    icon: Icons.clear_rounded,
                    label: l10n.clearSort,
                  ),
                ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _ColumnAction.rename,
                child: _MenuRow(
                  icon: Icons.edit_outlined,
                  label: l10n.renameColumn,
                ),
              ),
              if (column.type == ColumnType.select)
                PopupMenuItem(
                  value: _ColumnAction.editOptions,
                  child: _MenuRow(
                    icon: Icons.expand_more_rounded,
                    label: l10n.editOptions,
                  ),
                ),
              if (column.type == ColumnType.currency)
                PopupMenuItem(
                  value: _ColumnAction.editCurrency,
                  child: _MenuRow(
                    icon: Icons.payments_outlined,
                    label: l10n.editCurrency,
                  ),
                ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _ColumnAction.typeText,
                child: _TypeMenuRow(
                  label: l10n.columnTypeLabel(ColumnType.text),
                  selected: column.type == ColumnType.text,
                  icon: Icons.text_fields_rounded,
                ),
              ),
              PopupMenuItem(
                value: _ColumnAction.typeNumber,
                child: _TypeMenuRow(
                  label: l10n.columnTypeLabel(ColumnType.number),
                  selected: column.type == ColumnType.number,
                  icon: Icons.numbers_rounded,
                ),
              ),
              PopupMenuItem(
                value: _ColumnAction.typeDate,
                child: _TypeMenuRow(
                  label: l10n.columnTypeLabel(ColumnType.date),
                  selected: column.type == ColumnType.date,
                  icon: Icons.event_outlined,
                ),
              ),
              PopupMenuItem(
                value: _ColumnAction.typeSelect,
                child: _TypeMenuRow(
                  label: l10n.columnTypeLabel(ColumnType.select),
                  selected: column.type == ColumnType.select,
                  icon: Icons.expand_more_rounded,
                ),
              ),
              PopupMenuItem(
                value: _ColumnAction.typeCurrency,
                child: _TypeMenuRow(
                  label: l10n.columnTypeLabel(ColumnType.currency),
                  selected: column.type == ColumnType.currency,
                  icon: Icons.payments_outlined,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _ColumnAction.delete,
                child: _MenuRow(
                  icon: Icons.delete_outline_rounded,
                  label: l10n.deleteColumn,
                  color: scheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class _TypeMenuRow extends StatelessWidget {
  const _TypeMenuRow({
    required this.label,
    required this.selected,
    required this.icon,
  });

  final String label;
  final bool selected;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.7)
            : null,
        borderRadius: BorderRadius.circular(8),
        border: selected
            ? Border.all(color: scheme.primary.withValues(alpha: 0.35))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected)
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 14,
                color: scheme.onPrimary,
              ),
            )
          else
            Icon(icon, size: 17, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridRow extends StatelessWidget {
  const _GridRow({
    super.key,
    required this.table,
    required this.row,
    required this.index,
    required this.sortActive,
  });

  final TableData table;
  final RowData row;
  final int index;
  final bool sortActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final translucentDivider =
        Theme.of(context).dividerColor.withValues(alpha: 0.5);
    final stripe = index.isOdd
        ? scheme.surfaceContainerLow.withValues(alpha: 0.6)
        : Colors.transparent;
    return Container(
      height: _rowHeight,
      decoration: BoxDecoration(
        color: stripe,
        border: Border(bottom: BorderSide(color: translucentDivider)),
      ),
      child: Row(
        children: [
          _RowNumberCell(
            table: table,
            row: row,
            index: index,
            sortActive: sortActive,
          ),
          for (final column in table.columns)
            _EditableCell(
              key: ValueKey('${row.id}:${column.id}'),
              table: table,
              row: row,
              column: column,
            ),
          const SizedBox(width: _tailWidth),
        ],
      ),
    );
  }
}

class _RowNumberCell extends StatelessWidget {
  const _RowNumberCell({
    required this.table,
    required this.row,
    required this.index,
    required this.sortActive,
  });

  final TableData table;
  final RowData row;
  final int index;
  final bool sortActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return SizedBox(
      width: _rowNumberWidth,
      height: _rowHeight,
      child: PopupMenuButton<_RowAction>(
        tooltip: l10n.rowActions,
        position: PopupMenuPosition.under,
        onSelected: (action) {
          final state = AppScope.read(context);
          switch (action) {
            case _RowAction.duplicate:
              state.duplicateRow(table.id, row.id);
            case _RowAction.moveUp:
              state.moveRow(table.id, row.id, -1);
            case _RowAction.moveDown:
              state.moveRow(table.id, row.id, 1);
            case _RowAction.delete:
              state.deleteRow(table.id, row.id);
          }
        },
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _RowAction.duplicate,
            child: _MenuRow(
              icon: Icons.copy_all_outlined,
              label: l10n.duplicateRow,
            ),
          ),
          PopupMenuItem(
            value: _RowAction.moveUp,
            enabled: !sortActive && index > 0,
            child: _MenuRow(
              icon: Icons.arrow_upward_rounded,
              label: l10n.moveUp,
            ),
          ),
          PopupMenuItem(
            value: _RowAction.moveDown,
            enabled: !sortActive,
            child: _MenuRow(
              icon: Icons.arrow_downward_rounded,
              label: l10n.moveDown,
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _RowAction.delete,
            child: _MenuRow(
              icon: Icons.delete_outline_rounded,
              label: l10n.deleteRow,
              color: scheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableCell extends StatefulWidget {
  const _EditableCell({
    super.key,
    required this.table,
    required this.row,
    required this.column,
  });

  final TableData table;
  final RowData row;
  final ColumnDef column;

  @override
  State<_EditableCell> createState() => _EditableCellState();
}

class _EditableCellState extends State<_EditableCell> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _focused = false;
  bool _invalid = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final initialValue = widget.row.cells[widget.column.id] ?? '';
    _controller = TextEditingController(text: initialValue);
    _invalid = isInvalidCellValue(
      initialValue,
      widget.column.type,
      options: widget.column.options,
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocus);
  }

  @override
  void didUpdateWidget(covariant _EditableCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final modelValue = widget.row.cells[widget.column.id] ?? '';
    if (!_focusNode.hasFocus && _controller.text != modelValue) {
      _controller.text = modelValue;
    }
    _invalid = isInvalidCellValue(
      _controller.text,
      widget.column.type,
      options: widget.column.options,
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocus() {
    final focused = _focusNode.hasFocus;
    setState(() => _focused = focused);
    if (!focused && _dirty) {
      _dirty = false;
      AppScope.read(context).refresh();
    }
  }

  String get _invalidMessage {
    final l10n = context.l10n;
    switch (widget.column.type) {
      case ColumnType.number:
        return l10n.invalidNumberMessage;
      case ColumnType.date:
        return l10n.invalidDateMessage;
      case ColumnType.select:
        return l10n.invalidSelectMessage;
      case ColumnType.currency:
        return l10n.invalidCurrencyMessage;
      case ColumnType.text:
        return '';
    }
  }

  void _handleChanged(String value) {
    _dirty = true;
    AppScope.read(context).setCell(
      widget.table.id,
      widget.row.id,
      widget.column.id,
      value,
    );
    final invalid = isInvalidCellValue(
      value,
      widget.column.type,
      options: widget.column.options,
    );
    if (invalid != _invalid) {
      setState(() => _invalid = invalid);
    }
  }

  void _selectOption(String value) {
    if (_controller.text == value) return;
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    _handleChanged(value);
    _dirty = false;
    AppScope.read(context).refresh();
  }

  void _selectCellCurrency(String value) {
    AppScope.read(context).setCellCurrency(
      widget.table.id,
      widget.row.id,
      widget.column.id,
      value == _columnCurrencyDefault ? null : value,
    );
  }

  List<PopupMenuEntry<String>> _currencyMenuEntries(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final effective = widget.row.currencyFor(widget.column);
    final hasOverride =
        widget.row.currencies.containsKey(widget.column.id);
    return [
      if (hasOverride) ...[
        PopupMenuItem(
          value: _columnCurrencyDefault,
          child: Text(l10n.useColumnCurrency(widget.column.currencyCode)),
        ),
        const PopupMenuDivider(),
      ],
      for (final currency in appCurrencies)
        PopupMenuItem(
          value: currency.code,
          child: Row(
            children: [
              SizedBox(
                width: 18,
                child: effective == currency.code
                    ? Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: scheme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text('${currency.code} · ${currency.symbol}'),
            ],
          ),
        ),
    ];
  }

  Future<void> _pickDate() async {
    final state = AppScope.read(context);
    final firstDate = DateTime(1900);
    final lastDate = DateTime(2100, 12, 31);
    var initialDate = parseDate(_controller.text) ?? DateTime.now();
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;
    final picked = await showEasyDatePicker(
      context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null || !mounted) return;
    final text = '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    _handleChanged(text);
    _dirty = false;
    state.refresh();
  }

  Widget _buildSelectCell(BuildContext context, ColorScheme scheme) {
    final l10n = context.l10n;
    final value = _controller.text;
    final hasValue = value.trim().isNotEmpty;
    final textColor = _invalid
        ? scheme.error
        : hasValue
            ? scheme.onSurface
            : scheme.onSurfaceVariant.withValues(alpha: 0.65);
    return PopupMenuButton<String>(
      tooltip: l10n.chooseValueTooltip,
      position: PopupMenuPosition.under,
      onSelected: _selectOption,
      itemBuilder: (context) {
        final options = widget.column.options;
        return <PopupMenuEntry<String>>[
          if (options.isEmpty)
            PopupMenuItem<String>(
              enabled: false,
              child: Text(l10n.noOptionsDefined),
            ),
          for (final option in options)
            PopupMenuItem<String>(
              value: option,
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    child: value == option
                        ? Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: scheme.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      option,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (hasValue) ...[
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: '',
              child: Row(
                children: [
                  const Icon(Icons.close_rounded, size: 16),
                  const SizedBox(width: 8),
                  Text(l10n.clearValue),
                ],
              ),
            ),
          ],
        ];
      },
      child: SizedBox(
        height: _rowHeight,
        child: Padding(
          padding: const EdgeInsets.only(left: 11, right: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? value : l10n.chooseValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontStyle: hasValue ? null : FontStyle.italic,
                  ),
                ),
              ),
              if (_invalid) ...[
                Tooltip(
                  message: _invalidMessage,
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 13,
                    color: scheme.error,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isNumber = widget.column.type == ColumnType.number ||
        widget.column.type == ColumnType.currency;
    final isDate = widget.column.type == ColumnType.date;
    final isSelect = widget.column.type == ColumnType.select;
    final isCurrency = widget.column.type == ColumnType.currency;
    final currencyText = isCurrency
        ? currencySymbol(widget.row.currencyFor(widget.column))
        : '';
    final leftPadding = isCurrency
        ? (currencyText.length > 1 ? 56.0 : 44.0)
        : 11.0;
    final errorTint = scheme.errorContainer.withValues(
      alpha: _focused ? 0.32 : 0.18,
    );
    return Container(
      width: _cellWidth,
      height: _rowHeight,
      decoration: BoxDecoration(
        color: _invalid
            ? errorTint
            : _focused
                ? scheme.primary.withValues(alpha: 0.07)
                : null,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: isSelect
          ? _buildSelectCell(context, scheme)
          : Stack(
              children: [
                Positioned.fill(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _handleChanged,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      color: scheme.onSurface,
                      fontFeatures: isNumber
                          ? const [FontFeature.tabularFigures()]
                          : null,
                    ),
                    textAlign: isNumber ? TextAlign.right : TextAlign.left,
                    textAlignVertical: TextAlignVertical.center,
                    cursorColor: scheme.primary,
                    maxLines: 1,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(
                        left: leftPadding,
                        right: isDate ? 38 : (_invalid ? 26 : 11),
                        top: 12,
                        bottom: 12,
                      ),
                      hintText: null,
                      hoverColor: scheme.primary.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                if (isCurrency)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: PopupMenuButton<String>(
                      tooltip: context.l10n.chooseCurrency,
                      padding: EdgeInsets.zero,
                      position: PopupMenuPosition.under,
                      onSelected: _selectCellCurrency,
                      itemBuilder: _currencyMenuEntries,
                      child: SizedBox(
                        height: _rowHeight,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 6,
                            right: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currencyText,
                                style: TextStyle(
                                  fontSize:
                                      currencyText.length > 1 ? 9.5 : 11,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 14,
                                color: scheme.onSurfaceVariant
                                    .withValues(alpha: 0.55),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (isDate)
                  Positioned(
                    top: 4,
                    bottom: 4,
                    right: 2,
                    child: IconButton(
                      tooltip: _invalid
                          ? context.l10n.pickDateInvalid
                          : context.l10n.pickDate,
                      onPressed: _pickDate,
                      icon: Icon(
                        _invalid
                            ? Icons.error_outline_rounded
                            : Icons.event_outlined,
                        size: 16,
                      ),
                      color: _invalid
                          ? scheme.error
                          : scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 30,
                        height: 36,
                      ),
                      splashRadius: 15,
                    ),
                  )
                else if (_invalid)
                  Positioned(
                    top: 4,
                    right: 5,
                    child: Tooltip(
                      message: _invalidMessage,
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 13,
                        color: scheme.error,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _AddRowFooter extends StatelessWidget {
  const _AddRowFooter({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Row(
            children: [
              const SizedBox(width: _rowNumberWidth),
              Icon(Icons.add_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                context.l10n.addRow,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyGrid extends StatelessWidget {
  const _EmptyGrid({required this.hasQuery, required this.onAddRow});

  final bool hasQuery;
  final VoidCallback onAddRow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasQuery ? Icons.search_off_rounded : Icons.table_rows_outlined,
              size: 34,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 12),
            Text(
              hasQuery ? l10n.noRowsMatchFilter : l10n.noRowsYet,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasQuery ? l10n.noRowsFilterHint : l10n.noRowsHint,
              style: TextStyle(
                fontSize: 12.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (!hasQuery) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onAddRow,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.addRow),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoColumnsPanel extends StatelessWidget {
  const _NoColumnsPanel({required this.table});

  final TableData table;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.view_column_outlined,
              size: 34,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noColumnsTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.noColumnsHint,
              style: TextStyle(
                fontSize: 12.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => showAddColumnFlow(context, table),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.addColumn),
            ),
          ],
        ),
      ),
    );
  }
}
