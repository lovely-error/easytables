import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/table_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/currencies.dart';
import '../utils/csv.dart';
import '../utils/values.dart';

typedef ColumnDraft = ({
  String name,
  ColumnType type,
  List<String> options,
  String currencyCode,
});

class ImportDraft {
  const ImportDraft({required this.name, required this.parsed});

  final String name;
  final ParsedCsv parsed;
}

Future<String?> showTextPromptDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String? labelText,
  String? hintText,
  String? helperText,
  String? confirmLabel,
}) async {
  final controller = TextEditingController(text: initialValue);
  controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: initialValue.length,
  );
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: appInputDecoration(
                  dialogContext,
                  labelText: labelText ?? l10n.nameLabel,
                  hintText: hintText,
                  isDense: false,
                ),
                onSubmitted: (value) {
                  final trimmed = value.trim();
                  if (trimmed.isEmpty) return;
                  Navigator.of(dialogContext).pop(trimmed);
                },
              ),
              if (helperText != null) ...[
                const SizedBox(height: 8),
                Text(
                  helperText,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isEmpty) return;
              Navigator.of(dialogContext).pop(trimmed);
            },
            child: Text(confirmLabel ?? l10n.save),
          ),
        ],
      );
    },
  );
  controller.dispose();
  return result;
}

Future<ColumnDraft?> showAddColumnDialog(BuildContext context) {
  return showDialog<ColumnDraft>(
    context: context,
    builder: (dialogContext) => const _AddColumnDialog(),
  );
}

Future<List<String>?> showColumnOptionsDialog(
  BuildContext context, {
  required List<String> initialOptions,
  String? title,
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (dialogContext) => _ColumnOptionsDialog(
      initialOptions: initialOptions,
      title: title ?? dialogContext.l10n.optionsLabel,
    ),
  );
}

Future<String?> showCurrencyPickerDialog(
  BuildContext context, {
  required String initialCode,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _CurrencyPickerDialog(
      initialCode: initialCode,
    ),
  );
}

Future<void> showAddColumnFlow(BuildContext context, TableData table) async {
  final state = AppScope.read(context);
  final draft = await showAddColumnDialog(context);
  if (draft == null) return;
  state.addColumn(
    table.id,
    draft.name,
    draft.type,
    options: draft.options,
    currencyCode: draft.currencyCode,
  );
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      return AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: scheme.error),
        title: Text(title),
        content: SizedBox(
          width: 430,
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel ?? l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel ?? l10n.delete),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

Future<ImportDraft?> showImportCsvDialog(
  BuildContext context, {
  String? suggestedName,
}) {
  return showDialog<ImportDraft>(
    context: context,
    builder: (dialogContext) => _ImportCsvDialog(
      suggestedName: suggestedName ?? dialogContext.l10n.importedTable,
    ),
  );
}

Future<void> showExportDialog(
  BuildContext context,
  ExportResult result,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      final l10n = dialogContext.l10n;
      return AlertDialog(
        icon: Icon(Icons.check_circle_outline_rounded, color: scheme.primary),
        title: Text(l10n.csvExported),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.exportedTo),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: SelectableText(
                  result.path,
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.exportedFileHint,
                style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: result.csv));
              if (!dialogContext.mounted) return;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text(l10n.csvCopied)),
              );
            },
            icon: const Icon(Icons.copy_all_outlined, size: 18),
            label: Text(l10n.copyCsv),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.done),
          ),
        ],
      );
    },
  );
}

class _AddColumnDialog extends StatefulWidget {
  const _AddColumnDialog();

  @override
  State<_AddColumnDialog> createState() => _AddColumnDialogState();
}

class _AddColumnDialogState extends State<_AddColumnDialog> {
  final TextEditingController _nameController = TextEditingController();
  ColumnType _type = ColumnType.text;
  List<String> _options = <String>[];
  String _currencyCode = 'USD';
  bool _currencyInitialized = false;

