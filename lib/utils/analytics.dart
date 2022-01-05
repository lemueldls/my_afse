library my_afse.analytics;

import "package:firebase_analytics/firebase_analytics.dart";
import "package:flutter/material.dart";

import "constants.dart";
import "routes.dart";

late final analytics = production ? FirebaseAnalytics.instance : null;

late final List<NavigatorObserver> observer = production
    ? [
        FirebaseAnalyticsObserver(
          analytics: analytics!,
          nameExtractor: (final settings) => pageRoutes[settings.name]!.title,
        ),
      ]
    : const [];
