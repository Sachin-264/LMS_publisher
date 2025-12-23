import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lms_publisher/Util/AppUrl.dart';

class ParentStudentService {
  static const String baseUrl = AppUrls.baseUrl;

  /// Fetch all students/children for a parent using ParentID (UserCode)
  Future<List<StudentChild>> getStudentsByParentId({
    required String parentId,
  }) async {
    try {
      print("🔍 Fetching students for ParentID: $parentId");

      final response = await http.post(
        Uri.parse('$baseUrl/parent_student_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'GET_STUDENTS_BY_PARENT',
          'ParentID': parentId,
        }),
      );

      print("✅ Response: ${response.statusCode}");
      print("📦 Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final List<dynamic> studentsData = data['students'] ?? [];
          return studentsData
              .map((json) => StudentChild.fromJson(json))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch students');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Error fetching students: $e");
      throw Exception('Error fetching students: $e');
    }
  }
}

/// Model class for Student/Child
class StudentChild {
  final int recNo;
  final int schoolRecNo;
  final int classRecNo;
  final String studentId;
  final String admissionNumber;
  final String firstName;
  final String middleName;
  final String lastName;
  final String gender;
  final String dateOfBirth;
  final String bloodGroup;
  final String mobileNumber;
  final String emailId;
  final String currentClass;
  final String sectionDivision;
  final String rollNumber;
  final String studentPhotoPath;
  final int parentId;
  final bool isActive;

  StudentChild({
    required this.recNo,
    required this.schoolRecNo,
    required this.classRecNo,
    required this.studentId,
    required this.admissionNumber,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.gender,
    required this.dateOfBirth,
    required this.bloodGroup,
    required this.mobileNumber,
    required this.emailId,
    required this.currentClass,
    required this.sectionDivision,
    required this.rollNumber,
    required this.studentPhotoPath,
    required this.parentId,
    required this.isActive,
  });

  String get fullName => '$firstName ${middleName.isNotEmpty ? "$middleName " : ""}$lastName'.trim();

  factory StudentChild.fromJson(Map<String, dynamic> json) {
    return StudentChild(
      recNo: int.tryParse(json['RecNo']?.toString() ?? '0') ?? 0,
      schoolRecNo: int.tryParse(json['School_RecNo']?.toString() ?? '0') ?? 0,
      classRecNo: int.tryParse(json['ClassRecNo']?.toString() ?? '0') ?? 0,
      studentId: json['Student_ID']?.toString() ?? '',
      admissionNumber: json['Admission_Number']?.toString() ?? '',
      firstName: json['First_Name']?.toString() ?? '',
      middleName: json['Middle_Name']?.toString() ?? '',
      lastName: json['Last_Name']?.toString() ?? '',
      gender: json['Gender']?.toString() ?? '',
      dateOfBirth: json['Date_of_Birth']?.toString() ?? '',
      bloodGroup: json['Blood_Group']?.toString() ?? '',
      mobileNumber: json['Mobile_Number']?.toString() ?? '',
      emailId: json['Email_ID']?.toString() ?? '',
      currentClass: json['Current_Class']?.toString() ?? '',
      sectionDivision: json['Section_Division']?.toString() ?? '',
      rollNumber: json['Roll_Number']?.toString() ?? '',
      studentPhotoPath: json['Student_Photo_Path']?.toString() ?? '',
      parentId: int.tryParse(json['ParentID']?.toString() ?? '0') ?? 0,
      isActive: json['IsActive']?.toString() == '1',
    );
  }
}