  bool get _isSelect => _type == ColumnType.select;
  bool get _isCurrency => _type == ColumnType.currency;
  bool get _canSubmit => !_isSelect || _options.isNotEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_currencyInitialized) {
      _currencyInitialized = true;
      _currencyCode = defaultCurrencyCode(context.l10n.isRu);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  IconData _typeIcon(ColumnType type) {
    switch (type) {
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

  Widget _buildTypeChip(
    BuildContext context,
    ColorScheme scheme,
    AppLocalizations l10n,
    ColumnType type,
  ) {
    final selected = _type == type;
    return ChoiceChip(
      label: Text(
        l10n.columnTypeLabel(type),
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
        ),
      ),
      avatar: Icon(
        _typeIcon(type),
        size: 16,
        color: selected
            ? scheme.onPrimaryContainer
            : scheme.onSurfaceVariant,
      ),
      selected: selected,
      selectedColor: scheme.primaryContainer,
      showCheckmark: false,
      side: BorderSide(
        color: selected ? scheme.primary : scheme.outlineVariant,
      ),
      onSelected: (_) {
        setState(() => _type = type);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.addColumn),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('column-name-input'),
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: appInputDecoration(
                context,
                labelText: l10n.columnNameLabel,
                hintText: l10n.columnNameHint,
                isDense: false,
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.columnTypeLabelTitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in ColumnType.values)
                  _buildTypeChip(context, scheme, l10n, type),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.addColumnHelper,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (_isCurrency) ...[
              const SizedBox(height: 18),
              Text(
                l10n.currencyLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 240,
                child: CurrencyDropdown(
                  value: _currencyCode,
                  onChanged: (code) {
                    setState(() => _currencyCode = code);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.currencyHelper,
                style: TextStyle(
                  fontSize: 11.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (_isSelect) ...[
              const SizedBox(height: 18),
              Text(
                l10n.optionsLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              OptionsEditor(
                options: _options,
                onChanged: (options) {
                  setState(() => _options = options);
                },
              ),
              const SizedBox(height: 8),
              Text(
                _options.isEmpty
                    ? l10n.addAtLeastOneOption
                    : l10n.singleChoiceHint,
                style: TextStyle(
                  fontSize: 11.5,
                  color: _options.isEmpty
                      ? scheme.error
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('add-column-submit'),
          onPressed: _canSubmit ? _submit : null,
          child: Text(l10n.addColumn),
        ),
      ],
    );
  }

  void _submit() {
    if (!_canSubmit) return;
    final l10n = context.l10n;
    final name = _nameController.text.trim();
    Navigator.of(context).pop((
      name: name.isEmpty ? l10n.newColumnName : name,
      type: _type,
      options: _isSelect ? List<String>.of(_options) : const <String>[],
      currencyCode: _currencyCode,
    ));
  }
}

class CurrencyDropdown extends StatelessWidget {
  const CurrencyDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          menuMaxHeight: 320,
          borderRadius: BorderRadius.circular(10),
          icon: Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          style: TextStyle(fontSize: 12.5, color: scheme.onSurface),
          onChanged: (code) {
            if (code != null) onChanged(code);
          },
          items: [
            for (final currency in appCurrencies)
              DropdownMenuItem(
                value: currency.code,
                child: Text('${currency.code} · ${currency.symbol}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyPickerDialog extends StatefulWidget {
  const _CurrencyPickerDialog({required this.initialCode});

  final String initialCode;

  @override
  State<_CurrencyPickerDialog> createState() => _CurrencyPickerDialogState();
}

class _CurrencyPickerDialogState extends State<_CurrencyPickerDialog> {
  late String _code;

  @override
  void initState() {
    super.initState();
    _code = currencyFor(widget.initialCode).code;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l10n.currencyPickerTitle),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.currencyHelper,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            CurrencyDropdown(
              value: _code,
              onChanged: (code) {
                setState(() => _code = code);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_code),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class OptionsEditor extends StatefulWidget {
  const OptionsEditor({
    super.key,
    required this.options,
    required this.onChanged,
  });

  final List<String> options;
  final ValueChanged<List<String>> onChanged;

  @override
  State<OptionsEditor> createState() => _OptionsEditorState();
}

class _OptionsEditorState extends State<OptionsEditor> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addOption() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    final exists = widget.options.any(
      (option) => option.toLowerCase() == value.toLowerCase(),
    );
    if (!exists) {
      widget.onChanged(normalizeOptions([...widget.options, value]));
    }
    _controller.clear();
  }

  void _removeOption(String option) {
    widget.onChanged([...widget.options]..remove(option));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('option-input'),
                controller: _controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addOption(),
                style: const TextStyle(fontSize: 13),
                decoration: appInputDecoration(
                  context,
                  hintText: l10n.addOptionHint,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              key: const ValueKey('add-option-button'),
              tooltip: l10n.addOptionTooltip,
              onPressed: _addOption,
              icon: const Icon(Icons.add_rounded, size: 18),
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (widget.options.isEmpty)
          Text(
            l10n.noOptionsYet,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 132),
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final option in widget.options)
                      InputChip(
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: Text(
                            option,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                        deleteIcon: const Icon(
                          Icons.close_rounded,
                          size: 16,
                        ),
                        onDeleted: () => _removeOption(option),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ColumnOptionsDialog extends StatefulWidget {
  const _ColumnOptionsDialog({
    required this.initialOptions,
    required this.title,
  });

  final List<String> initialOptions;
  final String title;

  @override
  State<_ColumnOptionsDialog> createState() => _ColumnOptionsDialogState();
}

class _ColumnOptionsDialogState extends State<_ColumnOptionsDialog> {
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    _options = normalizeOptions(widget.initialOptions);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.optionsWarning,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            OptionsEditor(
              options: _options,
              onChanged: (options) {
                setState(() => _options = options);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _options.isEmpty
              ? null
              : () => Navigator.of(context).pop(List<String>.of(_options)),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _ImportCsvDialog extends StatefulWidget {
  const _ImportCsvDialog({required this.suggestedName});

  final String suggestedName;

  @override
  State<_ImportCsvDialog> createState() => _ImportCsvDialogState();
}

class _ImportCsvDialogState extends State<_ImportCsvDialog> {
  late final TextEditingController _nameController;
  final TextEditingController _csvController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.suggestedName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _csvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.importCsvTitle),
      content: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: appInputDecoration(
                context,
                labelText: l10n.tableNameLabel,
                isDense: false,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _csvController,
              minLines: 7,
              maxLines: 12,
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 12.5,
                height: 1.4,
              ),
              decoration: appInputDecoration(
                context,
                labelText: l10n.csvDataLabel,
                hintText: l10n.csvSample,
                isDense: false,
                alignLabelWithHint: true,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.importInfo,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(fontSize: 12.5, color: scheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.file_download_outlined, size: 18),
          label: Text(l10n.importAction),
        ),
      ],
    );
  }

  void _submit() {
    final l10n = context.l10n;
    final parsed = parseCsv(_csvController.text);
    if (parsed == null) {
      setState(() {
        _error = l10n.importErrorPaste;
      });
      return;
    }
    final name = _nameController.text.trim();
    Navigator.of(context).pop(ImportDraft(
      name: name.isEmpty ? l10n.importedTable : name,
      parsed: parsed,
    ));
  }
}
