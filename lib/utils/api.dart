library my_afse.api;

import "dart:async";
import "dart:convert";
import "dart:io";

import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";
import "package:universal_html/parsing.dart";

import "./constants.dart";

final _prefs = SharedPreferences.getInstance();

Future? _validated;

Future<List<API>> get<API>(final String api) async {
  final prefs = await _prefs;

  final token = prefs.getString("token");
  if (token != null) await validate(token);

  final username = prefs.getString("username");

  final response = await http.get(
    Uri.parse("https://api.jumpro.pe/api/v3/$api/"),
    headers: {
      ...userAgentHeader,
      HttpHeaders.contentTypeHeader: "application/json",
      HttpHeaders.authorizationHeader: "ApiKey $username:$token",
    },
  );

  if (response.statusCode == 200)
    return jsonDecode(utf8.decode(response.bodyBytes))["results"];
  else {
    _validated = null;
    await validate(token!);

    return get(api);
  }
}

Future<LoginResponse> login(
    final String username, final String password) async {
  final prefs = await _prefs;

  try {
    const headers = {
      ...userAgentHeader,
      HttpHeaders.contentTypeHeader: "application/x-www-form-urlencoded",
    };
    final request =
        http.Request("POST", Uri.parse("https://services.jumpro.pe/login/"))
          ..bodyFields = {"username": username, "password": password}
          ..followRedirects = false
          ..headers.addAll(headers);

    final http.StreamedResponse response = await request.send();

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

  final crisis = prefs.getStringList("crisis") ?? const [""];
  await prefs.clear();
  await prefs.setStringList("crisis", crisis);
}

Future<ValidateResponse> validate(final String token) async {
  final prefs = await _prefs;

  final username = prefs.getString("username");

  if (await _validated == true)
    return ValidateResponse(success: true, username: username);

  // I hope this is smart
  final completer = Completer();
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
    final user = await login(username!, prefs.getString("auth")!);

    return validate(user.token!);
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
  toString() => "{ $success, $message, $token }";
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
