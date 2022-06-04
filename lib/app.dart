import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "extensions/theming.dart";
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

    /// Helpful for starting up a specific page in debug mode.
    const debugPage = production ? null : "/home";

    final theme = Provider.of<ThemeChanger>(context);

    final brightness = theme.dark ? Brightness.dark : Brightness.light;
    final color = theme.color;

    final contrast = ThemeData.estimateBrightnessForColor(color);

    final themeData = ThemeData(
      brightness: brightness,
      primaryColor: color,
      primarySwatch: color,
    );

    return MaterialApp(
      title: "My AFSE",
      theme: themeData.copyWith(
        appBarTheme: AppBarTheme(
          foregroundColor: contrast.text,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(primary: themeData.primaryTextContrast),
        ),
        snackBarTheme: SnackBarThemeData(
          actionTextColor:
              // If the theme is light on dark
              themeData.isPrimaryContrastingOnBrightness
                  // Use a shade of grey
                  ? Colors.grey.shade500
                  // Fallback to the primary color
                  : null,
        ),
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
      navigatorObservers: observer,
    );
  }

  /// Used to get colors for switch states.
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

    // If the state is interactive, then return the color.
    if (states.any(interactiveStates.contains)) return color;

    return null;
  }
}
