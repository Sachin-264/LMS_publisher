import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
// Make sure to import your AiGeneratorDialog to access PaperSection or define it in a shared model file
import 'package:lms_publisher/Teacher_Panel/MyClass/ai_generator_dialog.dart';



class TeacherMaterialService {
  static const String baseUrl = 'http://localhost/AquareLMS/teacher_material.php';
  static const String assignmentBaseUrl = 'http://localhost/AquareLMS/assignment_api.php';
  static const String aiBaseUrl = 'http://localhost/AquareLMS/ai_generator.php';
  // New API URL for managing papers
  static const String manageAiPaperUrl = 'http://localhost/AquareLMS/manage_ai_paper.php';

  // ✅ ADD THIS TO TeacherMaterialService
  static Future<void> gradeAiPaper({
    required int submissionRecNo,
    required String teacherFeedback,
    required List<Map<String, dynamic>> gradedQuestions,
  }) async {
    const String aiApiUrl = 'http://localhost/AquareLMS/submit_ai_paper_api.php';

    try {
      final response = await http.post(
        Uri.parse(aiApiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "GRADE_SUBMISSION",
          "submission_rec_no": submissionRecNo,
          "teacher_feedback": teacherFeedback,
          "graded_questions": gradedQuestions,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data['status'] == 'error') {
        throw Exception(data['message']);
      }
    } catch (e) {
      throw Exception('Failed to save grades: $e');
    }
  }

  // ⭐ NEW: Publish AI Paper to Students
  static Future<Map<String, dynamic>> publishAiPaper({
    required String teacherCode,
    required int paperId,
    required int chapterId,
    String? dueDate,
    bool allowLateSubmission = false,
  }) async {
    print('📤 [PUBLISH_AI_PAPER] Publishing paper...');
    try {
      final requestBody = {
        "action": "PUBLISH_AI_PAPER",
        "TeacherCode": teacherCode,
        "PaperID": paperId,
        "ChapterID": chapterId,
        "DueDate": dueDate,
        "AllowLateSubmission": allowLateSubmission,
      };

      final response = await http.post(
        Uri.parse(manageAiPaperUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print('📤 Response: ${response.body}');
      final decoded = jsonDecode(response.body);

      if (decoded['status'] == 'success') {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to publish paper');
      }
    } catch (e) {
      print('❌ [PUBLISH_AI_PAPER] Error: $e');
      rethrow;
    }
  }

  // ... existing code ...

  // ✅ ADD THIS: Fetch detailed answers for grading
  static Future<Map<String, dynamic>> getStudentExamAnswers(int submissionRecNo) async {
    // Point to the AI specific API
    const String aiApiUrl = 'http://localhost/AquareLMS/submit_ai_paper_api.php';

    try {
      final response = await http.post(
        Uri.parse(aiApiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "GET_EXAM_ANSWERS",
          "submission_rec_no": submissionRecNo,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data;
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load answers: $e');
    }
  }


  // ⭐ NEW: Delete AI Paper
  static Future<Map<String, dynamic>> deleteAiPaper({
    required String teacherCode,
    required int paperId,
  }) async {
    print('🗑️ [DELETE_AI_PAPER] Starting...');
    try {
      final requestBody = {
        "action": "MANAGE_AI_PAPER",
        "SubAction": "DELETE",
        "TeacherCode": teacherCode,
        "PaperID": paperId,
      };

      final response = await http.post(
        Uri.parse(manageAiPaperUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print('🗑️ Response: ${response.body}');
      final decoded = jsonDecode(response.body);

      if (decoded['status'] == 'success') {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to delete paper');
      }
    } catch (e) {
      print('❌ [DELETE_AI_PAPER] Error: $e');
      rethrow;
    }
  }



  static Future<Map<String, dynamic>> generateAiContent({
    required PlatformFile file, // Changed from File to PlatformFile
    required String questionType,
    required int count,
    required String difficulty,
  }) async {
    print('🤖 [AI] Processing file: ${file.name}...');

    try {
      var request = http.MultipartRequest('POST', Uri.parse(aiBaseUrl));

      request.fields['action'] = 'GENERATE_QUESTIONS';
      request.fields['questionType'] = questionType;
      request.fields['count'] = count.toString();
      request.fields['difficulty'] = difficulty;

      // ⭐ SMART BYTE EXTRACTION
      List<int> fileBytes;
      if (file.bytes != null) {
        // WEB: Bytes are already in memory
        fileBytes = file.bytes!;
      } else if (file.path != null) {
        // MOBILE: Read from path
        fileBytes = await File(file.path!).readAsBytes();
      } else {
        throw Exception("Cannot read file data. File might be corrupted.");
      }

      // Send as Bytes
      request.files.add(http.MultipartFile.fromBytes(
        'pdf_file',
        fileBytes,
        filename: file.name, // PlatformFile has a direct .name property
      ));

      print('🤖 [AI] Sending ${fileBytes.length} bytes to server...');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('🤖 Response: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == 'success') {
          return decoded;
        } else {
          throw Exception(decoded['message'] ?? 'AI generation failed');
        }
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AI] Error: $e');
      rethrow;
    }
  }


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

  // Get submissions for an assignment - FIXED
  static Future<Map<String, dynamic>> getSubmissions({
    required String teacherCode,
    required int materialRecNo,
    required int classRecNo,
    String filterStatus = 'All',
  }) async {
    print('🟠 [GET_SUBMISSIONS] Starting API call...');
    print('🟠 TeacherCode: $teacherCode');
    print('🟠 MaterialRecNo: $materialRecNo (type: int)');
    print('🟠 ClassRecNo: $classRecNo (type: int)');
    print('🟠 FilterStatus: $filterStatus');

    try {
      // ✅ Ensure integers are actually integers before sending
      final requestBody = {
        "action": "GET_SUBMISSIONS",
        "TeacherCode": teacherCode,
        "MaterialRecNo": materialRecNo is int ? materialRecNo : int.parse(materialRecNo.toString()),
        "ClassRecNo": classRecNo is int ? classRecNo : int.parse(classRecNo.toString()),
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
        print('✅ Submitted Count: ${decoded['submitted_count']}');
        print('✅ Not Submitted Count: ${decoded['not_submitted_count']}');
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

  // ⭐ NEW METHOD: SAVE AI PAPER (Updated for Professional Schema)
  static Future<Map<String, dynamic>> saveAiQuestionPaper({
    required String teacherCode,
    required int chapterId,
    required String paperTitle,
    required double totalMarks,
    required String difficulty,
    // New Header Fields
    required String schoolName,
    required String examName,
    required String timeAllowed,
    required String instructions,
    // New: List of Sections (Hierarchical)
    required List<PaperSection> sections,
  }) async {
    print('🧠 [SAVE_AI_PAPER] Saving Professional Paper...');

    // Convert Sections to Nested JSON Structure
    List<Map<String, dynamic>> sectionsJson = sections.map((sec) {
      return {
        "title": sec.title,
        "questions": sec.questions.where((q) => q.model.isSelected).map((q) => {
          "question": q.model.question,
          "type": "MCQ", // You might want to pass dynamic type if available in QuestionModel
          "answer": q.model.answer,
          "explanation": q.model.explanation,
          "options": q.model.options,
          "marks": q.marks // Send individual marks per question
        }).toList()
      };
    }).toList();

    try {
      final requestBody = {
        "action": "MANAGE_AI_PAPER",
        "SubAction": "INSERT",
        "TeacherCode": teacherCode,
        "ChapterID": chapterId,
        "PaperTitle": paperTitle, // Used as internal tracking title

        // Professional Header Data
        "SchoolName": schoolName,
        "ExamName": examName,
        "TimeAllowed": timeAllowed,
        "Instructions": instructions,

        "TotalMarks": totalMarks,
        "DifficultyLevel": difficulty,

        // Nested JSON for Sections -> Questions
        "SectionsJSON": sectionsJson
      };

      print('🧠 Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(manageAiPaperUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print('🧠 Response: ${response.body}');

      final decoded = jsonDecode(response.body);
      if (decoded['status'] == 'success') {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to save paper');
      }
    } catch (e) {
      print('❌ [SAVE_AI_PAPER] Error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getAiPaperDetails({
    required String teacherCode,
    required int paperId,
  }) async {
    try {
      final requestBody = {
        "action": "MANAGE_AI_PAPER",
        "SubAction": "GET_PAPER_DETAILS",
        "TeacherCode": teacherCode,
        "PaperID": paperId,
      };

      final response = await http.post(
        Uri.parse(manageAiPaperUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      final decoded = jsonDecode(response.body);
      if (decoded['status'] == 'success') {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to load paper details');
      }
    } catch (e) {
      print('❌ [GET_AI_PAPER] Error: $e');
      rethrow;
    }
  }
}