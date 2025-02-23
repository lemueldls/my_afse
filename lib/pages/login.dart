import "package:firebase_analytics/firebase_analytics.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_database/firebase_database.dart";
import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../utils/analytics.dart";
import "../utils/api.dart" as api;
import "../utils/settings.dart";
import "../utils/student.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({final Key? key}) : super(key: key);

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _auth = FirebaseAuth.instance;
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

  Future<void> authenticate(
    final String username,
    final String password,
  ) async {
    final navigator = Navigator.of(context);

    final student = await fetchStudent().first;

    final id = student["id"].toString();

    try {
      await _auth.signInWithEmailAndPassword(
        email: username,
        password: password,
      );

      await analytics?.logLogin();
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case "user-not-found":
          final db = FirebaseDatabase.instance..setPersistenceEnabled(true);

          await db.ref().child("users").child(id).set(student);

          await _auth.createUserWithEmailAndPassword(
            email: username,
            password: password,
          );

          await analytics?.logSignUp(signUpMethod: "email");

          break;

        default:
          _error = error.message!;
          break;
      }
    } on Exception catch (error) {
      _error = error.toString();
    }

    await analytics?.setUserId(
      id: id,
      callOptions: AnalyticsCallOptions(global: true),
    );

    await navigator.pushReplacementNamed(settings.page);
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("JumpRope Login"),
      ),
      body: Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),

          // Login card
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
                      // JumpRope subtitle
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
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),

                      // Email input
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

                      // Password input
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: _passwordFilter,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            icon: const Icon(Icons.lock),

                            // Password visibility toggle
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

                      // Error text
                      Text(
                        _error,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            // Foreground color
                            foregroundColor: colorScheme.onSecondaryContainer,
                            backgroundColor: colorScheme.secondaryContainer,
                          ).copyWith(elevation: ButtonStyleButton.allOrNull(0)),
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
                              : const Text("Login"),
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

  /// Listen for email changes.
  void _emailListen() => _email = _emailFilter.text;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final prefs = await _prefs;

    final login = await api.login(_email, _password);

    if (login.success) {
      final account = await api.validate(login.token!);

      final username = account.username!;

      await Future.wait([
        prefs.setString("username", username),
        prefs.setString("auth", _password),
      ]);

      await authenticate(username, _password);
    } else if (mounted) setState(() => _error = login.message!);

    setState(() => _loading = false);
  }

  /// Handle the next action on enter.
  void _nextFocus(final BuildContext context) =>
      _email.isEmpty && _password.isEmpty
          ? FocusScope.of(context).requestFocus(_focus)
          : _login();

  /// Listen for password changes.
  void _passwordListen() => _password = _passwordFilter.text;

  /// Validate the email address.
  String? _validateEmail(final String? value) {
    if (value == null || value.isEmpty) return "Please enter your email";

    final email = value.toLowerCase();

    if (email.length < 19 ||
        !email.endsWith("@afsenyc.org") &&
            !(email.startsWith("student_afse_") &&
                email.endsWith("@students.jumpro.pe")))
      return "This is not a valid AFSE email";

    return null;
  }

  /// Validate the password.
  String? _validatePassword(final String? value) {
    if (value == null || value.isEmpty) return "Please enter your password";

    return null;
  }
}
