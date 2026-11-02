import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../models/table_data.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  bool get isRu => locale.languageCode == 'ru';

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ru'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('en'));
  }

  String get appName => 'EasyTables';

  String get dataWorkspace => isRu ? 'Рабочая область' : 'Data workspace';
  String get newTable => isRu ? 'Новая таблица' : 'New table';
  String get importCsv => isRu ? 'Импорт CSV' : 'Import CSV';
  String get exportCsv => isRu ? 'Экспорт CSV' : 'Export CSV';
  String get tablesLabel => isRu ? 'ТАБЛИЦЫ' : 'TABLES';
  String get noTablesYet => isRu ? 'Таблиц пока нет' : 'No tables yet';
  String get savedLocally => isRu ? 'Сохранено локально' : 'Saved locally';
  String get settings => isRu ? 'Настройки' : 'Settings';
  String get tableActions => isRu ? 'Действия с таблицей' : 'Table actions';
  String get rename => isRu ? 'Переименовать' : 'Rename';
  String get duplicate => isRu ? 'Дублировать' : 'Duplicate';
  String get delete => isRu ? 'Удалить' : 'Delete';
  String get renameTable => isRu ? 'Переименовать таблицу' : 'Rename table';
  String get deleteTableTitle => isRu ? 'Удалить таблицу?' : 'Delete table?';
  String get switchToLightTheme =>
      isRu ? 'Переключить на светлую тему' : 'Switch to light theme';
  String get switchToDarkTheme =>
      isRu ? 'Переключить на тёмную тему' : 'Switch to dark theme';
  String get createFirstTable =>
      isRu ? 'Создайте первую таблицу' : 'Create your first table';
  String get emptyLibraryDescription => isRu
      ? 'Создайте таблицу с нуля или вставьте данные из электронной таблицы. '
          'Добавляйте столбцы, фильтруйте строки и превращайте числа в '
          'понятные диаграммы.'
      : 'Build a table from scratch or paste data from a spreadsheet. Add '
          'columns, filter rows, and turn the numbers into clear charts.';
  String get featureEditableGrid =>
      isRu ? 'Редактируемая сетка' : 'Editable grid';
  String get featureSortFilter =>
      isRu ? 'Сортировка и фильтрация' : 'Sort & filter';
  String get featureCharts =>
      isRu ? 'Встроенные диаграммы' : 'Built-in charts';
  String get tableView => isRu ? 'Таблица' : 'Table';
  String get chartsView => isRu ? 'Диаграммы' : 'Charts';
  String get filterRowsHint => isRu ? 'Фильтр по строкам…' : 'Filter rows…';
  String get clearFilter => isRu ? 'Сбросить фильтр' : 'Clear filter';
  String get invalidValuesTooltip => isRu
      ? 'Эти значения не соответствуют типу столбца. Они сохраняются, но не '
          'учитываются при числовой сортировке и в итогах диаграмм.'
      : 'These values do not match their column type. They are kept, but '
          'ignored by numeric sorting and chart totals.';
  String get addColumn => isRu ? 'Добавить столбец' : 'Add column';
  String get addRow => isRu ? 'Добавить строку' : 'Add row';
  String get newColumnName => isRu ? 'Новый столбец' : 'New column';
  String get rowAddedHidden => isRu
      ? 'Строка добавлена. Она скрыта текущим фильтром.'
      : 'Row added. It is hidden by the current filter.';
  String get renameColumn =>
      isRu ? 'Переименовать столбец' : 'Rename column';
  String get editOptions => isRu ? 'Изменить варианты…' : 'Edit options…';
  String get columnOptions => isRu ? 'Параметры столбца' : 'Column options';
  String get sortAscending => isRu ? 'По возрастанию' : 'Sort ascending';
  String get sortDescending => isRu ? 'По убыванию' : 'Sort descending';
  String get clearSort => isRu ? 'Сбросить сортировку' : 'Clear sort';
  String get deleteColumn => isRu ? 'Удалить столбец' : 'Delete column';
  String get deleteColumnTitle =>
      isRu ? 'Удалить столбец?' : 'Delete column?';
  String get rowActions => isRu ? 'Действия со строкой' : 'Row actions';
  String get duplicateRow =>
      isRu ? 'Дублировать строку' : 'Duplicate row';
  String get moveUp => isRu ? 'Переместить вверх' : 'Move up';
  String get moveDown => isRu ? 'Переместить вниз' : 'Move down';
  String get deleteRow => isRu ? 'Удалить строку' : 'Delete row';
  String get noRowsYet => isRu ? 'Пока нет строк' : 'No rows yet';
  String get noRowsMatchFilter =>
      isRu ? 'Нет строк по текущему фильтру' : 'No rows match your filter';
  String get noRowsFilterHint =>
      isRu ? 'Попробуйте изменить запрос.' : 'Try a different search term.';
  String get noRowsHint => isRu
      ? 'Добавьте первую строку, чтобы начать вводить данные.'
      : 'Add your first row to start entering data.';
  String get noColumnsTitle =>
      isRu ? 'В этой таблице нет столбцов' : 'This table has no columns';
  String get noColumnsHint => isRu
      ? 'Добавьте столбец, чтобы начать вводить данные.'
      : 'Add a column to start entering data.';
  String get chooseValue => isRu ? 'Выберите…' : 'Choose…';
  String get chooseValueTooltip =>
      isRu ? 'Выбрать значение' : 'Choose a value';
  String get noOptionsDefined =>
      isRu ? 'Варианты не заданы' : 'No options defined';
  String get clearValue => isRu ? 'Очистить значение' : 'Clear value';
  String get invalidSelectMessage => isRu
      ? 'Это значение отсутствует среди вариантов столбца. Выберите значение '
          'из списка.'
      : 'This value is not one of the column options. Choose one from the '
          'list.';
  String get invalidNumberMessage => isRu
      ? 'Это недопустимое число. Оно пропускается при числовой сортировке и '
          'в итогах диаграмм.'
      : 'This is not a valid number. It is skipped by numeric sorting and '
          'chart totals.';
  String get invalidDateMessage => isRu
      ? 'Это недопустимая дата. Используйте формат ISO, например 2026-01-31.'
      : 'This is not a valid date. Use ISO format, e.g. 2026-01-31.';
  String get pickDate => isRu ? 'Выбрать дату' : 'Pick a date';
  String get pickDateInvalid => isRu
      ? 'Неверная дата — выберите корректную дату'
      : 'Invalid date — pick a valid date';
  String get pickDateTitle => isRu ? 'Выберите дату' : 'Pick a date';
  String get previousMonth => isRu ? 'Предыдущий месяц' : 'Previous month';
  String get nextMonth => isRu ? 'Следующий месяц' : 'Next month';
  String get selectAction => isRu ? 'Выбрать' : 'Select';
  String get optionsLabel => isRu ? 'Варианты' : 'Options';
  String get optionsWarning => isRu
      ? 'Ячейка может содержать один из этих вариантов. Изменение списка не '
          'переписывает существующие значения; значения вне списка будут '
          'отмечены.'
      : 'Cells can contain one of these values. Changing the list does not '
          'rewrite existing values; values not in the list will be flagged.';
  String get addOptionHint =>
      isRu ? 'Введите вариант и нажмите Enter' : 'Add an option and press Enter';
  String get addOptionTooltip => isRu ? 'Добавить вариант' : 'Add option';
  String get noOptionsYet => isRu ? 'Вариантов пока нет.' : 'No options yet.';
  String get addAtLeastOneOption => isRu
      ? 'Добавьте хотя бы один вариант, чтобы продолжить.'
      : 'Add at least one option to continue.';
  String get singleChoiceHint => isRu
      ? 'Ячейки будут предлагать эти значения как один вариант выбора.'
      : 'Cells will offer these values as a single choice.';
  String get columnNameLabel => isRu ? 'Название столбца' : 'Column name';
  String get columnNameHint => isRu ? 'напр. Выручка' : 'e.g. Revenue';
  String get columnTypeLabelTitle => isRu ? 'Тип столбца' : 'Column type';
  String get currencyLabel => isRu ? 'Валюта' : 'Currency';
  String get currencyPickerTitle =>
      isRu ? 'Выберите валюту' : 'Select currency';
  String get currencyHelper => isRu
      ? 'Суммы будут отображаться с символом выбранной валюты.'
      : 'Amounts will display with the selected currency symbol.';
  String get editCurrency => isRu ? 'Изменить валюту…' : 'Change currency…';
  String get chooseCurrency =>
      isRu ? 'Выбрать валюту' : 'Choose currency';
  String useColumnCurrency(String code) => isRu
      ? 'Использовать валюту столбца ($code)'
      : 'Use column currency ($code)';
  String get invalidCurrencyMessage => isRu
      ? 'Это недопустимая сумма. Она пропускается при числовой сортировке и '
          'в итогах диаграмм.'
      : 'This is not a valid amount. It is skipped by numeric sorting and '
          'chart totals.';
  String get addColumnHelper => isRu
      ? 'Числовые столбцы сортируются численно и могут использоваться в '
          'диаграммах. Столбцы валют хранят денежные суммы с выбранным '
          'символом. Даты сортируются хронологически и получают календарь. '
          'Столбцы-списки предлагают один вариант из заданного набора.'
      : 'Number columns sort numerically and can be charted. Currency columns '
          'store monetary amounts with a chosen symbol. Date columns sort '
          'chronologically and get a calendar picker. Select columns offer a '
          'single choice from your own list.';
  String get cancel => isRu ? 'Отмена' : 'Cancel';
  String get save => isRu ? 'Сохранить' : 'Save';
  String get done => isRu ? 'Готово' : 'Done';
  String get nameLabel => isRu ? 'Название' : 'Name';
  String get tableNameLabel => isRu ? 'Название таблицы' : 'Table name';
  String get tableNameHint =>
      isRu ? 'напр. Бюджет на месяц' : 'e.g. Monthly budget';
  String get createTable => isRu ? 'Создать таблицу' : 'Create table';
  String get untitledTable => isRu ? 'Без названия' : 'Untitled table';
  String get importedTable =>
      isRu ? 'Импортированная таблица' : 'Imported table';
  String get importCsvTitle => isRu ? 'Импорт CSV' : 'Import CSV';
  String get csvDataLabel => isRu ? 'Данные CSV' : 'CSV data';
  String get csvSample => isRu
      ? 'Название,Категория,Сумма\nКофе,Еда,4.50\nБлокнот,Офис,2.99'
      : 'Item,Category,Amount\nCoffee,Food,4.50\nNotebook,Office,2.99';
  String get importInfo => isRu
      ? 'Первая строка станет заголовками столбцов. Поддерживается текст '
          'через запятую, точку с запятой и табуляцию — вставляйте прямо из '
          'Excel или Google Таблиц.'
      : 'The first row becomes the column headers. Comma, semicolon, and tab '
          'separated text are supported — paste straight from Excel or Google '
          'Sheets.';
  String get importErrorPaste => isRu
      ? 'Вставьте данные, начиная со строки заголовков.'
      : 'Paste some data that includes a header row first.';
  String get importAction => isRu ? 'Импортировать' : 'Import';
  String get csvExported => isRu ? 'CSV экспортирован' : 'CSV exported';
  String get exportedTo => isRu ? 'Таблица сохранена в:' : 'Your table was saved to:';
  String get exportedFileHint => isRu
      ? 'Файл можно открыть в Excel, Numbers или Google Таблицах.'
      : 'The file can be opened in Excel, Numbers, or Google Sheets.';
  String get copyCsv => isRu ? 'Копировать CSV' : 'Copy CSV';
  String get csvCopied =>
      isRu ? 'CSV скопирован в буфер обмена' : 'CSV copied to clipboard';
  String get defaultItemColumn => isRu ? 'Название' : 'Item';
  String get defaultCategoryColumn => isRu ? 'Категория' : 'Category';
  String get defaultAmountColumn => isRu ? 'Сумма' : 'Amount';
  String get chartType => isRu ? 'Тип диаграммы' : 'Chart type';
  String get chartBar => isRu ? 'Столбцы' : 'Bar';
  String get chartLine => isRu ? 'Линии' : 'Line';
  String get chartDonut => isRu ? 'Кольцевая' : 'Donut';
  String get categoryAxis => isRu ? 'Категория (ось X)' : 'Category (X axis)';
  String get valueAxis => isRu ? 'Значение (ось Y)' : 'Value (Y axis)';
  String get aggregate => isRu ? 'Агрегация' : 'Aggregate';
  String get aggregationSum => isRu ? 'Сумма' : 'Sum';
  String get aggregationAverage => isRu ? 'Среднее' : 'Average';
  String get aggregationCount => isRu ? 'Количество' : 'Count';
  String get aggregationMin => isRu ? 'Минимум' : 'Min';
  String get aggregationMax => isRu ? 'Максимум' : 'Max';
  String get chooseColumn => isRu ? 'Выберите столбец' : 'Choose a column';
  String get noNumberColumns =>
      isRu ? 'Нет числовых столбцов' : 'No number columns';
  String get notUsedForCount =>
      isRu ? 'Не используется для количества' : 'Not used for Count';
  String get rowsStatLabel => isRu ? 'Строки' : 'Rows';
  String get groupsStatLabel => isRu ? 'Группы' : 'Groups';
  String get largestGroup =>
      isRu ? 'Наибольшая группа' : 'Largest group';
  String get avgPerGroup =>
      isRu ? 'В среднем на группу' : 'Avg per group';
  String get sumStat => isRu ? 'Сумма' : 'Sum';
  String get averageStat => isRu ? 'Среднее' : 'Average';
  String get maxStat => isRu ? 'Максимум' : 'Max';
  String get totalLabel => isRu ? 'Всего' : 'Total';
  String get chartNothingToVisualize =>
      isRu ? 'Пока нечего визуализировать' : 'Nothing to visualize yet';
  String get chartNothingToVisualizeMessage => isRu
      ? 'Добавьте столбцы и строки в режиме «Таблица», затем вернитесь к '
          'построению диаграммы.'
      : 'Add columns and rows in the Table view, then come back to build a '
          'chart.';
  String get chartNoRows =>
      isRu ? 'Нет строк для диаграммы' : 'No rows to chart';
  String get chartNoRowsMessage => isRu
      ? 'Добавьте строки в режиме «Таблица», чтобы увидеть диаграмму.'
      : 'Add some rows in the Table view to see a chart here.';
  String get chartNoRowsFilter =>
      isRu ? 'Нет строк по текущему фильтру' : 'No rows match your filter';
  String get chartNoRowsFilterMessage => isRu
      ? 'Измените поисковый запрос или сбросьте фильтр.'
      : 'Try a different search term or clear the filter.';
  String get chartChooseCategory =>
      isRu ? 'Выберите категорию' : 'Choose a category';
  String get chartChooseCategoryMessage => isRu
      ? 'Выберите столбец для группировки строк.'
      : 'Pick the column that should group your rows.';
  String get chartNoNumeric =>
      isRu ? 'Нет числовых значений' : 'No numeric values';
  String get chartNothingToChart =>
      isRu ? 'Нечего отображать' : 'Nothing to chart';
  String get chartNothingToChartMessage => isRu
      ? 'Попробуйте другую категорию, значение или агрегацию.'
      : 'Try a different category, value, or aggregation.';
  String get chartDonutPositive =>
      isRu ? 'Для кольцевой диаграммы нужны положительные значения'
          : 'Donut charts need positive values';
  String get chartDonutPositiveMessage => isRu
      ? 'В данных есть отрицательные значения. Переключитесь на столбцы или '
          'линии.'
      : 'This data contains negative values. Switch to the Bar or Line chart '
          'to show them.';
  String get chartZeroMessage => isRu
      ? 'Для этой диаграммы нужны значения больше нуля. Попробуйте другую '
          'агрегацию.'
      : 'This chart needs values above zero. Try another aggregation.';
  String get chartOther => isRu ? 'Прочее' : 'Other';
  String get settingsSubtitle => isRu
      ? 'Настройте внешний вид и язык приложения.'
      : "Customize the app's appearance and language.";
  String get closeSettings =>
      isRu ? 'Закрыть настройки' : 'Close settings';
  String get appearanceSection => isRu ? 'Внешний вид' : 'Appearance';
  String get themeLabel => isRu ? 'Тема' : 'Theme';
  String get lightLabel => isRu ? 'Светлая' : 'Light';
  String get darkLabel => isRu ? 'Тёмная' : 'Dark';
  String get languageSection => isRu ? 'Язык' : 'Language';
  String get interfaceLanguageLabel =>
      isRu ? 'Язык интерфейса' : 'Interface language';
  String get languageHint => isRu
      ? 'Выберите язык интерфейса приложения.'
      : 'Choose the language used across the application.';
  String get englishLabel => 'English';
  String get russianLabel => 'Русский';
  String get dataSection => isRu ? 'Данные' : 'Data';
  String get dataDescription => isRu
      ? 'Таблицы хранятся локально на этом компьютере и сохраняются '
          'автоматически.'
      : 'Tables are stored locally on this computer and saved automatically.';
  String get currencyRatesTitle =>
      isRu ? 'Конвертация валют' : 'Currency conversion';
  String get currencyRatesHint => isRu
      ? 'При сортировке валют и расчёте итогов диаграмм используются '
          'приблизительные встроенные курсы.'
      : 'Currency sorting and chart totals use approximate built-in exchange '
          'rates.';
  String get aboutSection => isRu ? 'О приложении' : 'About';
  String get aboutDescription => isRu
      ? 'Лёгкое настольное приложение для создания, организации и '
          'визуализации таблиц данных.'
      : 'A lightweight desktop app for creating, organizing, and visualizing '
          'tables of data.';

  String columnTypeLabel(ColumnType type) {
    switch (type) {
      case ColumnType.text:
        return isRu ? 'Текст' : 'Text';
      case ColumnType.number:
        return isRu ? 'Число' : 'Number';
      case ColumnType.date:
        return isRu ? 'Дата' : 'Date';
      case ColumnType.select:
        return isRu ? 'Список' : 'Select';
      case ColumnType.currency:
        return isRu ? 'Валюта' : 'Currency';
    }
  }

  List<String> get monthNames => isRu
      ? const [
          'Январь',
          'Февраль',
          'Март',
          'Апрель',
          'Май',
          'Июнь',
          'Июль',
          'Август',
          'Сентябрь',
          'Октябрь',
          'Ноябрь',
          'Декабрь',
        ]
      : const [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];

  String tablesCount(int count) =>
      isRu ? '$count ${_plural(count, 'таблица', 'таблицы', 'таблиц')}'
          : '$count ${count == 1 ? 'table' : 'tables'}';

  String rowsCount(int count) =>
      isRu ? '$count ${_plural(count, 'строка', 'строки', 'строк')}'
          : '$count ${count == 1 ? 'row' : 'rows'}';

  String columnsCount(int count) =>
      isRu ? '$count ${_plural(count, 'столбец', 'столбца', 'столбцов')}'
          : '$count ${count == 1 ? 'column' : 'columns'}';

  String groupsCount(int count) =>
      isRu ? '$count ${_plural(count, 'группа', 'группы', 'групп')}'
          : '$count ${count == 1 ? 'group' : 'groups'}';

  String errorsCount(int count) =>
      isRu ? '$count ${_plural(count, 'ошибка', 'ошибки', 'ошибок')}'
          : '$count ${count == 1 ? 'invalid value' : 'invalid values'}';

  String _plural(int count, String one, String few, String many) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) return one;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return few;
    }
    return many;
  }

  String deleteTableMessage(String name, int rowCount) => isRu
      ? '«$name» и ${rowsCount(rowCount)} будут удалены без возможности '
          'восстановления.'
      : '“$name” and its ${rowsCount(rowCount)} will be removed permanently.';

  String deleteColumnMessage(String name) => isRu
      ? 'Столбец «$name» и все его значения будут удалены из этой таблицы.'
      : 'The “$name” column and all of its values will be removed from this '
          'table.';

  String duplicateTableName(String name) =>
      isRu ? '$name (копия)' : '$name copy';

  String optionsFor(String name) =>
      isRu ? 'Варианты для «$name»' : 'Options for “$name”';

  String sortBy(String name) =>
      isRu ? 'Сортировать по «$name»' : 'Sort by $name';

  String tableSummary(
    int rowCount,
    int columnCount,
    DateTime updatedAt,
  ) =>
      '${rowsCount(rowCount)} · ${columnsCount(columnCount)} · '
      '${isRu ? 'Изменено' : 'Edited'} ${relativeTime(updatedAt)}';

  String editedLabel(DateTime time) =>
      '${isRu ? 'Изменено' : 'Edited'} ${relativeTime(time)}';

  String relativeTime(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inSeconds < 45) return isRu ? 'только что' : 'just now';
    if (difference.inMinutes < 60) {
      return isRu
          ? '${difference.inMinutes} мин назад'
          : '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return isRu
          ? '${difference.inHours} ч назад'
          : '${difference.inHours}h ago';
    }
    if (difference.inDays < 30) {
      return isRu
          ? '${difference.inDays} дн назад'
          : '${difference.inDays}d ago';
    }
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    return '$day.$month.${time.year}';
  }

  String shownOf(int visible, int total) => isRu
      ? 'Показано $visible из $total'
      : '$visible of $total shown';

  String invalidValues(int count) => errorsCount(count);

  String loadError(String error) => isRu
      ? 'Не удалось загрузить сохранённые таблицы: $error'
      : 'Could not load your saved tables: $error';

  String exportFailed(Object error) => isRu
      ? 'Не удалось экспортировать таблицу: $error'
      : 'Could not export this table: $error';

  String chartCountTitle(String category) => isRu
      ? 'Количество строк по «$category»'
      : 'Row count by $category';

  String chartAggregateTitle(
    String aggregation,
    String value,
    String category,
  ) =>
      isRu
          ? '$aggregation: $value по «$category»'
          : '$aggregation of $value by $category';

  String chartSubtitle(
    int rowCount,
    int groupCount,
    bool filtered,
  ) {
    final filterSuffix = filtered ? (isRu ? ' · фильтр' : ' · filtered') : '';
    return '${rowsCount(rowCount)} · ${groupsCount(groupCount)}$filterSuffix';
  }

  String chartNoNumericMessage(String valueName) => isRu
      ? 'В столбце «$valueName» нет чисел для агрегации. Выберите другой '
          'столбец значений или измените агрегацию на «Количество».'
      : 'The “$valueName” column has no numbers to aggregate. Try another '
          'value column or switch the aggregation to Count.';

  String chartLineTruncated(int shown, int total) => isRu
      ? 'Показаны первые $shown из $total групп.'
      : 'Showing the first $shown of $total groups.';

  String chartOtherTruncated(int named, int other) => isRu
      ? 'Показаны первые $named групп; остальные ($other) объединены в '
          '«Прочее».'
      : 'Top $named groups shown; the remaining $other grouped as “Other”.';
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'ru';

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
