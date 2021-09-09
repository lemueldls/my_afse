library my_afse.url;

import "package:url_launcher/url_launcher.dart";

void launchURL(String url) async {
  if (await canLaunch(url)) {
    final view = url.startsWith("http");

    await launch(
      url,
      forceWebView: view,
      forceSafariVC: view,
      enableJavaScript: true,
      enableDomStorage: true,
    );
  } else {
    throw "Could not launch $url";
  }
}
