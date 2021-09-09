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

  const App({Key? key, required this.loggedIn, required this.page})
      : super(key: key);

  @override
  build(context) {
    final routes = pageRoutes.map(
      (key, route) => MapEntry(
        key,
        (BuildContext context) {
          final page = route.page;

          return route.wrap
              ? PageScaffold(title: route.title, page: page)
              : page;
        },
      ),
    );

    const debugPage = production ? null : "/home";

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
            (states) => _getColor(states, color),
          ),
          trackColor: MaterialStateProperty.resolveWith(
            (states) => _getColor(states, color)?.shade600,
          ),
        ),
      ),
      routes: routes,
      initialRoute: loggedIn ? debugPage ?? page : "/login",
      navigatorObservers: observer,
    );
  }

  MaterialColor? _getColor(Set<MaterialState> states, MaterialColor color) {
    const interactiveStates = {
      MaterialState.pressed,
      MaterialState.selected,
      MaterialState.hovered,
      MaterialState.focused,
    };

    if (states.any(interactiveStates.contains)) return color;
  }
}
