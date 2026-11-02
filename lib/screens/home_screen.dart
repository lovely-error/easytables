import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/table_data.dart';
import '../theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/settings_view.dart';
import '../widgets/sidebar.dart';
import '../widgets/workspace.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showSettings = false;

  Future<void> _createTable(BuildContext context) async {
    final state = AppScope.read(context);
    final l10n = context.l10n;
    final name = await showTextPromptDialog(
      context,
      title: l10n.newTable,
      initialValue: l10n.untitledTable,
      labelText: l10n.tableNameLabel,
      hintText: l10n.tableNameHint,
      confirmLabel: l10n.createTable,
    );
    if (name == null) return;
    state.addTable(
      name,
      columns: [
        ColumnDef.create(
          name: l10n.defaultItemColumn,
          type: ColumnType.text,
        ),
        ColumnDef.create(
          name: l10n.defaultCategoryColumn,
          type: ColumnType.text,
        ),
        ColumnDef.create(
          name: l10n.defaultAmountColumn,
          type: ColumnType.number,
        ),
      ],
    );
    if (mounted) setState(() => _showSettings = false);
  }

  Future<void> _importCsv(BuildContext context) async {
    final state = AppScope.read(context);
    final l10n = context.l10n;
    final draft = await showImportCsvDialog(
      context,
      suggestedName: l10n.importedTable,
    );
    if (draft == null) return;
    state.importCsv(draft.name, draft.parsed);
    if (mounted) setState(() => _showSettings = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l10n = context.l10n;
    if (!state.isLoaded) {
      return const _LoadingView();
    }
    final selected = state.selectedTable;
    return Scaffold(
      body: Column(
        children: [
          if (state.loadError != null)
            _ErrorBanner(message: l10n.loadError(state.loadError!)),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSidebar(
                  onNewTable: () => _createTable(context),
                  onImportCsv: () => _importCsv(context),
                  onOpenSettings: () {
                    setState(() => _showSettings = true);
                  },
                  onSelectTable: (id) {
                    state.selectTable(id);
                    setState(() => _showSettings = false);
                  },
                  settingsOpen: _showSettings,
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _showSettings
                      ? SettingsView(
                          onClose: () {
                            setState(() => _showSettings = false);
                          },
                        )
                      : selected == null
                          ? _EmptyLibrary(
                              onCreate: () => _createTable(context),
                              onImport: () => _importCsv(context),
                            )
                          : TableWorkspace(
                              key: ValueKey(selected.id),
                              table: selected,
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

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'EasyTables',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onCreate, required this.onImport});

  final VoidCallback onCreate;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: seedColor.withValues(alpha: 0.25),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.createFirstTable,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.emptyLibraryDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.newTable),
                  ),
                  OutlinedButton.icon(
                    onPressed: onImport,
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: Text(l10n.importCsv),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 18,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _FeatureHint(
                    icon: Icons.edit_outlined,
                    label: l10n.featureEditableGrid,
                  ),
                  _FeatureHint(
                    icon: Icons.sort_rounded,
                    label: l10n.featureSortFilter,
                  ),
                  _FeatureHint(
                    icon: Icons.insights_rounded,
                    label: l10n.featureCharts,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureHint extends StatelessWidget {
  const _FeatureHint({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: scheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 17,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                color: scheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
