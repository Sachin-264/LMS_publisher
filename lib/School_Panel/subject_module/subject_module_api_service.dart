// lib/School_Panel/subject_module/subject_module_api_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Service/navigation_service.dart';
import 'package:provider/provider.dart';
import 'subject_module_model.dart';

class SubjectModuleApiService {
  // Singleton instance
  static final SubjectModuleApiService _instance = SubjectModuleApiService._internal();

  factory SubjectModuleApiService() {
    return _instance;
  }

  SubjectModuleApiService._internal();

  static const String baseUrl = 'http://localhost/AquareLMS';
  static const String apiEndpoint = '$baseUrl/manage_school_academics.php';



  int get _schoolRecNo {
    print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    print("🔍 [_schoolRecNo GETTER] Called");

    try {
      final context = NavigationService.context;
      print("🔍 Context available: ${context != null}");

      if (context != null) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        print("🔍 UserProvider retrieved: ${userProvider != null}");

        final userCode = userProvider.userCode;
        print("🔍 UserProvider.userCode (raw): '$userCode'");
        print("🔍 UserProvider.userCode (type): ${userCode.runtimeType}");

        if (userCode != null) {
          final parsed = int.tryParse(userCode);
          print("🔍 int.tryParse result: $parsed");
          print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
          return parsed ?? 0;
        } else {
          print("⚠️ userCode is NULL!");
          print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
          return 0;
        }
      } else {
        print("⚠️ NavigationService.context is NULL!");
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
        return 0;
      }
    } catch (e) {
      print("❌ Exception in _schoolRecNo: $e");
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
      return 0;
    }
  }

  // ============================================================================
  // HELPER: Call School Academics API (with automatic School_RecNo injection)
  // ============================================================================
  Future<Map<String, dynamic>> _callSchoolAcademicsApi({
    required String action,
    Map<String, dynamic>? params,
  }) async {
    try {
      print("\n═══════════════════════════════════════════");
      print("🚀 [API CALL] Action: $action");
      print("═══════════════════════════════════════════");

      // Get School_RecNo (this will print debug info)
      final schoolRecNo = _schoolRecNo;

      final requestBody = {
        'action': action,
        'School_RecNo': schoolRecNo, // 🔥 Automatically inject
        if (params != null) ...params,
      };

      print("📦 Request Body:");
      print(json.encode(requestBody));
      print("───────────────────────────────────────────");

      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print("📡 Response Status: ${response.statusCode}");
      print("📡 Response Body: ${response.body}");
      print("═══════════════════════════════════════════\n");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print("❌ API Error: $e\n");
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ============================================================================
  // FETCH AVAILABLE CLASSES (From Publisher)
  // ============================================================================
  Future<Map<String, dynamic>> fetchAvailableClasses({
    required String academicYear,
  }) async {
    return await _callSchoolAcademicsApi(
      action: 'FETCH_AVAILABLE',
      params: {
        'Level': 'CLASS',
        'Academic_Year': academicYear,
      },
    );
  }

  // ============================================================================
  // FETCH AVAILABLE SUBJECTS (From Publisher)
  // ============================================================================
  Future<Map<String, dynamic>> fetchAvailableSubjects({
    required int classID,
    required String academicYear,
  }) async {
    return await _callSchoolAcademicsApi(
      action: 'FETCH_AVAILABLE',
      params: {
        'Level': 'SUBJECT',
        'ClassID': classID,
        'Academic_Year': academicYear,
      },
    );
  }

  // ============================================================================
  // FETCH AVAILABLE CHAPTERS (From Publisher)
  // ============================================================================
  Future<Map<String, dynamic>> fetchAvailableChapters({
    required int subjectID,
    required String academicYear,
  }) async {
    return await _callSchoolAcademicsApi(
      action: 'FETCH_AVAILABLE',
      params: {
        'Level': 'CHAPTER',
        'SubjectID': subjectID,
        'Academic_Year': academicYear,
      },
    );
  }

  // ============================================================================
  // FETCH SCHOOL CLASSES (From School_Class_Master)
  // ============================================================================
  Future<Map<String, dynamic>> fetchSchoolClassMaster({
    required String academicYear,
  }) async {
    return await _callSchoolAcademicsApi(
      action: 'FETCH_AVAILABLE',
      params: {
        'Level': 'SCHOOL_CLASS',
        'Academic_Year': academicYear,
      },
    );
  }

  // ============================================================================
  // FETCH TEACHERS (From Teacher_Master)
  // ============================================================================
  Future<Map<String, dynamic>> fetchTeachers() async {
    return await _callSchoolAcademicsApi(
      action: 'FETCH_AVAILABLE',
      params: {
        'Level': 'TEACHER',
      },
    );
  }

  // ============================================================================
  // FETCH SCHOOL'S ADDED CLASSES
  // ============================================================================
  Future<Map<String, dynamic>> fetchSchoolClasses({
    required String academicYear,
  }) async {
    return await _callSchoolAcademicsApi(
      action: 'FETCH_SCHOOL_DATA',
      params: {
        'Level': 'CLASS',
        'Academic_Year': academicYear,
      },
    );
  }

  // ============================================================================
  // FETCH SCHOOL'S ADDED SUBJECTS (WITH ALLOTMENTS)
  // ============================================================================
  Future<Map<String, dynamic>> fetchSchoolSubjects({
    required int classID,
    required String academicYear,
  }) async {
    return await _callSchoolAcademicsApi(
      action: 'FETCH_SCHOOL_DATA',
      params: {
        'Level': 'SUBJECT',
        'ClassID': classID,
        'Academic_Year': academicYear,
      },
    );
  }

  // ============================================================================
  // FETCH SCHOOL'S ADDED CHAPTERS (WITH ALLOTMENTS)
  // ============================================================================
  Future<Map<String, dynamic>> fetchSchoolChapters({
    required int subjectID,
    required String academicYear,
  }) async {
    return await _callSchoolAcademicsApi(
      action: 'FETCH_SCHOOL_DATA',
      params: {
        'Level': 'CHAPTER',
        'SubjectID': subjectID,
        'Academic_Year': academicYear,
      },
    );
  }

  // ============================================================================
  // ADD_SUBJECT - First time add subject with custom name
  // ============================================================================
  Future<Map<String, dynamic>> addSubject({
    required int subjectID,
    required String academicYear,
    String? customSubjectName,
    required String createdBy,
  }) async {
    return await _callSchoolAcademicsApi(
      action: 'ADD_SUBJECT',
      params: {
        'SubjectID': subjectID,
        'Academic_Year': academicYear,
        if (customSubjectName != null && customSubjectName.isNotEmpty)
          'Custom_Subject_Name': customSubjectName,
        'Created_By': createdBy,
      },
    );
  }

  // ============================================================================
  // BULK_ADD - Add ALL chapters of subject
  // ============================================================================
  Future<Map<String, dynamic>> bulkAddSubjectChapters({
    required int subjectID,
    required String academicYear,
    String? customSubjectName,
    required String createdBy,
  }) async {
    return await _callSchoolAcademicsApi(
      action: 'BULK_ADD',
      params: {
        'SubjectID': subjectID,
        'Academic_Year': academicYear,
        if (customSubjectName != null && customSubjectName.isNotEmpty)
          'Custom_Subject_Name': customSubjectName,
        'Created_By': createdBy,
      },
    );
  }

  // ============================================================================
  // ADD_CHAPTER - Add single chapter with optional custom name
  // ============================================================================
  Future<Map<String, dynamic>> addChapterToSchool({
    required int classID,
    required int subjectID,
    required int chapterID,
    required String academicYear,
    String? customChapterName,
    required String createdBy,
  }) async {
    return await _callSchoolAcademicsApi(
      action: 'ADD_CHAPTER',
      params: {
        'ClassID': classID,
        'SubjectID': subjectID,
        'ChapterID': chapterID,
        'Academic_Year': academicYear,
        if (customChapterName != null && customChapterName.isNotEmpty)
          'Custom_Chapter_Name': customChapterName,
        'Created_By': createdBy,
      },
    );
  }

  // ============================================================================
  // ADD_ALLOTMENT - Subject-level allotment
  // ============================================================================
  Future<Map<String, dynamic>> addAllotment({
    required int subjectID,
    required String academicYear,
    required List<int> classRecNoList,
    required List<int> teacherRecNoList,
    String? startDate,
    String? endDate,
    int statusID = 1,
    required String createdBy,
  }) async {
    return await _callSchoolAcademicsApi(
      action: 'ADD_ALLOTMENT',
      params: {
        'SubjectID': subjectID,
        'Academic_Year': academicYear,
        'ClassRecNo_List': classRecNoList.join(','),
        'TeacherRecNo_List': teacherRecNoList.join(','),
        if (startDate != null) 'Start_Date': startDate,
        if (endDate != null) 'End_Date': endDate,
        'Status_ID': statusID,
        'Created_By': createdBy,
      },
    );
  }

  // ============================================================================
  // UPDATE_SUBJECT - Update custom subject name
  // ============================================================================
  Future<Map<String, dynamic>> updateSubjectName({
    required int subjectID,
    required String academicYear,
    required String customSubjectName,
    required String modifiedBy,
  }) async {
    return await _callSchoolAcademicsApi(
      action: 'UPDATE_SUBJECT',
      params: {
        'SubjectID': subjectID,
        'Academic_Year': academicYear,
        'Custom_Subject_Name': customSubjectName,
        'Modified_By': modifiedBy,
      },
    );
  }

  // ============================================================================
  // UPDATE_CHAPTER - Update custom chapter name
  // ============================================================================
  Future<Map<String, dynamic>> updateSchoolChapter({
    required int recNo,
    String? customChapterName,
    int? isActiveForSchool,
    required String modifiedBy,
  }) async {
    return await _callSchoolAcademicsApi(
      action: 'UPDATE_CHAPTER',
      params: {
        'RecNo': recNo,
        if (customChapterName != null && customChapterName.isNotEmpty)
          'Custom_Chapter_Name': customChapterName,
        if (isActiveForSchool != null)
          'Is_Active_For_School': isActiveForSchool,
        'Modified_By': modifiedBy,
      },
    );
  }

  // ============================================================================
  // UPDATE_ALLOTMENT - Update allotment details
  // ============================================================================
  Future<Map<String, dynamic>> updateAllotment({
    required int recNo,
    int? classRecNo,
    int? teacherRecNo,
    String? startDate,
    String? endDate,
    int? statusID,
    required String modifiedBy,
  }) async {
    return await _callSchoolAcademicsApi(
      action: 'UPDATE_ALLOTMENT',
      params: {
        'RecNo': recNo,
        if (classRecNo != null) 'ClassRecNo_List': classRecNo.toString(),
        if (teacherRecNo != null) 'TeacherRecNo_List': teacherRecNo.toString(),
        if (startDate != null) 'Start_Date': startDate,
        if (endDate != null) 'End_Date': endDate,
        if (statusID != null) 'Status_ID': statusID,
        'Modified_By': modifiedBy,
      },
    );
  }

  // ============================================================================
  // DELETE_CHAPTER - Delete chapter
  // ============================================================================
  Future<Map<String, dynamic>> deleteSchoolChapter({
    required int recNo,
  }) async {
    return await _callSchoolAcademicsApi(
      action: 'DELETE_CHAPTER',
      params: {
        'RecNo': recNo,
      },
    );
  }

  // ============================================================================
  // DELETE_ALLOTMENT - Delete allotment
  // ============================================================================
  Future<Map<String, dynamic>> deleteAllotment({
    required int recNo,
  }) async {
    return await _callSchoolAcademicsApi(
      action: 'DELETE_ALLOTMENT',
      params: {
        'RecNo': recNo,
      },
    );
  }
}
