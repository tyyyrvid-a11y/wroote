import 'package:flutter/material.dart';

/// Controla claro/escuro/sistema para o app inteiro. Começa seguindo o
/// tema do sistema operacional e permite alternar manualmente pela
/// Biblioteca.
class ThemeModeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  bool isDark(BuildContext context) {
    if (_mode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _mode == ThemeMode.dark;
  }

  void toggle(BuildContext context) {
    final currentlyDark = isDark(context);
    _mode = currentlyDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
