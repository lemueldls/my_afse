import "package:flutter/material.dart";

extension TextBrightness on Brightness {
  /// Inverts brightness for contrasting text color
  Color get text => this == Brightness.dark ? Colors.white : Colors.black;
}
