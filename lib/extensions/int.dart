extension LocaleNumber on int {
  String get ordinal {
    // if (I18n.locale == const Locale("ja"))
    //   // No ordinal number for Japanese
    //   return "$this";

    if (this % 10 == 1) return "${this}st";
    if (this % 10 == 2) return "${this}nd";
    if (this % 10 == 3) return "${this}rd";

    return "${this}th";
  }
}
