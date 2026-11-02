import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/table_data.dart';
import '../state/app_state.dart';
import 'dialogs.dart';

enum _TableMenuAction { rename, duplicate, delete }

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.onNewTable,
    required this.onImportCsv,
    required this.onOpenSettings,
    required this.onSelectTable,
    required this.settingsOpen,
  });

  final VoidCallback onNewTable;
  final VoidCallback onImportCsv;
  final VoidCallback onOpenSettings;
  final ValueChanged<String> onSelectTable;
  final bool settingsOpen;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Container(
      width: 274,
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 10, 18),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.appName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        l10n.dataWorkspace,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: state.themeMode == ThemeMode.dark
                      ? l10n.switchToLightTheme
                      : l10n.switchToDarkTheme,
                  onPressed: state.toggleTheme,
                  icon: Icon(
                    state.themeMode == ThemeMode.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    size: 19,
                  ),
                  color: scheme.onSurfaceVariant,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onNewTable,
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: Text(l10n.newTable),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: l10n.importCsv,
                  child: OutlinedButton(
                    onPressed: onImportCsv,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(42, 42),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Icon(Icons.upload_file_outlined, size: 19),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
            child: Row(
              children: [
                Text(
                  l10n.tablesLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (state.tables.isNotEmpty)
                  Text(
                    '${state.tables.length}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: state.tables.isEmpty
                ? _EmptySidebar(scheme: scheme)
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: state.tables.length,
                    itemBuilder: (context, index) {
                      final table = state.tables[index];
                      return _TableTile(
                        table: table,
                        selected:
                            !settingsOpen && table.id == state.selectedId,
                        onTap: () => onSelectTable(table.id),
                        onMenuAction: (action) => _handleMenu(
                          context,
                          state,
                          table,
                          action,
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onOpenSettings,
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: settingsOpen
                        ? scheme.primaryContainer.withValues(alpha: 0.5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: settingsOpen
                          ? scheme.primary.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: 18,
                        color: settingsOpen
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.settings,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: settingsOpen
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenu(
    BuildContext context,
    AppState state,
    TableData table,
    _TableMenuAction action,
  ) async {
    final l10n = context.l10n;
    switch (action) {
      case _TableMenuAction.rename:
        final name = await showTextPromptDialog(
          context,
          title: l10n.renameTable,
          initialValue: table.name,
          labelText: l10n.nameLabel,
          confirmLabel: l10n.rename,
        );
        if (name != null) state.renameTable(table.id, name);
      case _TableMenuAction.duplicate:
        state.duplicateTable(
          table.id,
          name: l10n.duplicateTableName(table.name),
        );
      case _TableMenuAction.delete:
        final confirmed = await showConfirmDialog(
          context,
          title: l10n.deleteTableTitle,
          message: l10n.deleteTableMessage(table.name, table.rows.length),
          confirmLabel: l10n.delete,
        );
        if (confirmed) state.deleteTable(table.id);
    }
  }
}

class _TableTile extends StatelessWidget {
  const _TableTile({
    required this.table,
    required this.selected,
    required this.onTap,
    required this.onMenuAction,
  });

  final TableData table;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<_TableMenuAction> onMenuAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.fromLTRB(10, 9, 4, 9),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primaryContainer.withValues(alpha: 0.55)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.35)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.grid_on_rounded,
                    size: 17,
                    color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        table.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.rowsCount(table.rows.length)} · '
                        '${l10n.columnsCount(table.columns.length)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? scheme.onPrimaryContainer.withValues(alpha: 0.75)
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_TableMenuAction>(
                  tooltip: l10n.tableActions,
                  onSelected: onMenuAction,
                  position: PopupMenuPosition.under,
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 18,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                  iconSize: 18,
                  splashRadius: 18,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _TableMenuAction.rename,
                      child: _MenuRow(
                        icon: Icons.edit_outlined,
                        label: l10n.rename,
                      ),
                    ),
                    PopupMenuItem(
                      value: _TableMenuAction.duplicate,
                      child: _MenuRow(
                        icon: Icons.copy_all_outlined,
                        label: l10n.duplicate,
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: _TableMenuAction.delete,
                      child: _MenuRow(
                        icon: Icons.delete_outline_rounded,
                        label: l10n.delete,
                        color: scheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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

class _EmptySidebar extends StatelessWidget {
  const _EmptySidebar({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.layers_outlined,
              size: 30,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.noTablesYet,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
