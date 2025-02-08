library my_afse.student;

import "dart:async";
import "dart:convert";

import "package:intl/intl.dart";
import "package:shared_preferences/shared_preferences.dart";

import "api.dart" as api;

late Student student;

final _prefs = SharedPreferences.getInstance();

Stream<Map<String, dynamic>> fetchStudent() async* {
  final prefs = await _prefs;

  await for (final response in api.getApi("student")) {
    final data = response[0];

    student = Student.fromJson(data);
    await prefs.setString("student", jsonEncode(data));

    yield data;
  }
}

Future<void> initializeStudent() async {
  final prefs = await _prefs;

  final token = prefs.getString("token");

  if (token == null) return;

  // Validate token in the background
  unawaited(api.validate(token));

  final localStudent = prefs.getString("student");
  if (localStudent != null) {
    final data = jsonDecode(localStudent);

    student = Student.fromJson(data);
  } else
    fetchStudent();
}

class Student {
  final String modified;
  final String school;
  final int id;
  final String externalId;
  final String label;
  final String firstName;
  final String lastName;
  final int adviser;
  final List<dynamic> followers;
  final String officialClass;
  final String status;
  final String email;
  // final List<String> sections;
  // final Map<String, dynamic> annotations;

  const Student({
    required this.modified,
    required this.school,
    required this.id,
    required this.externalId,
    required this.label,
    required this.firstName,
    required this.lastName,
    required this.adviser,
    required this.followers,
    required this.officialClass,
    required this.status,
    required this.email,
    // required final this.sections,
    // required final this.annotations,
  });

  factory Student.fromJson(final Map<String, dynamic> json) {
    final dateFormat = DateFormat.yMMMEd().add_jm();

    return Student(
      modified: dateFormat.format(
        DateFormat("yyyy-MM-ddTHH:mm:ss").parseUtc(
          json["time_modified"],
        ),
      ),
      school: json["school"],
      id: json["id"],
      externalId: json["external_id"],
      label: json["label"],
      firstName: json["first_name"],
      lastName: json["last_name"],
      adviser: json["user"],
      followers: json["followers"],
      officialClass: json["official_class"],
      status: json["status"],
      email: json["google_account"],
      // sections: json["sections"],
      // annotations: json["annotations"],
    );
  }

  @override
  String toString() =>
      """{ $modified, $school, $id, $externalId, $label, $firstName, $lastName, $adviser, $followers, $officialClass, $status, $email }""";
}
