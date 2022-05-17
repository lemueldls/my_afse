library my_afse.url;

import "package:url_launcher/url_launcher_string.dart";

/// Opens urls using the prospective device handler.
/// When the url is a website, it opens an internal
/// browser in the app instead of launching seperate one.
Future<void> launchURL(final String url) async {
  final view = url.startsWith("http");

  await launchUrlString(
    url,
    mode: view ? LaunchMode.inAppWebView : LaunchMode.platformDefault,
  );
}
