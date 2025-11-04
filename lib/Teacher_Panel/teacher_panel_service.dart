import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class TeacherPanelService {
  // Base URL for Teacher Panel API
  static const String baseUrl = 'https://aquare.co.in/mobileAPI/sachin/lms';

  /// Get Teacher Dashboard Summary
  static Future<Map<String, dynamic>> getDashboardSummary({
    required String teacherCode,
    required String academicYear,
  }) async {
    try {
      if (kDebugMode) {
        print('\n========================================');
        print('📊 FETCHING TEACHER DASHBOARD');
        print('========================================');
        print('👨‍🏫 Teacher Code: $teacherCode');
        print('📅 Academic Year: $academicYear');
        print('🌐 API URL: $baseUrl/teacher_panel_api.php');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/teacher_panel_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'GET_DASHBOARD_SUMMARY',
          'TeacherCode': teacherCode,
          'AcademicYear': academicYear,
        }),
      );

      if (kDebugMode) {
        print('📡 Response Status: ${response.statusCode}');
        print('📦 Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to load dashboard');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching dashboard: $e');
      }
      rethrow;
    }
  }

  /// Get Teacher's Classes List
  static Future<Map<String, dynamic>> getClassesList({
    required String teacherCode,
    required String academicYear,
    String viewType = 'grid',
  }) async {
    try {
      if (kDebugMode) {
        print('\n========================================');
        print('📚 FETCHING CLASSES LIST');
        print('========================================');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/teacher_panel_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'GET_CLASSES_LIST',
          'TeacherCode': teacherCode,
          'AcademicYear': academicYear,
          'ViewType': viewType,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to load classes');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching classes: $e');
      }
      rethrow;
    }
  }

  /// Get Students List with Filters and Pagination
  static Future<Map<String, dynamic>> getStudentsList({
    required String teacherCode,
    required int classRecNo,
  }) async {
    final String apiUrl = "$baseUrl/teacher_panel_api.php";

    // Build request body
    final Map<String, dynamic> requestBody = {
      "action": "GET_STUDENTS_LIST",
      "TeacherCode": teacherCode,
      "ClassRecNo": classRecNo,
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      body: jsonEncode(requestBody),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      // Always check for API status!
      if (decoded['status'] == 'success') {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'API error');
      }
    } else {
      throw Exception('Network error: ${response.statusCode}');
    }
  }

  /// Get Student Profile Detail
  static Future<Map<String, dynamic>> getStudentProfile({
    required String teacherCode,
    required int studentRecNo,
    int? subjectId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/teacher_panel_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'GET_STUDENT_PROFILE',
          'TeacherCode': teacherCode,
          'StudentRecNo': studentRecNo,
          'SubjectID': subjectId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching student profile: $e');
      }
      rethrow;
    }
  }

  /// Add Teacher Note for Student
  static Future<Map<String, dynamic>> addStudentNote({
    required String teacherCode,
    required int studentRecNo,
    int? subjectId,
    required String noteText,
    String noteCategory = 'General',
    bool isPrivate = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/teacher_panel_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'ADD_STUDENT_NOTE',
          'TeacherCode': teacherCode,
          'StudentRecNo': studentRecNo,
          'SubjectID': subjectId,
          'NoteText': noteText,
          'NoteCategory': noteCategory,
          'IsPrivate': isPrivate ? 1 : 0,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding note: $e');
      }
      rethrow;
    }
  }

  /// Get Study Materials
  static Future<Map<String, dynamic>> getStudyMaterials({
    required String teacherCode,
    required int subjectId,
    int? chapterId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/teacher_panel_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'GET_STUDY_MATERIALS',
          'TeacherCode': teacherCode,
          'SubjectID': subjectId,
          'ChapterID': chapterId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching materials: $e');
      }
      rethrow;
    }
  }

  /// Get Class Performance Overview
  static Future<Map<String, dynamic>> getClassPerformance({
    required String teacherCode,
    required int classRecNo,
    required int subjectId,
    required String academicYear,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/teacher_panel_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'GET_CLASS_PERFORMANCE',
          'TeacherCode': teacherCode,
          'ClassRecNo': classRecNo,
          'SubjectID': subjectId,
          'AcademicYear': academicYear,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching class performance: $e');
      }
      rethrow;
    }
  }

  /// Get Struggling Students Alert
  static Future<Map<String, dynamic>> getStrugglingStudents({
    required String teacherCode,
    int? classRecNo,
    int? subjectId,
    double threshold = 40.0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/teacher_panel_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'GET_STRUGGLING_STUDENTS',
          'TeacherCode': teacherCode,
          'ClassRecNo': classRecNo,
          'SubjectID': subjectId,
          'Threshold': threshold,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching struggling students: $e');
      }
      rethrow;
    }
  }

  /// Get High Performers
  static Future<Map<String, dynamic>> getHighPerformers({
    required String teacherCode,
    int? classRecNo,
    int? subjectId,
    double threshold = 85.0,
    int topN = 10,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/teacher_panel_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'GET_HIGH_PERFORMERS',
          'TeacherCode': teacherCode,
          'ClassRecNo': classRecNo,
          'SubjectID': subjectId,
          'Threshold': threshold,
          'TopN': topN,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching high performers: $e');
      }
      rethrow;
    }
  }
}
