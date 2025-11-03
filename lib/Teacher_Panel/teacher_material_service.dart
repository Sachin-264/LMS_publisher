import 'dart:convert';
import 'package:http/http.dart' as http;

class TeacherMaterialService {
  static const String baseUrl = 'http://localhost/AquareLMS/teacher_material.php';
  static const String assignmentBaseUrl = 'http://localhost/AquareLMS/assignment_api.php';

  // Get materials for a chapter (publisher + teacher materials)
  static Future<Map<String, dynamic>> getChapterMaterials({
    required String teacherCode,
    required int chapterId,
  }) async {
    print('🔵 [GET_MATERIALS] Starting API call...');
    print('🔵 TeacherCode: $teacherCode');
    print('🔵 ChapterID: $chapterId');
    print('🔵 URL: $baseUrl');

    try {
      final requestBody = {
        "action": "GET_MATERIALS",
        "TeacherCode": teacherCode,
        "ChapterID": chapterId,
      };

      print('🔵 Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print('🔵 Response Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      final decoded = jsonDecode(response.body);
      print('🔵 Decoded Response: $decoded');
      print('🔵 Status: ${decoded['status']}');
      print('🔵 Publisher Materials Count: ${decoded['publisher_materials']?.length ?? 0}');
      print('🔵 Teacher Materials Count: ${decoded['teacher_materials']?.length ?? 0}');

      if (decoded['status'] == 'success') {
        print('✅ [GET_MATERIALS] Success!');
        return decoded;
      } else {
        print('❌ [GET_MATERIALS] API returned error status');
        throw Exception(decoded['message'] ?? 'Error fetching materials');
      }
    } catch (e) {
      print('❌ [GET_MATERIALS] Exception caught: $e');
      rethrow;
    }
  }

  // Get chapters by subject ID
  static Future<List<Map<String, dynamic>>> getChaptersBySubjectId({
    required String subjectId,
  }) async {
    print('🟢 [GET_CHAPTERS] Starting API call...');
    print('🟢 SubjectID: $subjectId');

    try {
      final requestBody = {
        'action': 'GET_CHAPTERS_BY_SUBJECTID',
        'SubjectID': subjectId,
      };

      print('🟢 Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('🟢 Response Status Code: ${response.statusCode}');
      print('🟢 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print('🟢 Decoded Response: $decoded');

        if (decoded['status'] == 'success') {
          final List chaptersData = decoded['chapters'] ?? [];
          print('✅ [GET_CHAPTERS] Success! Chapters count: ${chaptersData.length}');
          return chaptersData.cast<Map<String, dynamic>>();
        } else {
          print('❌ [GET_CHAPTERS] API returned error status');
          throw Exception(decoded['message'] ?? 'Error fetching chapters');
        }
      } else {
        print('❌ [GET_CHAPTERS] HTTP error: ${response.statusCode}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [GET_CHAPTERS] Exception caught: $e');
      rethrow;
    }
  }

  // Upload new material or assignment
  static Future<Map<String, dynamic>> uploadMaterial({
    required String teacherCode,
    required int chapterId,
    required String materialType,
    required String title,
    String? description,
    String? materialPath,
    String? materialLink,
    String? scheduleReleaseDate,
    // Assignment & Worksheet parameters
    String? dueDate,
    int? totalMarks,
    int? passingMarks,
    int? maxAttempts,
    bool? allowLateSubmission,
    double? lateSubmissionPenalty,
  }) async {
    print('🟡 [UPLOAD_MATERIAL] Starting API call...');
    print('🟡 TeacherCode: $teacherCode, ChapterID: $chapterId');
    print('🟡 Title: $title, Type: $materialType');

    try {
      // Check if it's an assignment - use assignment API
      if (materialType.toLowerCase() == 'assignment') {
        print('🟡 Detected Assignment - using assignment API...');
        return await _uploadAssignment(
          teacherCode: teacherCode,
          chapterId: chapterId,
          title: title,
          description: description,
          materialPath: materialPath,
          dueDate: dueDate,
          totalMarks: totalMarks ?? 0,
          passingMarks: passingMarks ?? 0,
          maxAttempts: maxAttempts ?? 1,
          allowLateSubmission: allowLateSubmission ?? false,
          lateSubmissionPenalty: lateSubmissionPenalty ?? 0.0,
        );
      }

      // For Worksheet and other materials
      final requestBody = {
        "action": "UPLOAD_MATERIAL",
        "TeacherCode": teacherCode,
        "ChapterID": chapterId,
        "MaterialType": materialType,
        "MaterialTitle": title,
        if (description != null && description.isNotEmpty)
          "Description": description,
        if (materialPath != null && materialPath.isNotEmpty)
          "MaterialPath": materialPath,
        if (materialLink != null && materialLink.isNotEmpty)
          "MaterialLink": materialLink,
        // Only include date fields if they have values
        if (scheduleReleaseDate != null && scheduleReleaseDate.isNotEmpty)
          "ScheduleReleaseDate": scheduleReleaseDate,
        // Worksheet-specific fields - send only if provided
        if (materialType.toLowerCase() == 'worksheet') ...{
          if (totalMarks != null && totalMarks > 0)
            "TotalMarks": totalMarks,
          if (passingMarks != null && passingMarks > 0)
            "PassingMarks": passingMarks,
          if (maxAttempts != null && maxAttempts > 0)
            "AllowedAttempts": maxAttempts,
          if (dueDate != null && dueDate.isNotEmpty)
            "DueDate": _formatDateForApi(dueDate),
        },
      };

      print('🟡 Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print('🟡 Response Status Code: ${response.statusCode}');
      print('🟡 Response Body: ${response.body}');

      final decoded = jsonDecode(response.body);

      if (decoded['status'] == 'success') {
        print('✅ [UPLOAD_MATERIAL] Success!');
        return decoded;
      } else {
        print('❌ [UPLOAD_MATERIAL] API returned error: ${decoded['message']}');
        throw Exception(decoded['message'] ?? 'Error uploading material');
      }
    } catch (e) {
      print('❌ [UPLOAD_MATERIAL] Exception: $e');
      rethrow;
    }
  }


  // Upload assignment (private helper)
  static Future<Map<String, dynamic>> _uploadAssignment({
    required String teacherCode,
    required int chapterId,
    required String title,
    String? description,
    String? materialPath,
    String? dueDate,
    required int totalMarks,
    required int passingMarks,
    required int maxAttempts,
    required bool allowLateSubmission,
    required double lateSubmissionPenalty,
  }) async {
    print('🟡 [UPLOAD_ASSIGNMENT] Starting assignment upload...');

    try {
      // Parse dueDate to proper format if needed
      String? formattedDueDate;
      if (dueDate != null && dueDate.isNotEmpty) {
        // Assuming dueDate comes in 'MMM dd, yyyy' format from date picker
        formattedDueDate = _formatDateForApi(dueDate);
      }

      final requestBody = {
        "action": "ADD_MATERIAL",
        "TeacherCode": teacherCode,
        "ChapterID": chapterId,
        "MaterialType": "Assignment",
        "MaterialTitle": title,
        "Description": description,
        "DueDate": formattedDueDate,
        "TotalMarks": totalMarks,
        "PassingMarks": passingMarks,
        "AllowLateSubmission": allowLateSubmission,
        "LateSubmissionPenalty": lateSubmissionPenalty,
        "AvailableFrom": DateTime.now().toIso8601String().split('.')[0],
        "AllowedAttempts": maxAttempts,
        "SubmissionType": materialPath != null ? "FileUpload" : "Text",
        if (materialPath != null) "AllowedFileTypes": "pdf,docx,jpg,png",
        if (materialPath != null) "MaterialPath": materialPath,
        "PublishStatus": "Published",
      };

      print('🟡 Assignment Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(assignmentBaseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print('🟡 Assignment Response Status: ${response.statusCode}');
      print('🟡 Assignment Response Body: ${response.body}');

      final decoded = jsonDecode(response.body);

      if (decoded['status'] == 'success') {
        print('✅ [UPLOAD_ASSIGNMENT] Assignment created successfully');
        return decoded;
      } else {
        print('❌ [UPLOAD_ASSIGNMENT] API error: ${decoded['message']}');
        throw Exception(decoded['message'] ?? 'Error creating assignment');
      }
    } catch (e) {
      print('❌ [UPLOAD_ASSIGNMENT] Exception: $e');
      rethrow;
    }
  }

  // Format date from UI to API format
  static String? _formatDateForApi(String uiDate) {
    try {
      // Input: "MMM dd, yyyy" (e.g., "Nov 10, 2025")
      // Output: "yyyy-MM-dd HH:mm:ss" (e.g., "2025-11-10 23:59:59")
      final inputFormat = 'MMM dd, yyyy';
      final now = DateTime.now();

      // Parse the date - since we only have date, add end-of-day time
      final parts = uiDate.split(',');
      if (parts.length != 2) return null;

      final monthDay = parts[0].trim();
      final year = parts[1].trim();
      final fullDateString = '$monthDay, $year 23:59:59';

      // Simple parsing for common formats
      final monthNames = {
        'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
        'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
        'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12',
      };

      final monthDayParts = monthDay.split(' ');
      if (monthDayParts.length != 2) return null;

      final month = monthNames[monthDayParts[0]];
      final day = monthDayParts[1].padLeft(2, '0');

      if (month == null) return null;

      return '$year-$month-$day 23:59:59';
    } catch (e) {
      print('❌ Error formatting date: $e');
      return null;
    }
  }

  // Delete teacher material
  static Future<Map<String, dynamic>> deleteMaterial({
    required String teacherCode,
    required int materialRecNo,
  }) async {
    print('🔴 [DELETE_MATERIAL] Starting API call...');
    print('🔴 TeacherCode: $teacherCode, MaterialRecNo: $materialRecNo');

    try {
      final requestBody = {
        "action": "DELETE_MATERIAL",
        "TeacherCode": teacherCode,
        "MaterialRecNo": materialRecNo,
      };

      print('🔴 Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print('🔴 Response Status Code: ${response.statusCode}');
      print('🔴 Response Body: ${response.body}');

      final decoded = jsonDecode(response.body);

      if (decoded['status'] == 'success') {
        print('✅ [DELETE_MATERIAL] Success!');
        return decoded;
      } else {
        print('❌ [DELETE_MATERIAL] API returned error');
        throw Exception(decoded['message'] ?? 'Error deleting material');
      }
    } catch (e) {
      print('❌ [DELETE_MATERIAL] Exception: $e');
      rethrow;
    }
  }

  // Get submissions for an assignment (from assignment API)
  static Future<Map<String, dynamic>> getSubmissions({
    required String teacherCode,
    required int materialRecNo,
    String filterStatus = 'All',
  }) async {
    print('🟠 [GET_SUBMISSIONS] Starting API call...');
    print('🟠 TeacherCode: $teacherCode, MaterialRecNo: $materialRecNo');

    try {
      final requestBody = {
        "action": "GET_SUBMISSIONS",
        "TeacherCode": teacherCode,
        "MaterialRecNo": materialRecNo,
        "FilterStatus": filterStatus,
      };

      print('🟠 Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(assignmentBaseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print('🟠 Response Status: ${response.statusCode}');
      print('🟠 Response Body: ${response.body}');

      final decoded = jsonDecode(response.body);

      if (decoded['status'] == 'success') {
        print('✅ [GET_SUBMISSIONS] Success!');
        return decoded;
      } else {
        print('❌ [GET_SUBMISSIONS] API returned error');
        throw Exception(decoded['message'] ?? 'Error fetching submissions');
      }
    } catch (e) {
      print('❌ [GET_SUBMISSIONS] Exception: $e');
      rethrow;
    }
  }

  // Grade a submission
  static Future<Map<String, dynamic>> gradeSubmission({
    required String teacherCode,
    required int submissionRecNo,
    required double marksObtained,
    String? teacherFeedback,
  }) async {
    print('🟣 [GRADE_SUBMISSION] Starting API call...');
    print('🟣 TeacherCode: $teacherCode, SubmissionRecNo: $submissionRecNo');

    try {
      final requestBody = {
        "action": "GRADE_SUBMISSION",
        "TeacherCode": teacherCode,
        "SubmissionRecNo": submissionRecNo,
        "MarksObtained": marksObtained,
        if (teacherFeedback != null) "TeacherFeedback": teacherFeedback,
      };

      print('🟣 Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(assignmentBaseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print('🟣 Response Status: ${response.statusCode}');
      print('🟣 Response Body: ${response.body}');

      final decoded = jsonDecode(response.body);

      if (decoded['status'] == 'success') {
        print('✅ [GRADE_SUBMISSION] Success!');
        return decoded;
      } else {
        print('❌ [GRADE_SUBMISSION] API returned error');
        throw Exception(decoded['message'] ?? 'Error grading submission');
      }
    } catch (e) {
      print('❌ [GRADE_SUBMISSION] Exception: $e');
      rethrow;
    }
  }

  // Get material statistics (for assignment cards)
  static Future<Map<String, dynamic>> getMaterialStats({
    required String teacherCode,
    required int materialRecNo,
  }) async {
    print('🟠 [GET_MATERIAL_STATS] Starting API call...');
    print('🟠 TeacherCode: $teacherCode, MaterialRecNo: $materialRecNo');

    try {
      final requestBody = {
        "action": "GET_MATERIAL_STATS",
        "TeacherCode": teacherCode,
        "MaterialRecNo": materialRecNo,
      };

      print('🟠 Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(assignmentBaseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print('🟠 Response Status: ${response.statusCode}');
      print('🟠 Response Body: ${response.body}');

      final decoded = jsonDecode(response.body);

      if (decoded['status'] == 'success') {
        print('✅ [GET_MATERIAL_STATS] Success!');
        return decoded;
      } else {
        print('❌ [GET_MATERIAL_STATS] API returned error');
        throw Exception(decoded['message'] ?? 'Error fetching stats');
      }
    } catch (e) {
      print('❌ [GET_MATERIAL_STATS] Exception: $e');
      rethrow;
    }
  }
}
