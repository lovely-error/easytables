import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

Future<DateTime?> showEasyDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => EasyDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

class EasyDatePickerDialog extends StatefulWidget {
  const EasyDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<EasyDatePickerDialog> createState() => _EasyDatePickerDialogState();
}

class _EasyDatePickerDialogState extends State<EasyDatePickerDialog> {
  late final DateTime _firstDate;
  late final DateTime _lastDate;
  late DateTime _selectedDate;
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _firstDate = DateUtils.dateOnly(widget.firstDate);
    _lastDate = DateUtils.dateOnly(widget.lastDate);
    var initial = DateUtils.dateOnly(widget.initialDate);
    if (initial.isBefore(_firstDate)) initial = _firstDate;
    if (initial.isAfter(_lastDate)) initial = _lastDate;
    _selectedDate = initial;
    _visibleMonth = DateTime(initial.year, initial.month);
  }

  bool get _canGoPrevious {
    final previousMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month - 1,
    );
    final lastDay = DateTime(
      previousMonth.year,
      previousMonth.month + 1,
      0,
    );
    return !lastDay.isBefore(_firstDate);
  }

  bool get _canGoNext {
    final nextMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
    );
    return !nextMonth.isAfter(_lastDate);
  }

  void _changeMonth(int year, int month) {
    final firstMonth = DateTime(_firstDate.year, _firstDate.month);
    final lastMonth = DateTime(_lastDate.year, _lastDate.month);
    var target = DateTime(year, month);
    if (target.isBefore(firstMonth)) target = firstMonth;
    if (target.isAfter(lastMonth)) target = lastMonth;

    final daysInMonth = DateUtils.getDaysInMonth(target.year, target.month);
    final day = _selectedDate.day.clamp(1, daysInMonth);
    var selected = DateTime(target.year, target.month, day);
    if (selected.isBefore(_firstDate)) selected = _firstDate;
    if (selected.isAfter(_lastDate)) selected = _lastDate;

    setState(() {
      _visibleMonth = DateTime(target.year, target.month);
      _selectedDate = selected;
    });
  }

  void _selectDay(int day) {
    final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
    if (date.isBefore(_firstDate) || date.isAfter(_lastDate)) return;
    setState(() => _selectedDate = date);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final l10n = context.l10n;
    final monthNames = l10n.monthNames;
    final today = DateUtils.dateOnly(DateTime.now());
    final daysInMonth = DateUtils.getDaysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    final leadingDays = DateUtils.firstDayOffset(
      _visibleMonth.year,
      _visibleMonth.month,
      localizations,
    );
    final weekdays = <String>[
      for (var index = 0; index < 7; index++)
        localizations.narrowWeekdays[
            (localizations.firstDayOfWeekIndex + index) % 7],
    ];
    final years = <int>[
      for (var year = _firstDate.year; year <= _lastDate.year; year++) year,
    ];

    final dayCells = <Widget>[];
    for (var index = 0; index < 42; index++) {
      final day = index - leadingDays + 1;
      if (day < 1 || day > daysInMonth) {
        dayCells.add(const Expanded(child: SizedBox()));
        continue;
      }
      final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
      final enabled =
          !date.isBefore(_firstDate) && !date.isAfter(_lastDate);
      final isSelected = DateUtils.isSameDay(date, _selectedDate);
      final isToday = DateUtils.isSameDay(date, today);
      final textColor = isSelected
          ? scheme.onPrimary
          : !enabled
              ? scheme.onSurface.withValues(alpha: 0.3)
              : isToday
                  ? scheme.primary
                  : scheme.onSurface;
      dayCells.add(
        Expanded(
          child: Center(
            child: Semantics(
              button: enabled,
              selected: isSelected,
              label: localizations.formatFullDate(date),
              child: InkWell(
                onTap: enabled ? () => _selectDay(day) : null,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? scheme.primary : null,
                    border: isToday && !isSelected
                        ? Border.all(
                            color: scheme.primary.withValues(alpha: 0.6),
                          )
                        : null,
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AlertDialog(
      title: Text(l10n.pickDateTitle),
      content: SizedBox(
        width: 336,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: l10n.previousMonth,
                  onPressed: _canGoPrevious
                      ? () => _changeMonth(
                            _visibleMonth.year,
                            _visibleMonth.month - 1,
                          )
                      : null,
                  icon: const Icon(Icons.chevron_left, size: 19),
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: _DropdownShell(
                    child: DropdownButton<int>(
                      key: const ValueKey('date-picker-month'),
                      value: _visibleMonth.month,
                      isExpanded: true,
                      isDense: true,
                      menuMaxHeight: 320,
                      borderRadius: BorderRadius.circular(10),
                      icon: const Icon(Icons.expand_more_rounded, size: 17),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurface,
                      ),
                      onChanged: (month) {
                        if (month != null) {
                          _changeMonth(_visibleMonth.year, month);
                        }
                      },
                      items: [
                        for (var month = 1; month <= 12; month++)
                          DropdownMenuItem(
                            value: month,
                            child: Text(monthNames[month - 1]),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 88,
                  child: _DropdownShell(
                    child: DropdownButton<int>(
                      key: const ValueKey('date-picker-year'),
                      value: _visibleMonth.year,
                      isExpanded: true,
                      isDense: true,
                      menuMaxHeight: 320,
                      borderRadius: BorderRadius.circular(10),
                      icon: const Icon(Icons.expand_more_rounded, size: 17),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurface,
                      ),
                      onChanged: (year) {
                        if (year != null) {
                          _changeMonth(year, _visibleMonth.month);
                        }
                      },
                      items: [
                        for (final year in years)
                          DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.nextMonth,
                  onPressed: _canGoNext
                      ? () => _changeMonth(
                            _visibleMonth.year,
                            _visibleMonth.month + 1,
                          )
                      : null,
                  icon: const Icon(Icons.chevron_right, size: 19),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 22,
              child: Row(
                children: [
                  for (final weekday in weekdays)
                    Expanded(
                      child: Center(
                        child: Text(
                          weekday,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            for (var row = 0; row < 6; row++)
              SizedBox(
                height: 38,
                child: Row(
                  children: dayCells.sublist(row * 7, row * 7 + 7),
                ),
              ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                localizations.formatFullDate(_selectedDate),
                style: TextStyle(
                  fontSize: 11.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
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
          onPressed: () => Navigator.of(context).pop(_selectedDate),
          child: Text(l10n.selectAction),
        ),
      ],
    );
  }
}

class _DropdownShell extends StatelessWidget {
  const _DropdownShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(child: child),
    );
  }
}
