import "package:flutter/material.dart";
import "package:flutter_colorpicker/flutter_colorpicker.dart";
import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../utils/routes.dart";
import "../utils/settings.dart";
import "../utils/theme.dart";

class SettingsPage extends StatefulWidget {
  const SettingsPage({final Key? key}) : super(key: key);

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final _prefs = SharedPreferences.getInstance();

  String _page = settings.page;

  late bool _dark;
  late Color _color;

  @override
  Widget build(final BuildContext context) {
    final theme = Provider.of<ThemeChanger>(context);

    _dark = theme.dark;
    _color = theme.color;

    final textStyle = TextStyle(
      color: _dark ? Colors.white : Colors.black,
      fontWeight: FontWeight.bold,
    );
    const titlePadding = EdgeInsets.only(
      top: 16,
      left: 16,
      right: 16,
      bottom: 8,
    );

    final pageItems = pageRoutes.keys.toList();
    pageItems.removeRange(pageItems.length - 2, pageItems.length);

    return Align(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 750),
        child: SettingsList(
          backgroundColor: Colors.transparent,
          physics: const BouncingScrollPhysics(),
          contentPadding: const EdgeInsets.all(8),
          sections: [
            SettingsSection(
              title: "Theme",
              titleTextStyle: textStyle,
              titlePadding: titlePadding,
              tiles: [
                SettingsTile.switchTile(
                  title: "Dark Mode",
                  leading: const Icon(Icons.dark_mode),
                  switchValue: _dark,
                  onToggle: (final dark) => setState(() {
                    theme.setDark(_dark = dark);
                  }),
                ),
                SettingsTile(
                  title: "Accent Color",
                  leading: const Icon(Icons.palette),
                  trailing: Container(
                    width: 64,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: (final context) => _selectColor(context, theme),
                ),
              ],
            ),
            SettingsSection(
              title: "Startup",
              titleTextStyle: textStyle,
              titlePadding: titlePadding,
              tiles: [
                SettingsTile(
                  title: "Default Page",
                  leading: const Icon(Icons.pages),
                  trailing: DropdownButton<String>(
                    value: _page,
                    onChanged: (final page) async {
                      setState(() => _page = page!);

                      final prefs = await _prefs;
                      await prefs.setString("page", page!);
                    },
                    items: pageItems.map(
                      (final route) {
                        final page = pageRoutes[route]!;

                        return DropdownMenuItem(
                          value: route,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: page.icon,
                              ),
                              Text(page.title),
                            ],
                          ),
                        );
                      },
                    ).toList(growable: false),
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: "More Info",
              titleTextStyle: textStyle,
              titlePadding: titlePadding,
              tiles: [
                SettingsTile(
                  title: "About",
                  leading: const Icon(Icons.info),
                  onPressed: (final context) async {
                    final info = await PackageInfo.fromPlatform();

                    if (!mounted) return;

                    showAboutDialog(
                      context: context,
                      applicationVersion: info.version,
                      applicationIcon: Image.asset(
                        "assets/icon/icon.png",
                        width: 48,
                        height: 48,
                      ),
                      children: [
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.subtitle1,
                            children: const [
                              TextSpan(
                                text: "The AFSE integrated JumpRope client.",
                              ),
                              TextSpan(
                                text: "\n\nMade By: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              // Yours truly
                              TextSpan(text: "Lemuel De Los Santos"),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectColor(final BuildContext context, final ThemeChanger theme) {
    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        actionsPadding: const EdgeInsets.only(right: 6),
        content: SingleChildScrollView(
          child: MaterialPicker(
            enableLabel: true,
            pickerColor: _color,
            onColorChanged: (final color) {
              setState(() {
                theme.setColor(color);
              });

              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }
}
