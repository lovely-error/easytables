import 'package:easytables/app_scope.dart';
import 'package:easytables/l10n/app_localizations.dart';
import 'package:easytables/services/storage_service.dart';
import 'package:easytables/state/app_state.dart';
import 'package:easytables/theme.dart';
import 'package:easytables/widgets/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage extends StorageService {
  Map<String, dynamic>? stored;
  Map<String, dynamic>? lastSaved;

  @override
  Future<Map<String, dynamic>?> loadLibrary() async => stored;

  @override
  Future<void> saveLibrary(Map<String, dynamic> data) async {
    lastSaved = data;
  }
}

void main() {
  test('provides Russian translations and plural forms', () {
    const ru = AppLocalizations(Locale('ru'));
    expect(ru.settings, 'Настройки');
    expect(ru.newTable, 'Новая таблица');
    expect(ru.rowsCount(1), '1 строка');
    expect(ru.rowsCount(3), '3 строки');
    expect(ru.rowsCount(5), '5 строк');
    expect(ru.rowsCount(21), '21 строка');
    expect(ru.errorsCount(2), '2 ошибки');
    expect(ru.chartOther, 'Прочее');
    expect(ru.monthNames[9], 'Октябрь');
  });

  test('English remains the fallback locale', () {
    const en = AppLocalizations(Locale('en'));
    expect(en.settings, 'Settings');
    expect(en.rowsCount(3), '3 rows');
    expect(en.errorsCount(1), '1 invalid value');
  });

  test('language and theme are loaded and saved', () async {
    final storage = _MemoryStorage()
      ..stored = {
        'language': 'ru',
        'theme': 'dark',
        'tables': <dynamic>[],
      };
    final state = AppState(storage);
    addTearDown(state.dispose);

    await state.initialize();
    expect(state.languageCode, 'ru');
    expect(state.themeMode, ThemeMode.dark);

    state.setLanguage('en');
    state.setThemeMode(ThemeMode.light);
    await state.flush();

    expect(storage.lastSaved?['language'], 'en');
    expect(storage.lastSaved?['theme'], 'light');
  });

  testWidgets('settings page switches the interface language', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = _MemoryStorage()
      ..stored = {
        'language': 'en',
        'tables': <dynamic>[],
      };
    final state = AppState(storage);
    addTearDown(state.dispose);
    await state.initialize();

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: ListenableBuilder(
          listenable: state,
          builder: (context, _) {
            return MaterialApp(
              locale: Locale(state.languageCode),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              theme: buildAppTheme(Brightness.light),
              home: Scaffold(
                body: SettingsView(onClose: () {}),
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Interface language'), findsOneWidget);

    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();

    expect(state.languageCode, 'ru');
    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Язык интерфейса'), findsOneWidget);
  });
}
