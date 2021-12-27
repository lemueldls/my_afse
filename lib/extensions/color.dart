import "package:flutter/material.dart";

extension Material on Color {
  /// Turns colors into material palletes
  MaterialColor get material {
    final swatch = {50: withOpacity(0.1)};

    for (var i = 1; i < 10;) swatch[i * 100] = withOpacity(++i / 10);

    return MaterialColor(value, swatch);
  }
}
