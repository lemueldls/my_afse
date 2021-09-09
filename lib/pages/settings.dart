import "package:flutter/material.dart";
import "package:flutter_colorpicker/flutter_colorpicker.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";
import "package:settings_ui/settings_ui.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../utils/routes.dart";
import "../utils/settings.dart";
import "../utils/theme.dart";

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _prefs = SharedPreferences.getInstance();

  String _page = settings.page;

  late bool _dark;
  late Color _color;

  @override
  build(context) {
    final theme = Provider.of<ThemeChanger>(context);

    _dark = theme.dark;
    _color = theme.color;

    final textStyle = TextStyle(
      color: _dark ? Colors.white : Colors.black,
      fontWeight: FontWeight.bold,
    );
    const titlePadding = EdgeInsets.only(
      top: 16.0,
      left: 16.0,
      right: 16.0,
      bottom: 8.0,
    );

    final pageItems = pageRoutes.keys.toList();
    pageItems.removeRange(pageItems.length - 2, pageItems.length);

    return Align(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 750.0),
        child: SettingsList(
          backgroundColor: Colors.transparent,
          physics: const BouncingScrollPhysics(),
          contentPadding: const EdgeInsets.all(8.0),
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
                  onToggle: (dark) => setState(() {
                    theme.setDark(_dark = dark);
                  }),
                ),
                SettingsTile(
                  title: "Accent Color",
                  leading: const Icon(Icons.palette),
                  trailing: Container(
                    width: 64.0,
                    height: 32.0,
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  onPressed: (context) => _selectColor(context, theme),
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
                  trailing: DropdownButton(
                    value: _page,
                    onChanged: (String? page) async {
                      setState(() => _page = page!);

                      final prefs = await _prefs;
                      prefs.setString("page", page!);
                    },
                    items: pageItems.map(
                      (route) {
                        final page = pageRoutes[route]!;

                        return DropdownMenuItem(
                          value: route,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: page.icon!,
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
                  onPressed: (context) async {
                    final info = await PackageInfo.fromPlatform();

                    showAboutDialog(
                      context: context,
                      applicationVersion: info.version,
                      applicationIcon: Image.asset(
                        "assets/icon/icon.png",
                        width: 48.0,
                        height: 48.0,
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

  void _selectColor(BuildContext context, ThemeChanger theme) {
    var pickerColor = _color;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actionsPadding: const EdgeInsets.only(right: 6.0),
        // title: const Text("Pick a color!""),
        content: SingleChildScrollView(
          child: MaterialPicker(
            enableLabel: true,
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
          ),
        ),
        actions: [
          TextButton(
            child: const Text("SELECT"),
            onPressed: () {
              setState(() {
                theme.setColor(_color = pickerColor);
              });

              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
