library my_afse.analytics;

import "package:firebase_analytics/firebase_analytics.dart";
import "package:flutter/material.dart";

import "constants.dart";
import "routes.dart";

final analytics = production ? FirebaseAnalytics.instance : null;

final observer = production
    // Use analytics when building in production mode.
    ? [
        FirebaseAnalyticsObserver(
          analytics: analytics!,
          nameExtractor: (final settings) => pageRoutes[settings.name]!.title,
        ),
      ]
    : const <NavigatorObserver>[];
