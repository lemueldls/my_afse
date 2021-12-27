import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "utils/constants.dart";
import "utils/routes.dart";
import "utils/theme.dart";
import "widgets/scaffold.dart";

/// Contains logic for initializing theme colors and page routes.
class App extends StatelessWidget {
  final bool loggedIn;
  final String page;

  const App({
    required final this.loggedIn,
    required final this.page,
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

    // Helpful for starting up a specific page in debug mode.
    const debugPage = production ? null : "/grades";

    final theme = Provider.of<ThemeChanger>(context);

    final brightness = theme.dark ? Brightness.dark : Brightness.light;
    final color = theme.color;

    return MaterialApp(
      title: "My AFSE",
      theme: ThemeData(
        brightness: brightness,
        primaryColor: color,
        primarySwatch: color,
        snackBarTheme: SnackBarThemeData(actionTextColor: color),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: color,
          cardColor: color,
          brightness: brightness,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith(
            (final states) => _getColor(states, color),
          ),
          trackColor: MaterialStateProperty.resolveWith(
            (final states) => _getColor(states, color)?.shade600,
          ),
        ),
      ),
      routes: routes,
      initialRoute: loggedIn ? debugPage ?? page : "/login",
    );
  }

  MaterialColor? _getColor(
    final Set<MaterialState> states,
    final MaterialColor color,
  ) {
    const interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.selected,
      MaterialState.hovered,
      MaterialState.focused,
    };

    if (states.any(interactiveStates.contains)) return color;
  }
}
