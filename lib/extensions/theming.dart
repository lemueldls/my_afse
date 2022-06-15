import "package:flutter/material.dart";

extension Material on Color {
  /// Turns colors into material pallets
  MaterialColor get material {
    final swatch = {50: withOpacity(0.1)};

    for (var i = 1; i < 10;) swatch[i * 100] = withOpacity(++i / 10);

    return MaterialColor(value, swatch);
  }
}

extension TextBrightness on Brightness {
  /// Inverts brightness for contrasting text color
  Color get text => this == Brightness.dark ? Colors.white : Colors.black;
}
