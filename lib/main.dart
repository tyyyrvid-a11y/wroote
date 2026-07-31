import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import 'screens/library_screen.dart';
import 'services/library_provider.dart';
import 'services/sound_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WrooteApp());
}

/// Comportamento de rolagem de desktop: barra de rolagem sempre presente e
/// arrasto com o mouse habilitado. O padrão do Flutter esconde a barra em
/// desktop, o que deixa listas longas sem nenhuma indicação de posição.
class _DesktopScrollBehavior extends MaterialScrollBehavior {
  const _DesktopScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class WrooteApp extends StatelessWidget {
  const WrooteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeModeController()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        // `init()` carrega preferências e prepara os players de áudio; roda
        // em segundo plano porque nada na tela depende dele.
        ChangeNotifierProvider(create: (_) => SoundService()..init()),
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
            scrollBehavior: const _DesktopScrollBehavior(),
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
