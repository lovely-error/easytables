import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'state/app_state.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EasyTablesApp());
}

class EasyTablesApp extends StatefulWidget {
  const EasyTablesApp({super.key});

  @override
  State<EasyTablesApp> createState() => _EasyTablesAppState();
}

class _EasyTablesAppState extends State<EasyTablesApp>
    with WidgetsBindingObserver {
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _state = AppState(StorageService());
    unawaited(_state.initialize());
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    await _state.flush();
    return AppExitResponse.exit;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: ListenableBuilder(
        listenable: _state,
        builder: (context, _) {
          return MaterialApp(
            title: 'EasyTables',
            onGenerateTitle: (context) => context.l10n.appName,
            debugShowCheckedModeBanner: false,
            locale: Locale(_state.languageCode),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            themeMode: _state.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
