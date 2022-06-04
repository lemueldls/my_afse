library my_afse.api;

import "dart:async";
import "dart:convert";
import "dart:io";

import "package:hive_flutter/hive_flutter.dart";
import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";
import "package:universal_html/parsing.dart";

/// JumpRope, one day, decided to only allow browser requests for their API.
/// Setting a custom user agent fakes creating a request from a browser.
const userAgentHeader = {
  HttpHeaders.userAgentHeader: "Mozilla/5.0 (X11; Linux x86_64) Gecko/20100101",
};

final cacheBox = Hive.openLazyBox<String>("cache");

final _prefs = SharedPreferences.getInstance();

Future<bool>? _validated;

/// Fetch from the JumpRope API.
Stream<List<Map<String, API>>> getApi<API>(final String api) async* {
  final prefs = await _prefs;

  final token = prefs.getString("token");
  await validate(token!);

  final username = prefs.getString("username");

  final stream = getCached(
    "https://api.jumpro.pe/api/v3/$api/",
    headers: {
      HttpHeaders.contentTypeHeader: "application/json",
      HttpHeaders.authorizationHeader: "ApiKey $username:$token",
    },
  );

  await for (final response in stream)
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> results = data["results"];

      yield results
          .map<Map<String, API>>((final result) => result)
          .toList(growable: false);
    } else {
      _validated = null;
      await validate(token);

      await for (final data in getApi<API>(api)) yield data;
    }
}

Stream<http.Response> getCached(
  final String url, {
  final Map<String, String>? headers,
}) async* {
  final cache = await cacheBox;

  final cached = await cache.get(url);
  final hasCached = cached != null;

  if (hasCached) yield http.Response(cached, 200);

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        ...userAgentHeader,
        if (headers != null) ...headers,
      },
    );

    if (response.statusCode == 200) {
      final body = response.body;

      await cache.put(url, body);

      yield response;
    }
  } on Exception {
    if (!hasCached) rethrow;
  }
}

Future<LoginResponse> login(
  final String username,
  final String auth,
) async {
  final prefs = await _prefs;

  try {
    const headers = {
      ...userAgentHeader,
      HttpHeaders.contentTypeHeader: "application/x-www-form-urlencoded",
    };
    final request =
        http.Request("POST", Uri.parse("https://services.jumpro.pe/login/"))
          ..bodyFields = {"username": username, "password": auth}
          ..followRedirects = false
          ..headers.addAll(headers);

    final response = await request.send();

    if (response.statusCode == 200) {
      final error = parseHtmlDocument(await response.stream.bytesToString())
          .querySelector(".text-danger")!
          .innerText;

      return LoginResponse(success: false, message: error, token: null);
    } else {
      final token =
          Uri.parse(response.headers["location"]!).queryParameters["st"]!;

      await prefs.setString("token", token);

      return LoginResponse(success: true, message: null, token: token);
    }
  } on Exception {
    return const LoginResponse(
      success: false,
      message: "Failed to login",
      token: null,
    );
  }
}

Future<void> logout() async {
  _validated = null;

  final prefs = await _prefs;

  /// Avoid crisis hacking.
  final crisis = prefs.getStringList("crisis") ?? const [""];
  await prefs.clear();
  await prefs.setStringList("crisis", crisis);
}

/// Check if the current token is expired or not.
Future<ValidateResponse> validate(final String token) async {
  final prefs = await _prefs;

  final username = prefs.getString("username");

  if (await _validated ?? false)
    return ValidateResponse(success: true, username: username);

  /// Set the validation state to an asynchronous value so we only
  /// have to send a network request to check once, when multiple
  /// validations are also running at the same time.
  final completer = Completer<bool>();
  _validated = completer.future;

  final validateRes = await http.get(
    Uri.parse("https://api.jumpro.pe/account/validate_token?st=$token"),
    headers: userAgentHeader,
  );
  final response = ValidateResponse.fromJson(jsonDecode(validateRes.body));

  if (response.success) {
    completer.complete(true);

    return response;
  } else {
    final auth = prefs.getString("auth");
    final user = await login(username!, auth!);

    // Recursive validation with a new, working, token.
    final validated = validate(user.token!);
    completer.complete(true);

    return validated;
  }
}

class LoginResponse {
  final bool success;
  final String? message;
  final String? token;

  const LoginResponse({
    required final this.success,
    required final this.message,
    required final this.token,
  });

  factory LoginResponse.fromJson(final Map<String, dynamic> json) =>
      LoginResponse(
        success: json["success"],
        message: json["message"],
        token: json["services_token"],
      );

  @override
  String toString() => "{ $success, $message, $token }";
}

class ValidateResponse {
  final bool success;
  final String? username;

  const ValidateResponse({
    required final this.success,
    required final this.username,
  });

  factory ValidateResponse.fromJson(final Map<String, dynamic> json) =>
      ValidateResponse(
        success: json["success"],
        username: json["username"],
      );

  @override
  String toString() => "{ $success, $username }";
}
