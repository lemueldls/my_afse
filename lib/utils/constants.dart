library my_afse.cosntants;

import "dart:io";

import "package:flutter/foundation.dart" as foundation;

/// Check if the current enviorment is a production build.
const production = foundation.kReleaseMode;

/// JumpRope, one day, decided to only allow browser requests for thier API.
/// Setting a custom user agent fakes creating a request from a browser.
const userAgentHeader = {
  HttpHeaders.userAgentHeader: "Mozilla/5.0 (X11; Linux x86_64) Gecko/20100101",
};
