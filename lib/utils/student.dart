library my_afse.student;

import "dart:convert";

import "package:intl/intl.dart";
import "package:shared_preferences/shared_preferences.dart";

import "api.dart" as api;

late Student student;

final _prefs = SharedPreferences.getInstance();

Future<Map<String, dynamic>?> updateStudent() async {
  final prefs = await _prefs;

  final token = prefs.getString("token");

  if (token == null)
    return null;
  else
    api.validate(token);

  final localStudent = prefs.getString("student");
  if (localStudent != null) {
    final data = jsonDecode(localStudent);
    student = Student.fromJson(data);

    return data;
  }

  return fetchStudent();
}

Future<Map<String, dynamic>> fetchStudent() async {
  final prefs = await _prefs;

  final data = (await api.get("student"))[0];

  student = Student.fromJson(data);
  await prefs.setString("student", jsonEncode(data));

  return data;
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
  final List followers;
  final String officialClass;
  final String status;
  final String email;
  // final List<String> sections;
  // final Map annotations;

  const Student({
    required final this.modified,
    required final this.school,
    required final this.id,
    required final this.externalId,
    required final this.label,
    required final this.firstName,
    required final this.lastName,
    required final this.adviser,
    required final this.followers,
    required final this.officialClass,
    required final this.status,
    required final this.email,
    // required final this.sections,
    // required final this.annotations,
  });

  factory Student.fromJson(final Map<String, dynamic> json) => Student(
        modified: DateFormat.yMMMEd().add_jm().format(
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

  @override
  toString() =>
      "{ $modified, $school, $id, $externalId, $label, $firstName, $lastName, $adviser, $followers, $officialClass, $status, $email }"; // , $annotations
}
