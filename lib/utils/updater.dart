library my_afse.update;

import "dart:io";

import "package:http/http.dart" as http;
import "package:ota_update/ota_update.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:version/version.dart";

var dismissed = false;
var prompt = false;

Future<String?> checkLatest() async {
  final latest = await _fetchLatest();
  final current = await PackageInfo.fromPlatform();

  if (Version.parse(latest) > Version.parse(current.version)) prompt = true;
}

void update() {
  prompt = false;

  if (Platform.isAndroid)
    OtaUpdate().execute("https://my-afse.deno.dev/app.apk");
}

Future<String> _fetchLatest() async {
  final response = await http.get(Uri.parse("https://my-afse.deno.dev/"));

  if (response.statusCode == 200)
    return response.body;
  else
    throw Exception("Failed to check for updates");
}
