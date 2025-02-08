library my_afse.settings;

import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../extensions/theming.dart";

late Settings settings;

final _prefs = SharedPreferences.getInstance();

/// Initialize page and theme with local settings,
/// otherwise using default values.
Future<void> updateSettings() async {
  final prefs = await _prefs;

  var page = prefs.getString("page");
  if (page == null)
    // Default to home page.
    await prefs.setString("page", page = "/home");

  var color = prefs.getInt("color");
  if (color == null)
    // Default to blue.
    await prefs.setInt("color", color = 0xff25aae2);

  var dark = prefs.getBool("dark");
  if (dark == null)
    // Default to device dark mode.
    await prefs.setBool(
      "dark",
      dark = WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
    );

  settings = Settings(
    page: page,
    color: Color(color).material,
    dark: dark,
  );
}

class Settings {
  final String page;
  final MaterialColor color;
  final bool dark;

  const Settings({
    required this.page,
    required this.color,
    required this.dark,
  });
}
