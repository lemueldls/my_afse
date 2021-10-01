import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "utils/analytics.dart";
import "utils/constants.dart";
import "utils/routes.dart";
import "utils/theme.dart";
import "widgets/scaffold.dart";

class App extends StatelessWidget {
  final bool loggedIn;
  final String page;

  const App({
    final Key? key,
    required final this.loggedIn,
    required final this.page,
  }) : super(key: key);

  @override
  build(final context) {
    final routes = pageRoutes.map(
      (final key, final route) => MapEntry(
        key,
        (final BuildContext context) {
          final page = route.page;

          return route.wrap
              ? PageScaffold(title: route.title, page: page)
              : page;
        },
      ),
    );

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
      navigatorObservers: observer,
    );
  }

  MaterialColor? _getColor(
    final Set<MaterialState> states,
    final MaterialColor color,
  ) {
    const interactiveStates = {
      MaterialState.pressed,
      MaterialState.selected,
      MaterialState.hovered,
      MaterialState.focused,
    };

    if (states.any(interactiveStates.contains)) return color;
  }
}
