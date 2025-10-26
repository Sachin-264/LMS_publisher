// class_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'class_model.dart';

class ClassApiService {
  // Change this to your actual API URL
  static const String baseUrl = 'http://localhost/AquareLMS';

  Future<Map<String, dynamic>> _post(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/class.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          return result;
        } else {
          throw Exception(result['message'] ?? 'Unknown error occurred');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  /// Fetches master classes from Class_Master
  Future<List<MasterClassOption>> fetchMasterClasses({required int schoolID}) async {
    final result = await _post({
      'action': 'FETCH_AVAILABLE_CLASSES_FROM_MASTER',
      'School_ID': schoolID,
    });

    if (result['data'] != null && result['data'] is List) {
      return (result['data'] as List)
          .map((json) => MasterClassOption.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Fetches available teachers for assignment
  Future<List<TeacherOptionModel>> fetchAvailableTeachers({required int schoolID}) async {
    final result = await _post({
      'action': 'FETCH_AVAILABLE_TEACHERS',
      'School_ID': schoolID,
    });

    if (result['data'] != null && result['data'] is List) {
      return (result['data'] as List)
          .map((json) => TeacherOptionModel.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Fetches all classes for a school
  Future<List<ClassModel>> fetchAllClasses({
    required int schoolID,
    String? academicYear,
  }) async {
    final result = await _post({
      'action': 'FETCH_ALL_CLASSES',
      'School_ID': schoolID,
      if (academicYear != null) 'Academic_Year': academicYear,
    });

    if (result['data'] != null && result['data'] is List) {
      return (result['data'] as List)
          .map((json) => ClassModel.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Adds a new class
  Future<Map<String, dynamic>> addClass({
    required ClassModel classData,
    required String operationBy,
  }) async {
    return _post({
      'action': 'ADD_CLASS',
      'School_ID': classData.schoolID,
      'Class_ID': classData.classID,
      'Class_Name': classData.className,
      'Class_Code': classData.classCode,
      'Section_Name': classData.sectionName,
      'Room_Number': classData.roomNumber,
      'Max_Student_Capacity': classData.maxStudentCapacity,
      'Academic_Year': classData.academicYear,
      'Class_Start_Date': classData.classStartDate,
      'Class_End_Date': classData.classEndDate,
      'Class_Teacher_RecNo': classData.classTeacherRecNo,
      'IsActive': classData.isActive ? 1 : 0,
      'Created_By': operationBy,
    });
  }

  /// Updates an existing class
  Future<Map<String, dynamic>> updateClass({
    required ClassModel classData,
    required String operationBy,
  }) async {
    return _post({
      'action': 'UPDATE_CLASS',
      'ClassRecNo': classData.classRecNo,
      'School_ID': classData.schoolID,
      'Class_Name': classData.className,
      'Class_Code': classData.classCode,
      'Section_Name': classData.sectionName,
      'Room_Number': classData.roomNumber,
      'Max_Student_Capacity': classData.maxStudentCapacity,
      'Academic_Year': classData.academicYear,
      'Class_Start_Date': classData.classStartDate,
      'Class_End_Date': classData.classEndDate,
      'IsActive': classData.isActive ? 1 : 0,
      'Modified_By': operationBy,
    });
  }

  /// Deletes a class
  Future<Map<String, dynamic>> deleteClass({
    required int classRecNo,
    required int schoolID,
    required String operationBy,
  }) async {
    return _post({
      'action': 'DELETE_CLASS',
      'ClassRecNo': classRecNo,
      'School_ID': schoolID,
      'Modified_By': operationBy,
    });
  }

  /// Changes class teacher
  Future<Map<String, dynamic>> changeClassTeacher({
    required int classRecNo,
    required int classTeacherRecNo,
    required int schoolID,
    required String operationBy,
  }) async {
    return _post({
      'action': 'CHANGE_CLASS_TEACHER',
      'ClassRecNo': classRecNo,
      'Class_Teacher_RecNo': classTeacherRecNo,
      'School_ID': schoolID,
      'Modified_By': operationBy,
    });
  }

  /// Fetches available subjects for a class
  Future<List<SubjectOptionModel>> fetchAvailableSubjects({
    required int schoolID,
    required int classRecNo,
    required String academicYear,
  }) async {
    final result = await _post({
      'action': 'FETCH_AVAILABLE_SUBJECTS',
      'School_ID': schoolID,
      'ClassRecNo': classRecNo,
      'Academic_Year': academicYear,
    });

    if (result['data'] != null && result['data'] is List) {
      return (result['data'] as List)
          .map((json) => SubjectOptionModel.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Fetches subjects assigned to a class (with teacher info)
  Future<List<ClassSubjectModel>> fetchClassSubjects({
    required int schoolID,
    required int classRecNo,
    required String academicYear,
  }) async {
    final result = await _post({
      'action': 'FETCH_CLASS_SUBJECTS',
      'School_ID': schoolID,
      'ClassRecNo': classRecNo,
      'Academic_Year': academicYear,
    });

    if (result['data'] != null && result['data'] is List) {
      return (result['data'] as List)
          .map((json) => ClassSubjectModel.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Adds subjects to a class
  Future<Map<String, dynamic>> addSubjectsToClass({
    required int schoolID,
    required int classRecNo,
    required List<int> subjectIDs,
    required String academicYear,
    required String operationBy,
  }) async {
    return _post({
      'action': 'ADD_SUBJECTS_TO_CLASS',
      'School_ID': schoolID,
      'ClassRecNo': classRecNo,
      'SubjectIDs': subjectIDs,
      'Academic_Year': academicYear,
      'Created_By': operationBy,
    });
  }

  /// Removes a subject from class (NEWLY ADDED)
  Future<Map<String, dynamic>> removeSubjectFromClass({
    required int classRecNo,
    required int subjectID,
    required int schoolID,
    required String academicYear,
    required String operationBy,
  }) async {
    return _post({
      'action': 'REMOVE_SUBJECT_FROM_CLASS',
      'ClassRecNo': classRecNo,
      'SubjectID': subjectID,
      'School_ID': schoolID,
      'Academic_Year': academicYear,
      'Modified_By': operationBy,
    });
  }

  /// Allots a teacher to a subject
  Future<Map<String, dynamic>> allotSubjectTeacher({
    required int classRecNo,
    required int subjectID,
    required int teacherRecNo,
    required int schoolID,
    required String startDate,
    required String endDate,
    required String academicYear,
    required String operationBy,
  }) async {
    return _post({
      'action': 'ALLOT_SUBJECT_TEACHER',
      'ClassRecNo': classRecNo,
      'SubjectID': subjectID,
      'TeacherRecNo': teacherRecNo,
      'School_ID': schoolID,
      'Start_Date': startDate,
      'End_Date': endDate,
      'Academic_Year': academicYear,
      'Status_ID': 1,
      'Created_By': operationBy,
    });
  }

  /// Removes subject allotment
  Future<Map<String, dynamic>> removeSubjectAllotment({
    required int subjectID,
    required int classRecNo,
    required int teacherRecNo,
    required int schoolID,
    required String academicYear,
    required String operationBy,
  }) async {
    return _post({
      'action': 'REMOVE_SUBJECT_ALLOTMENT',
      'SubjectID': subjectID,
      'ClassRecNo': classRecNo,
      'TeacherRecNo': teacherRecNo,
      'School_ID': schoolID,
      'Academic_Year': academicYear,
      'Modified_By': operationBy,
    });
  }

  /// Fetches subject-teacher allotments for a class
  Future<List<SubjectTeacherAllotmentModel>> fetchSubjectAllotments({
    required int schoolID,
    required int classRecNo,
    required String academicYear,
  }) async {
    final result = await _post({
      'action': 'FETCH_SUBJECT_ALLOTMENTS',
      'School_ID': schoolID,
      'ClassRecNo': classRecNo,
      'Academic_Year': academicYear,
    });

    if (result['data'] != null && result['data'] is List) {
      return (result['data'] as List)
          .map((json) => SubjectTeacherAllotmentModel.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Fetches class details
  Future<ClassModel?> fetchClassDetails({
    required int classRecNo,
    required int schoolID,
  }) async {
    final result = await _post({
      'action': 'FETCH_CLASS_DETAILS',
      'ClassRecNo': classRecNo,
      'School_ID': schoolID,
    });

    if (result['data'] != null && result['data'] is Map) {
      return ClassModel.fromJson(result['data']);
    }
    return null;
  }
}
