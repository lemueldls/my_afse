import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter/material.dart";
import "package:flutter_shortcuts/flutter_shortcuts.dart";
import "package:provider/provider.dart";
import "package:pull_to_refresh/pull_to_refresh.dart";

import "app.dart";
import "utils/settings.dart";
import "utils/student.dart";
import "utils/theme.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    Firebase.initializeApp(),
    updateSettings(),
    updateStudent(),
  ]);

  runApp(const AppBuilder());
}

class AppBuilder extends StatefulWidget {
  const AppBuilder({final Key? key}) : super(key: key);

  @override
  _AppBuilderState createState() => _AppBuilderState();
}

class _AppBuilderState extends State<AppBuilder> {
  String _page = settings.page;

  final flutterShortcuts = FlutterShortcuts();

  @override
  build(final context) => StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (final context, final snapshot) {
          if (snapshot.hasError) return Text("${snapshot.error}");
          if (snapshot.connectionState == ConnectionState.waiting)
            return MaterialApp(
              theme: ThemeData(
                brightness: settings.dark ? Brightness.dark : Brightness.light,
                primaryColor: settings.color,
              ),
              home: const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );

          return ChangeNotifierProvider(
            create: (final context) => ThemeChanger(),
            child: RefreshConfiguration(
              headerBuilder: () => const WaterDropMaterialHeader(),
              enableRefreshVibrate: true,
              child: App(loggedIn: snapshot.data != null, page: _page),
            ),
          );
        },
      );

  @override
  void initState() {
    super.initState();

    _loadShortcuts();
  }

  void _loadShortcuts() => flutterShortcuts
    ..initialize()
    ..listenAction((final page) => setState(() => _page = page))
    ..setShortcutItems(
      shortcutItems: const [
        // FlutterShortcutItem(
        //   id: "settings",
        //   action: "/settings",
        //   shortLabel: "Settings",
        //   icon: "assets/shortcut/settings.png",
        // ),
        FlutterShortcutItem(
          id: "attendance",
          action: "/attendance",
          shortLabel: "Attendance",
          icon: "assets/shortcut/attendance.png",
        ),
        FlutterShortcutItem(
          id: "grades",
          action: "/grades",
          shortLabel: "Grades",
          icon: "assets/shortcut/grades.png",
        ),
        FlutterShortcutItem(
          id: "schedule",
          action: "/schedule",
          shortLabel: "Schedule",
          icon: "assets/shortcut/schedule.png",
        ),
        FlutterShortcutItem(
          id: "home",
          action: "/home",
          shortLabel: "Home",
          icon: "assets/shortcut/home.png",
        ),
        FlutterShortcutItem(
          id: "profile",
          action: "/profile",
          shortLabel: "Profile",
          icon: "assets/shortcut/profile.png",
        ),
      ],
    );
}
