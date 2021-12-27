import "package:flutter/material.dart";
import "package:flutter_shortcuts/flutter_shortcuts.dart";
import "package:provider/provider.dart";
import "package:pull_to_refresh/pull_to_refresh.dart";

import "app.dart";
import "utils/settings.dart";
import "utils/student.dart";
import "utils/theme.dart";

Future<void> main() async {
  // Helps to initialize top-level shared preferences correctly.
  WidgetsFlutterBinding.ensureInitialized();

  // Load theme and page settings.
  await initializeSettings();

  // Run the app builder.
  runApp(const AppBuilder());
}

class AppBuilder extends StatefulWidget {
  const AppBuilder({final Key? key}) : super(key: key);

  @override
  _AppBuilderState createState() => _AppBuilderState();
}

class _AppBuilderState extends State<AppBuilder> {
  String _page = settings.page;

  final shortcuts = FlutterShortcuts();

  @override
  Widget build(final BuildContext context) => FutureBuilder<bool>(
        future: initializeStudent(),
        builder: (final context, final snapshot) {
          if (snapshot.hasError) return Text("${snapshot.error}");
          if (snapshot.connectionState == ConnectionState.waiting) {
            return MaterialApp(
              theme: ThemeData(
                brightness: settings.dark ? Brightness.dark : Brightness.light,
                primaryColor: settings.color,
              ),
              home: const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          // Create an automatic theme changer
          return ChangeNotifierProvider(
            create: (final context) => ThemeChanger(),
            // Global refresh indicator configuration
            child: RefreshConfiguration(
              headerBuilder: () => const WaterDropMaterialHeader(),
              enableRefreshVibrate: true,
              // Load the app with the authencation state
              child: App(loggedIn: snapshot.data!, page: _page),
            ),
          );
        },
      );

  @override
  void initState() {
    super.initState();

    _loadShortcuts();
  }

  /// Listens if the user opens the app using a shortcut, and navigates
  void _loadShortcuts() => shortcuts
    ..initialize()
    ..listenAction((final page) => setState(() => _page = page))
    ..setShortcutItems(
      shortcutItems: const [
        ShortcutItem(
          id: "profile",
          action: "/profile",
          shortLabel: "Profile",
          icon: "assets/shortcut/profile.png",
        ),
        ShortcutItem(
          id: "home",
          action: "/home",
          shortLabel: "Home",
          icon: "assets/shortcut/home.png",
        ),
        ShortcutItem(
          id: "schedule",
          action: "/schedule",
          shortLabel: "Schedule",
          icon: "assets/shortcut/schedule.png",
        ),
        ShortcutItem(
          id: "grades",
          action: "/grades",
          shortLabel: "Grades",
          icon: "assets/shortcut/grades.png",
        ),
        ShortcutItem(
          id: "attendance",
          action: "/attendance",
          shortLabel: "Attendance",
          icon: "assets/shortcut/attendance.png",
        ),
        // ShortcutItem(
        //   id: "settings",
        //   action: "/settings",
        //   shortLabel: "Settings",
        //   icon: "assets/shortcut/settings.png",
        // ),
      ],
    );
}
