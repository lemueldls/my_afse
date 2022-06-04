import "package:flutter/material.dart";

extension Contrast on ThemeData {
  bool get isPrimaryContrastingOnBrightness {
    final luminance = primaryColor.computeLuminance();

    return brightness == Brightness.dark ? luminance >= 0.2 : luminance <= 0.55;
  }

  /// Gets a contrasting alternative to the current primary color.
  Color get primaryTextContrast => isPrimaryContrastingOnBrightness
      // Contrast is good enough to use the primary color
      ? primaryColor
      // Is it in dark mode
      : brightness == Brightness.dark
          // Use a lighter version of the primary color
          ? primaryColorLight
          // If the darker version of the primary color
          // is considered dark enough to use as contrast
          : ThemeData.estimateBrightnessForColor(primaryColorDark) ==
                  Brightness.dark
              // Use the darker version
              ? primaryColorDark
              // Use a shade of grey
              : Colors.grey.shade500;

  Color get textContrastOnPrimary =>
      primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
}

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
