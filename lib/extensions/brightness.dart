import "package:flutter/material.dart";

extension TextBrightness on Brightness {
  Color get text => this == Brightness.dark ? Colors.white : Colors.black;
}
