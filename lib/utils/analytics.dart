library my_afse.analytics;

import "package:firebase_analytics/firebase_analytics.dart";
import "package:firebase_analytics/observer.dart";
import "package:flutter/material.dart";

import "constants.dart";
import "routes.dart";

late final analytics = production ? FirebaseAnalytics() : null;

late final List<NavigatorObserver> observer = production
    ? [
        FirebaseAnalyticsObserver(
          analytics: analytics!,
          nameExtractor: (settings) => pageRoutes[settings.name]!.title,
        ),
      ]
    : const [];
