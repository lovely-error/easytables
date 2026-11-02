import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/table_data.dart';
import '../theme.dart';
import '../utils/values.dart';
import 'chart_view.dart';
import 'dialogs.dart';
import 'table_grid.dart';

enum WorkspaceView { table, charts }

class TableWorkspace extends StatefulWidget {
  const TableWorkspace({super.key, required this.table});

  final TableData table;

  @override
  State<TableWorkspace> createState() => _TableWorkspaceState();
}

class _TableWorkspaceState extends State<TableWorkspace> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  WorkspaceView _view = WorkspaceView.table;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateQuery(String value) {
    setState(() => _query = value);
  }

  void _clearFilter() {
    _searchController.clear();
    _updateQuery('');
  }

  void _addRow() {
    final l10n = context.l10n;
    AppScope.read(context).addRow(widget.table.id);
    if (_query.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.rowAddedHidden),
        action: SnackBarAction(label: l10n.clearFilter, onPressed: _clearFilter),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final state = AppScope.read(context);
    final l10n = context.l10n;
    try {
      final result = await state.exportTableCsv(widget.table);
      if (!mounted) return;
      await showExportDialog(context, result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final table = widget.table;
    final filtered = filterRows(table, _query);
    final searching = _query.trim().isNotEmpty;
    final invalidCount = countInvalidCells(table);

    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tooltip(
                      message: table.name,
                      waitDuration: const Duration(milliseconds: 800),
                      child: Text(
                        table.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.tableSummary(
                        table.rows.length,
                        table.columns.length,
                        table.updatedAt,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _exportCsv,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: Text(l10n.exportCsv),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<WorkspaceView>(
                segments: [
                  ButtonSegment(
                    value: WorkspaceView.table,
                    icon: const Icon(Icons.table_chart_outlined, size: 17),
                    label: Text(l10n.tableView),
                  ),
                  ButtonSegment(
                    value: WorkspaceView.charts,
                    icon: const Icon(Icons.insights_rounded, size: 17),
                    label: Text(l10n.chartsView),
                  ),
                ],
                selected: {_view},
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onSelectionChanged: (selection) {
                  setState(() => _view = selection.first);
                },
              ),
              SizedBox(
                width: 290,
                child: TextField(
                  controller: _searchController,
                  onChanged: _updateQuery,
                  decoration: appInputDecoration(
                    context,
                    hintText: l10n.filterRowsHint,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    suffixIcon: searching
                        ? IconButton(
                            tooltip: l10n.clearFilter,
                            onPressed: _clearFilter,
                            icon: const Icon(Icons.close_rounded, size: 16),
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          )
                        : null,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              if (searching)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.shownOf(filtered.length, table.rows.length),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              if (invalidCount > 0)
                Tooltip(
                  message: l10n.invalidValuesTooltip,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 14,
                          color: scheme.error,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          l10n.invalidValues(invalidCount),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_view == WorkspaceView.table) ...[
                OutlinedButton.icon(
                  onPressed: () => showAddColumnFlow(context, table),
                  icon: const Icon(Icons.view_column_outlined, size: 17),
                  label: Text(l10n.addColumn),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.addRow),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: IndexedStack(
              index: _view == WorkspaceView.table ? 0 : 1,
              children: [
                SizedBox.expand(
                  child: TableGrid(
                    table: table,
                    rows: filtered,
                    query: _query,
                    onClearFilter: _clearFilter,
                  ),
                ),
                SizedBox.expand(
                  child: ChartView(
                    table: table,
                    rows: filtered,
                    query: _query,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
