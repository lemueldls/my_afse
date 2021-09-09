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

  String? localStudent = prefs.getString("student");
  if (localStudent != null) {
    final data = jsonDecode(localStudent);
    student = Student.fromJson(data);

    return data;
  }

  return await fetchStudent();
}

Future<Map<String, dynamic>> fetchStudent() async {
  final prefs = await _prefs;

  final data = (await api.get("student"))[0];

  student = Student.fromJson(data);
  await prefs.setString("student", JsonEncoder().convert(data));

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
    // required this.sections,
    // required this.annotations,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        modified: DateFormat.yMMMMEEEEd().add_jm().format(
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
