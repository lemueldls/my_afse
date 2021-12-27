library my_afse.theme;

import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../extensions/color.dart";
import "settings.dart";

class ThemeChanger extends ChangeNotifier {
  final _prefs = SharedPreferences.getInstance();

  final _settings = settings;
  late bool _dark = _settings.dark;
  late MaterialColor _color = _settings.color;

  ThemeChanger();

  MaterialColor get color => _color;
  bool get dark => _dark;

  Future<void> setColor(final Color color) async {
    _color = color.material;

    notifyListeners();

    final prefs = await _prefs;

    await prefs.setInt("color", color.value);
    await initializeSettings();
  }

  Future<void> setDark(final bool dark) async {
    _dark = dark;

    notifyListeners();

    final prefs = await _prefs;

    await prefs.setBool("dark", dark);
    await initializeSettings();
  }
}
