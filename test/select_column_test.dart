import 'package:easytables/models/table_data.dart';
import 'package:easytables/theme.dart';
import 'package:easytables/widgets/dialogs.dart';
import 'package:easytables/widgets/table_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('add column dialog can create a select field', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    ColumnDraft? draft;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                draft = await showAddColumnDialog(context);
              },
              child: const Text('Open dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('column-name-input')),
      'Priority',
    );
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    expect(find.text('No options yet.'), findsOneWidget);
    final submitBefore = tester.widget<FilledButton>(
      find.byKey(const ValueKey('add-column-submit')),
    );
    expect(submitBefore.onPressed, isNull);

    Future<void> addOption(String value) async {
      await tester.enterText(
        find.byKey(const ValueKey('option-input')),
        value,
      );
      await tester.tap(find.byKey(const ValueKey('add-option-button')));
      await tester.pump();
    }

    await addOption('Low');
    await addOption('High');
    expect(find.widgetWithText(InputChip, 'Low'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'High'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('add-column-submit')));
    await tester.pumpAndSettle();

    expect(draft, isNotNull);
    expect(draft!.name, 'Priority');
    expect(draft!.type, ColumnType.select);
    expect(draft!.options, ['Low', 'High']);
  });

  testWidgets('add column dialog can create a currency field', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    ColumnDraft? draft;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                draft = await showAddColumnDialog(context);
              },
              child: const Text('Open dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('column-name-input')),
      'Price',
    );
    await tester.tap(find.text('Currency'));
    await tester.pumpAndSettle();

    expect(find.byType(CurrencyDropdown), findsOneWidget);
    await tester.tap(find.byType(CurrencyDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EUR · €').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add-column-submit')));
    await tester.pumpAndSettle();

    expect(draft, isNotNull);
    expect(draft!.name, 'Price');
    expect(draft!.type, ColumnType.currency);
    expect(draft!.currencyCode, 'EUR');
  });

  testWidgets('select cells open a list of options', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026, 1, 1);
    final table = TableData(
      id: 't',
      name: 'Choices',
      columns: [
        ColumnDef(
          id: 'priority',
          name: 'Priority',
          type: ColumnType.select,
          options: const ['Low', 'High'],
        ),
      ],
      rows: [
        RowData(id: 'r1', cells: {'priority': 'Low'}),
      ],
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: TableGrid(
            table: table,
            rows: table.rows,
            query: '',
            onClearFilter: () {},
          ),
        ),
      ),
    );

    expect(find.text('Low'), findsOneWidget);
    await tester.tap(find.text('Low'));
    await tester.pumpAndSettle();

    expect(find.text('High'), findsOneWidget);
    expect(find.text('Clear value'), findsOneWidget);
  });
}
