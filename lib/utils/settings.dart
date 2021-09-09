library my_afse.settings;

import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../extensions/color.dart";

late Settings settings;

final _prefs = SharedPreferences.getInstance();

Future<void> updateSettings() async {
  final prefs = await _prefs;

  String? page = prefs.getString("page");
  if (page == null) await prefs.setString("page", page = "/home");

  int? color = prefs.getInt("color");
  if (color == null) await prefs.setInt("color", color = 0xff007bb0);

  bool? dark = prefs.getBool("dark");
  if (dark == null)
    await prefs.setBool(
      "dark",
      dark = SchedulerBinding.instance!.window.platformBrightness ==
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
