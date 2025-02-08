import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:pull_to_refresh/pull_to_refresh.dart";

import "utils/analytics.dart";
import "utils/constants.dart";
import "utils/routes.dart";
import "utils/theme.dart";
import "widgets/scaffold.dart";

/// Contains logic for initializing theme colors and page routes.
class App extends StatelessWidget {
  final bool loggedIn;
  final String page;

  const App({
    required this.loggedIn,
    required this.page,
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    /// Remapped pages into a routing table.
    final routes = pageRoutes.map(
      (final key, final route) => MapEntry(
        key,
        (final context) {
          final page = route.page;

          return route.wrap
              ? PageScaffold(title: route.title, page: page)
              : page;
        },
      ),
    );

    /// Helpful for starting up a specific page in debug mode.
    const debugPage = isProduction ? null : "/grades";

    final theme = Provider.of<ThemeChanger>(context);

    final brightness = theme.dark ? Brightness.dark : Brightness.light;
    final color = theme.color;

    final themeData = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: color,
      brightness: brightness,
    );

    final colorScheme = themeData.colorScheme;

    return RefreshConfiguration(
      headerBuilder: () => WaterDropMaterialHeader(
        backgroundColor: themeData.colorScheme.primaryContainer,
        color: themeData.colorScheme.onPrimaryContainer,
      ),
      enableRefreshVibrate: true,
      // Load app with the current authentication state
      child: MaterialApp(
        title: "My AFSE",
        theme: themeData.copyWith(
          listTileTheme: ListTileThemeData(
            selectedColor: colorScheme.onSecondaryContainer,
            selectedTileColor: colorScheme.secondaryContainer,
          ),
          cardTheme: const CardTheme(
            margin: EdgeInsets.symmetric(vertical: 8),
          ),
          switchTheme: SwitchThemeData(
            thumbColor: MaterialStateProperty.resolveWith(
              (final states) =>
                  _generateSwitchStates(states, colorScheme.secondary),
            ),
            trackColor: MaterialStateProperty.resolveWith(
              (final states) =>
                  _generateSwitchStates(states, colorScheme.onSecondary),
            ),
          ),
        ),
        routes: routes,
        initialRoute: loggedIn ? debugPage ?? page : "/login",
        navigatorObservers: observer,
      ),
    );
  }

  /// Used to get colors for switch states.
  Color? _generateSwitchStates(
    final Set<MaterialState> states,
    final Color color,
  ) {
    const interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.selected,
      MaterialState.hovered,
      MaterialState.focused,
    };

    // If the state is interactive, then return the color.
    if (states.any(interactiveStates.contains)) return color;

    return null;
  }
}
