import 'package:easytables/app_scope.dart';
import 'package:easytables/models/table_data.dart';
import 'package:easytables/services/storage_service.dart';
import 'package:easytables/state/app_state.dart';
import 'package:easytables/widgets/date_picker_dialog.dart';
import 'package:easytables/widgets/table_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('date cells open a calendar picker', (tester) async {
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(StorageService());
    addTearDown(state.dispose);

    final now = DateTime(2026, 1, 1);
    final table = TableData(
      id: 't',
      name: 'Dates',
      columns: [
        ColumnDef(id: 'task', name: 'Task', type: ColumnType.text),
        ColumnDef(id: 'due', name: 'Due', type: ColumnType.date),
      ],
      rows: [
        RowData(id: 'r1', cells: {'task': 'Ship', 'due': '2026-01-31'}),
      ],
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          home: Scaffold(
            body: TableGrid(
              table: table,
              rows: table.rows,
              query: '',
              onClearFilter: () {},
            ),
          ),
        ),
      ),
    );

    final button = find.widgetWithIcon(IconButton, Icons.event_outlined);
    expect(button, findsOneWidget);
    expect(tester.getSize(button).width, greaterThan(0));
    expect(tester.getSize(button).height, greaterThan(0));

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(EasyDatePickerDialog), findsOneWidget);

    final monthDropdown =
        find.byKey(const ValueKey('date-picker-month'));
    expect(monthDropdown, findsOneWidget);
    await tester.tap(monthDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('March').last);
    await tester.pumpAndSettle();

    final selectedMonth = tester.widget<DropdownButton<int>>(monthDropdown);
    expect(selectedMonth.value, 3);
    expect(find.text('March'), findsOneWidget);
  });
}
