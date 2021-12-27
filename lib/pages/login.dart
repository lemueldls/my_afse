import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../utils/api.dart" as api;
import "../utils/settings.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({final Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = LabeledGlobalKey<FormState>("Form");

  final _prefs = SharedPreferences.getInstance();

  /// Validator for email.
  final _emailFilter = TextEditingController();

  /// Validator for password.
  final _passwordFilter = TextEditingController();

  /// Keyboard focus
  final _focus = FocusNode();

  String _email = "";
  String _password = "";
  bool _passwordVisible = false;
  String _error = "";
  bool _loading = false;

  void authencate(final String username, final String password) {
    Navigator.of(context).pushReplacementNamed(settings.page);
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("JumpRope Login"),
      ),
      body: Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            width: 375,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Image.asset(
                                "assets/img/jumprope.webp",
                                width: 25,
                                height: 25,
                                color: IconTheme.of(context).color,
                              ),
                            ),
                            Text(
                              "Login using your JumpRope account",
                              style: theme.textTheme.subtitle1,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextFormField(
                          controller: _emailFilter,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.email),
                            labelText: "Email",
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (final _) => _nextFocus(context),
                          validator: _validateEmail,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: _passwordFilter,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            icon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _passwordVisible = !_passwordVisible,
                              ),
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                            labelText: "Password",
                          ),
                          keyboardType: TextInputType.visiblePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (final _) => _nextFocus(context),
                          validator: _validatePassword,
                        ),
                      ),
                      Text(_error, style: const TextStyle(color: Colors.red)),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          focusNode: _focus,
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(
                                  width: 25,
                                  height: 25,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text("LOGIN"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailFilter.dispose();
    _passwordFilter.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _emailFilter.addListener(_emailListen);
    _passwordFilter.addListener(_passwordListen);
  }

  void _emailListen() => _email = _emailFilter.text;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final prefs = await _prefs;

    final login = await api.login(_email, _password);

    if (login.success) {
      final account = await api.validate(login.token!);

      final username = account.username!;

      await prefs.setString("username", username);
      await prefs.setString("auth", _password);

      authencate(username, _password);
    } else
      setState(() => _error = login.message!);

    setState(() => _loading = false);
  }

  void _nextFocus(final BuildContext context) =>
      _email.isEmpty && _password.isEmpty
          ? FocusScope.of(context).requestFocus(_focus)
          : _login();

  void _passwordListen() => _password = _passwordFilter.text;

  String? _validateEmail(final String? value) {
    if (value == null || value.isEmpty) return "Please enter your email";

    final email = value.toLowerCase();

    if (email.length < 19 ||
        !email.endsWith("@afsenyc.org") &&
            !(email.startsWith("student_afse_") &&
                email.endsWith("@students.jumpro.pe")))
      return "This is not a valid AFSE email";
  }

  String? _validatePassword(final String? value) {
    if (value == null || value.isEmpty) return "Please enter your password";
  }
}
