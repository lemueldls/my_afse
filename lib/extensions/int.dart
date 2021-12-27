extension LocaleNumber on int {
  /// Gets the ordinal format of a number
  String get ordinal {
    // if (I18n.locale == const Locale("ja"))
    //   // No ordinal number for Japanese
    //   return "$this";

    final digit = this % 10;

    if (digit == 1) return "${this}st";
    if (digit == 2) return "${this}nd";
    if (digit == 3) return "${this}rd";

    return "${this}th";
  }
}
