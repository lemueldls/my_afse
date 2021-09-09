library my_afse.api;

import "dart:async";
import "dart:convert";
import "dart:io";

import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";

final _prefs = SharedPreferences.getInstance();

Future? _validated;

Future<List<API>> get<API>(String api) async {
  final prefs = await _prefs;

  final token = prefs.getString("token");
  if (token != null) await validate(token);

  final username = prefs.getString("username");

  final response = await http.get(
    Uri.parse("https://api.jumpro.pe/api/v3/$api/"),
    headers: {
      HttpHeaders.contentTypeHeader: "application/json",
      HttpHeaders.authorizationHeader: "ApiKey $username:$token",
    },
  );

  if (response.statusCode == 200)
    return jsonDecode(utf8.decode(response.bodyBytes))["results"];
  else {
    _validated = null;
    await validate(token!);

    return await get(api);
  }
}

Future<LoginResponse> login(String username, String password) async {
  final prefs = await _prefs;

  final loginRes = await http.post(
    Uri.parse("https://nyc3.jumpro.pe/account/login/"),
    body: {"username": username, "password": password, "module": "Portal"},
  );
  final response = LoginResponse.fromJson(jsonDecode(loginRes.body));

  if (response.success) await prefs.setString("token", response.token!);

  return response;
}

Future<void> logout() async {
  _validated = null;

  final prefs = await _prefs;

  final crisis = prefs.getStringList("crisis") ?? const [""];
  await prefs.clear();
  await prefs.setStringList("crisis", crisis);
}

Future<ValidateResponse> validate(String token) async {
  final prefs = await _prefs;

  final username = prefs.getString("username");

  if (await _validated == true)
    return ValidateResponse(success: true, username: username);

  // I hope this is smart
  final completer = Completer();
  _validated = completer.future;

  final validateRes = await http
      .get(Uri.parse("https://api.jumpro.pe/account/validate_token?st=$token"));
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
  final String? type;
  final String? message;
  final String? token;

  const LoginResponse({
    required this.success,
    required this.type,
    required this.message,
    required this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        success: json["success"],
        type: json["type"],
        message: json["message"],
        token: json["services_token"],
      );

  @override
  toString() => "{ $success, $type, $message, $token }";
}

class ValidateResponse {
  final bool success;
  final String? username;

  const ValidateResponse({required this.success, required this.username});

  factory ValidateResponse.fromJson(Map<String, dynamic> json) =>
      ValidateResponse(
        success: json["success"],
        username: json["username"],
      );

  @override
  String toString() => "{ $success, $username }";
}
