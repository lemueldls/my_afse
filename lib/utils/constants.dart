library my_afse.cosntants;

import "dart:io";

import "package:flutter/foundation.dart" as foundation;

const production = foundation.kReleaseMode;

const userAgentHeader = {
  HttpHeaders.userAgentHeader: "Mozilla/5.0 (X11; Linux x86_64) Gecko/20100101",
};
