import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import 'screens/library_screen.dart';
import 'services/library_provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WrooteApp());
}

class WrooteApp extends StatelessWidget {
  const WrooteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeModeController()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
      ],
      child: Builder(
        builder: (context) {
          final themeModeController = context.watch<ThemeModeController>();
          return MaterialApp(
            title: 'Wroote',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeModeController.mode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [Locale('pt'), Locale('en')],
            locale: const Locale('pt'),
            home: const LibraryScreen(),
          );
        },
      ),
    );
  }
}
