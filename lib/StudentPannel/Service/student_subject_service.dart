import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lms_publisher/StudentPannel/Service/student_subject_service.dart';

class StudentSubjectService {
  // API URLs
  static const String baseUrl = 'https://aquare.co.in/mobileAPI/sachin/lms';
  static const String documentBaseUrl = "https://storage.googleapis.com/upload-images-34/documents/LMS/";
  static const String manageAiPaperUrl = 'https://aquare.co.in/mobileAPI/sachin/lms/manage_ai_paper.php';
  static const String submitUrl = 'https://aquare.co.in/mobileAPI/sachin/lms/submit_ai_paper_api.php';

  // Helper function to get YouTube thumbnail
  static String getYouTubeThumbnail(String videoUrl) {
    try {
      final uri = Uri.parse(videoUrl);
      String? videoId;
      if (uri.host.contains('youtube.com')) {
        videoId = uri.queryParameters['v'];
      } else if (uri.host.contains('youtu.be')) {
        videoId = uri.pathSegments.first;
      }

      if (videoId != null && videoId.isNotEmpty) {
        return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
      }
    } catch (e) {
      print('Error parsing YouTube URL: $e');
    }
    return 'https://via.placeholder.com/1280x720/4CAF50/FFFFFF?text=Video';
  }

  // Helper function to get full document URL
  static String getDocumentUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    return '$documentBaseUrl$relativePath';
  }


  // ✅ ADD: Submit AI Paper Method
  static Future<Map<String, dynamic>> submitAiPaper({
    required String studentCode,  // Student RecNo (e.g., from user profile)
    required int materialRecNo, // From TeacherMaterialModel
    required int paperId,       // From TeacherMaterialModel
    required List<Map<String, dynamic>> answers, // [{ "question_id": 1, "answer": "OptionA" }]
  }) async {
    // NOTE: Replace with your actual PHP API URL


    try {
      print('📤 Submitting AI Paper...');
      final requestBody = {
        "action": "SUBMIT_AI_PAPER",
        "student_code": studentCode, // Send String
        "material_rec_no": materialRecNo,
        "paper_id": paperId,
        "answers": answers
      };

      print('   Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(submitUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print('   Response: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == 'success') {
          return decoded;
        } else {
          throw Exception(decoded['message'] ?? 'Submission failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error submitting paper: $e');
      rethrow;
    }
  }


  static Future<Map<String, dynamic>> getAiPaperDetails({
    required int paperId,
    required String teacherCode
  }) async {
    try {
      print('📄 [Student] Fetching AI Paper Details: $paperId');

      final requestBody = {
        "action": "MANAGE_AI_PAPER",
        "SubAction": "GET_PAPER_DETAILS",
        "TeacherCode": teacherCode, // ✅ USING REAL TEACHER CODE
        "PaperID": paperId,
      };

      print('   Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(manageAiPaperUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print('   Response: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == 'success') {
          return decoded;
        } else {
          throw Exception(decoded['message'] ?? 'Failed to load paper details');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching paper: $e');
      rethrow;
    }
  }


  // Existing methods...
  static Future<SubjectsResponse> getStudentSubjects(String studentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/student_subjects_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'GET_SUBJECTS',
          'Student_ID': studentId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SubjectsResponse.fromJson(data);
      } else {
        throw Exception('Failed to load subjects: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching subjects: $e');
    }
  }

  static Future<ChaptersResponse> getSubjectChapters(String studentId,
      int subjectId,) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/student_subjects_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'GET_CHAPTERS',
          'Student_ID': studentId,
          'SubjectID': subjectId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ChaptersResponse.fromJson(data);
      } else {
        throw Exception('Failed to load chapters: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching chapters: $e');
    }
  }

  static Future<MaterialsResponse> getChapterMaterials(String studentId,
      int chapterId,) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/student_subjects_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'GET_MATERIALS',
          'Student_ID': studentId,
          'ChapterID': chapterId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MaterialsResponse.fromJson(data);
      } else {
        throw Exception('Failed to load materials: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching materials: $e');
    }
  }

  static Future<TeacherStudentNotesResponse> getStudentNotes({
    required String studentId,
    int? chapterId,
    int? subjectId,
    int? isPrivate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/teacher_student_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'GET_STUDENT_NOTES',
          'Student_ID': studentId,
          if (chapterId != null) 'ChapterID': chapterId,
          if (subjectId != null) 'SubjectID': subjectId,
          if (isPrivate != null) 'IsPrivate': isPrivate,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TeacherStudentNotesResponse.fromJson(data);
      } else {
        throw Exception('Failed to load notes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching notes: $e');
    }
  }


// ✅ UPDATED: getTeacherMaterials with student_code parameter
  static Future<TeacherMaterialsResponse> getTeacherMaterials({
    required String teacherCode,
    required String studentCode,
    int? chapterId,
  }) async {
    try {
      print('🔄 Calling getTeacherMaterials API...');
      print('   Teacher Code: $teacherCode');
      print('   Student Code: $studentCode');
      print('   Chapter ID: ${chapterId ?? "NULL"}');

      final response = await http.post(
        Uri.parse('$baseUrl/teacher_student_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'GET_TEACHER_MATERIALS',
          'teacher_code': teacherCode,
          'student_code': studentCode,
          if (chapterId != null) 'chapter_id': chapterId,
        }),
      );

      print('   Response Status: ${response.statusCode}');
      print('   Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('   ✅ API Response Success');
        return TeacherMaterialsResponse.fromJson(data);
      } else {
        throw Exception('Failed to load materials: ${response.statusCode}');
      }
    } catch (e) {
      print('   ❌ API Error: $e');
      throw Exception('Error fetching teacher materials: $e');
    }
  }
}
// ✅ FIXED: TeacherMaterialsResponse
class TeacherMaterialsResponse {
  final String status;
  final String action;
  final String teacherCode;
  final String studentCode;
  final int? chapterId;
  final List<TeacherMaterialModel> materials;
  final List<StudentSubmissionModel> submissions;

  TeacherMaterialsResponse({
    required this.status,
    required this.action,
    required this.teacherCode,
    required this.studentCode,
    this.chapterId,
    required this.materials,
    required this.submissions,
  });

  factory TeacherMaterialsResponse.fromJson(Map<String, dynamic> json) {
    // ✅ FIX: Handle the "data" wrapper from API
    List<TeacherMaterialModel> parseMaterials() {
      final materialsData = json['materials'];
      if (materialsData == null) return [];

      // If it's a map with 'data' key
      if (materialsData is Map) {
        final data = materialsData['data'];
        if (data is List) {
          return data
              .map((item) => TeacherMaterialModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      // If it's already a list
      else if (materialsData is List) {
        return materialsData
            .map((item) => TeacherMaterialModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    List<StudentSubmissionModel> parseSubmissions() {
      final submissionsData = json['submissions'];
      if (submissionsData == null) return [];

      // If it's a map with 'data' key
      if (submissionsData is Map) {
        final data = submissionsData['data'];
        if (data is List) {
          return data
              .map((item) => StudentSubmissionModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      // If it's already a list
      else if (submissionsData is List) {
        return submissionsData
            .map((item) => StudentSubmissionModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    return TeacherMaterialsResponse(
      status: json['status'] ?? 'error',
      action: json['action'] ?? 'GET_TEACHER_MATERIALS',
      teacherCode: json['teacher_code'] ?? '',
      studentCode: json['student_code'] ?? '',
      chapterId: json['chapter_id'],
      materials: parseMaterials(),
      submissions: parseSubmissions(),
    );
  }
}

class TeacherMaterialModel {
  final int recNo;
  final int materialRecNo;
  final int teacherRecNo;
  final int chapterId;
  final String materialType;
  final String materialTitle;
  final String? materialPath;
  final String? materialLink;
  final String? scheduleReleaseDate;
  final String? actualReleaseDate;
  final String? description;
  final int viewCount;
  final String createdDate;
  final int isActive;
  final String? dueDate;
  final int? totalMarks;
  final int? passingMarks;
  final int? allowLateSubmission;
  final String? lateSubmissionPenalty;
  final String? lateSubmissionDeadline;
  final String? availableFrom;
  final int? allowedAttempts;
  final String? submissionType;
  final String? allowedFileTypes;
  final String? publishStatus;
  final String? instructionFilePath;

  // ✅ ADD THIS: Paper ID for AI generated papers
  final int? paperId;

  // Teacher Info
  final String teacherCode;
  final String teacherName;

  // Chapter Info
  final String chapterName;
  final int chapterOrder;
  final int subjectId;

  // Subject Info
  final String subjectName;
  final String subjectCode;

  // Assignment Status
  final String assignmentStatus;
  final int? daysRemaining;
  final int mySubmissionCount;
  final String? myLatestSubmissionStatus;
  final double? myMarks;

  TeacherMaterialModel({
    required this.recNo,
    required this.materialRecNo,
    required this.teacherRecNo,
    required this.chapterId,
    required this.materialType,
    required this.materialTitle,
    this.materialPath,
    this.materialLink,
    this.scheduleReleaseDate,
    this.actualReleaseDate,
    this.description,
    required this.viewCount,
    required this.createdDate,
    required this.isActive,
    this.dueDate,
    this.totalMarks,
    this.passingMarks,
    this.allowLateSubmission,
    this.lateSubmissionPenalty,
    this.lateSubmissionDeadline,
    this.availableFrom,
    this.allowedAttempts,
    this.submissionType,
    this.allowedFileTypes,
    this.publishStatus,
    this.instructionFilePath,
    this.paperId, // ✅ ADD THIS
    required this.teacherCode,
    required this.teacherName,
    required this.chapterName,
    required this.chapterOrder,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.assignmentStatus,
    this.daysRemaining,
    required this.mySubmissionCount,
    this.myLatestSubmissionStatus,
    this.myMarks,
  });

  factory TeacherMaterialModel.fromJson(Map<String, dynamic> json) {
    return TeacherMaterialModel(
      recNo: json['RecNo'] ?? 0,
      materialRecNo: json['MaterialRecNo'] ?? json['RecNo'] ?? 0,
      teacherRecNo: json['TeacherRecNo'] ?? 0,
      chapterId: json['ChapterID'] ?? 0,
      materialType: json['MaterialType'] ?? 'Material',
      materialTitle: json['MaterialTitle'] ?? 'Untitled',
      materialPath: json['MaterialPath'],
      materialLink: json['MaterialLink'],
      scheduleReleaseDate: json['ScheduleReleaseDate'],
      actualReleaseDate: json['ActualReleaseDate'],
      description: json['Description'],
      viewCount: json['ViewCount'] ?? 0,
      createdDate: json['Created_Date'] ?? '',
      isActive: json['IsActive'] ?? 0,
      dueDate: json['DueDate'],
      totalMarks: json['TotalMarks'] is int
          ? json['TotalMarks']
          : int.tryParse(json['TotalMarks'].toString()),
      passingMarks: json['PassingMarks'] is int
          ? json['PassingMarks']
          : int.tryParse(json['PassingMarks'].toString()),
      allowLateSubmission: json['AllowLateSubmission'] is int
          ? json['AllowLateSubmission']
          : (json['AllowLateSubmission'] == '1' ? 1 : 0),
      lateSubmissionPenalty: json['LateSubmissionPenalty']?.toString(),
      lateSubmissionDeadline: json['LateSubmissionDeadline'],
      availableFrom: json['AvailableFrom'],
      allowedAttempts: json['AllowedAttempts'] is int
          ? json['AllowedAttempts']
          : int.tryParse(json['AllowedAttempts'].toString()),
      submissionType: json['SubmissionType'],
      allowedFileTypes: json['AllowedFileTypes'],
      publishStatus: json['PublishStatus'],
      instructionFilePath: json['InstructionFilePath'],

      // ✅ ADD THIS: Safe parsing for PaperID
      paperId: json['PaperID'] is int
          ? json['PaperID']
          : (json['PaperID'] != null ? int.tryParse(json['PaperID'].toString()) : null),

      teacherCode: json['TeacherCode'] ?? '',
      teacherName: json['TeacherName'] ?? 'Unknown',
      chapterName: json['ChapterName'] ?? '',
      chapterOrder: json['ChapterOrder'] ?? 0,
      subjectId: json['SubjectID'] ?? 0,
      subjectName: json['SubjectName'] ?? '',
      subjectCode: json['SubjectCode'] ?? '',
      assignmentStatus: json['AssignmentStatus'] ?? 'Active',
      daysRemaining: json['DaysRemaining'] is int
          ? json['DaysRemaining']
          : (json['DaysRemaining'] != null ? int.tryParse(json['DaysRemaining'].toString()) : null),
      mySubmissionCount: json['MySubmissionCount'] ?? 0,
      myLatestSubmissionStatus: json['MyLatestSubmissionStatus'],
      myMarks: json['MyMarks'] is double
          ? json['MyMarks']
          : (json['MyMarks'] != null ? double.tryParse(json['MyMarks'].toString()) : null),
    );
  }
}


class StudentSubmissionModel {
  final int recNo;
  final int studentRecNo;
  final int materialRecNo;
  final int attemptNumber;
  final String submissionDate;
  final String submissionType;
  final String? submissionFilePath;
  final String? submissionText;
  final String? submissionLink;
  final int isLateSubmission;
  final int? daysLate;
  final double? marksObtained;
  final double? marksAfterPenalty;
  final String gradeStatus;
  final String? teacherFeedback;
  final String? gradedDate;
  final String? gradedBy;
  final String submissionStatus;
  final String? studentComments;
  final String createdDate;
  final String modifiedDate;

  // Material Info
  final String materialTitle;
  final int totalMarks;
  final String? dueDate;

  // Chapter Info
  final String chapterName;

  // Student Info
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String admissionNumber;

  StudentSubmissionModel({
    required this.recNo,
    required this.studentRecNo,
    required this.materialRecNo,
    required this.attemptNumber,
    required this.submissionDate,
    required this.submissionType,
    this.submissionFilePath,
    this.submissionText,
    this.submissionLink,
    required this.isLateSubmission,
    this.daysLate,
    this.marksObtained,
    this.marksAfterPenalty,
    required this.gradeStatus,
    this.teacherFeedback,
    this.gradedDate,
    this.gradedBy,
    required this.submissionStatus,
    this.studentComments,
    required this.createdDate,
    required this.modifiedDate,
    required this.materialTitle,
    required this.totalMarks,
    this.dueDate,
    required this.chapterName,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.admissionNumber,
  });

  factory StudentSubmissionModel.fromJson(Map<String, dynamic> json) {
    return StudentSubmissionModel(
      recNo: json['RecNo'] ?? 0,
      studentRecNo: json['StudentRecNo'] ?? 0,
      materialRecNo: json['MaterialRecNo'] ?? 0,
      attemptNumber: json['AttemptNumber'] ?? 1,
      submissionDate: json['SubmissionDate'] ?? '',
      submissionType: json['SubmissionType'] ?? '',
      submissionFilePath: json['SubmissionFilePath'],
      submissionText: json['SubmissionText'],
      submissionLink: json['SubmissionLink'],
      isLateSubmission: json['IsLateSubmission'] is int ? json['IsLateSubmission'] : (json['IsLateSubmission'] == '1' ? 1 : 0),
      daysLate: json['DaysLate'] is int ? json['DaysLate'] : int.tryParse(json['DaysLate'].toString() ?? '0'),
      marksObtained: json['MarksObtained'] is double
          ? json['MarksObtained']
          : (json['MarksObtained'] != null ? double.tryParse(json['MarksObtained'].toString()) : null),
      marksAfterPenalty: json['MarksAfterPenalty'] is double
          ? json['MarksAfterPenalty']
          : (json['MarksAfterPenalty'] != null ? double.tryParse(json['MarksAfterPenalty'].toString()) : null),
      gradeStatus: json['GradeStatus'] ?? 'Pending',
      teacherFeedback: json['TeacherFeedback'],
      gradedDate: json['GradedDate'],

      // ✅ THE FIX IS HERE:
      // Convert the value (which can be int or null) to a String?
      gradedBy: json['GradedBy']?.toString(),

      submissionStatus: json['SubmissionStatus'] ?? 'Submitted',
      studentComments: json['StudentComments'],
      createdDate: json['Created_Date'] ?? '',
      modifiedDate: json['Modified_Date'] ?? '',
      materialTitle: json['MaterialTitle'] ?? '',
      totalMarks: json['TotalMarks'] is int
          ? json['TotalMarks']
          : int.tryParse(json['TotalMarks'].toString()) ?? 0,
      dueDate: json['DueDate'],
      chapterName: json['ChapterName'] ?? '',
      studentId: json['Student_ID'] ?? '',
      studentName: json['StudentName'] ?? '',
      rollNumber: json['Roll_Number'] ?? '',
      admissionNumber: json['Admission_Number'] ?? '',
    );
  }

  bool get isLate => isLateSubmission == 1;
}



class TeacherStudentNotesResponse {
  final String status;
  final List<TeacherNoteModel> notes;
  final int count;

  TeacherStudentNotesResponse({
    required this.status,
    required this.notes,
    required this.count,
  });

  factory TeacherStudentNotesResponse.fromJson(Map<String, dynamic> json) {
    return TeacherStudentNotesResponse(
      status: json['status'] ?? '',
      notes: (json['notes'] as List?)
          ?.map((item) => TeacherNoteModel.fromJson(item))
          .toList() ??
          [],
      count: json['count'] ?? 0,
    );
  }
}

class TeacherNoteModel {
  final int recNo;
  final int studentRecNo;
  final int teacherRecNo;
  final int? subjectId;
  final int? chapterId;
  final String noteText;
  final String noteCategory;
  final String noteDate;
  final bool isPrivate;
  final String createdDate;
  final String? modifiedDate;
  final String studentId;
  final String studentName;
  final String? rollNumber;
  final String teacherCode;
  final String teacherName;
  final String? teacherEmail;
  final String? subjectName;
  final String? chapterName;

  TeacherNoteModel({
    required this.recNo,
    required this.studentRecNo,
    required this.teacherRecNo,
    this.subjectId,
    this.chapterId,
    required this.noteText,
    required this.noteCategory,
    required this.noteDate,
    required this.isPrivate,
    required this.createdDate,
    this.modifiedDate,
    required this.studentId,
    required this.studentName,
    this.rollNumber,
    required this.teacherCode,
    required this.teacherName,
    this.teacherEmail,
    this.subjectName,
    this.chapterName,
  });

  factory TeacherNoteModel.fromJson(Map<String, dynamic> json) {
    return TeacherNoteModel(
      recNo: json['RecNo'] ?? 0,
      studentRecNo: json['StudentRecNo'] ?? 0,
      teacherRecNo: json['TeacherRecNo'] ?? 0,
      subjectId: json['SubjectID'],
      chapterId: json['ChapterID'],
      noteText: json['NoteText'] ?? '',
      noteCategory: json['NoteCategory'] ?? '',
      noteDate: json['NoteDate'] ?? '',
      isPrivate: json['IsPrivate'] == 1 || json['IsPrivate'] == true,
      createdDate: json['Created_Date'] ?? '',
      modifiedDate: json['Modified_Date'],
      studentId: json['Student_ID'] ?? '',
      studentName: json['StudentName'] ?? '',
      rollNumber: json['Roll_Number'],
      teacherCode: json['TeacherCode'] ?? '',
      teacherName: json['TeacherName'] ?? '',
      teacherEmail: json['TeacherEmail'],
      subjectName: json['SubjectName'],
      chapterName: json['ChapterName'],
    );
  }
}


 const String documentBaseUrl = "https://storage.googleapis.com/upload-images-34/documents/LMS/";


// ========== RESPONSE MODELS ==========

// ========================================
// COMPLETE RESPONSE MODELS
// ========================================

class SubjectsResponse {
  final String status;
  final String action;
  final String studentId;
  final String academicYear;
  final ClassInfo? classInfo;
  final int subjectCount;
  final List<SubjectModel> subjects;

  SubjectsResponse({
    required this.status,
    required this.action,
    required this.studentId,
    required this.academicYear,
    this.classInfo,
    required this.subjectCount,
    required this.subjects,
  });

  factory SubjectsResponse.fromJson(Map<String, dynamic> json) {
    return SubjectsResponse(
      status: json['status'] ?? 'error',
      action: json['action'] ?? 'GET_SUBJECTS',
      studentId: json['student_id'] ?? '',
      academicYear: json['academic_year'] ?? 'current',
      classInfo: json['class_info'] != null
          ? ClassInfo.fromJson(json['class_info'])
          : null,
      subjectCount: json['subject_count'] ?? 0,
      subjects: (json['data'] as List?)
          ?.map((item) => SubjectModel.fromJson(item))
          .toList() ??
          [],
    );
  }
}

// ========================================
// CLASS INFO MODEL
// ========================================

class ClassInfo {
  final int classRecNo;
  final int classId;
  final String className;
  final String classCode;
  final String sectionName;
  final String academicYear;
  final DateTime classStartDate;
  final DateTime classEndDate;
  final int classTeacherRecNo;
  final String teacherCode;
  final String classTeacherFirstName;
  final String? classTeacherMiddleName;
  final String classTeacherLastName;
  final String classTeacherFullName;
  final String classTeacherMobile;
  final String? classTeacherEmail;
  final String classTeacherDesignation;
  final String classTeacherDepartment;
  final String? classTeacherPhoto;
  final DateTime classTeacherDateOfJoining;
  final int classTeacherExperienceYears;

  ClassInfo({
    required this.classRecNo,
    required this.classId,
    required this.className,
    required this.classCode,
    required this.sectionName,
    required this.academicYear,
    required this.classStartDate,
    required this.classEndDate,
    required this.classTeacherRecNo,
    required this.teacherCode,
    required this.classTeacherFirstName,
    this.classTeacherMiddleName,
    required this.classTeacherLastName,
    required this.classTeacherFullName,
    required this.classTeacherMobile,
    this.classTeacherEmail,
    required this.classTeacherDesignation,
    required this.classTeacherDepartment,
    this.classTeacherPhoto,
    required this.classTeacherDateOfJoining,
    required this.classTeacherExperienceYears,
  });

  factory ClassInfo.fromJson(Map<String, dynamic> json) {
    return ClassInfo(
      classRecNo: _parseInt(json['ClassRecNo']),
      classId: _parseInt(json['ClassID']),
      className: json['Class_Name'] ?? 'Unknown Class',
      classCode: json['Class_Code'] ?? '',
      sectionName: json['Section_Name'] ?? '',
      academicYear: json['Academic_Year'] ?? '',
      classStartDate: _parseDateTime(json['Class_Start_Date']),
      classEndDate: _parseDateTime(json['Class_End_Date']),
      classTeacherRecNo: _parseInt(json['Class_Teacher_RecNo']),
      teacherCode: json['TeacherCode'] ?? '',
      classTeacherFirstName: json['Class_Teacher_FirstName'] ?? '',
      classTeacherMiddleName: json['Class_Teacher_MiddleName'],
      classTeacherLastName: json['Class_Teacher_LastName'] ?? '',
      classTeacherFullName: json['Class_Teacher_FullName'] ?? '',
      classTeacherMobile: json['Class_Teacher_Mobile'] ?? '',
      classTeacherEmail: json['Class_Teacher_Email'],
      classTeacherDesignation: json['Class_Teacher_Designation'] ?? '',
      classTeacherDepartment: json['Class_Teacher_Department'] ?? '',
      classTeacherPhoto: json['Class_Teacher_Photo'],
      classTeacherDateOfJoining:
      _parseDateTime(json['Class_Teacher_DateOfJoining']),
      classTeacherExperienceYears:
      _parseInt(json['Class_Teacher_ExperienceYears']),
    );
  }
}

// ========================================
// SUBJECT MODEL (UPDATED)
// ========================================

class SubjectModel {
  final int subjectId;
  final int classId;
  final String subjectName;
  final String subjectCode;
  final String subjectDescription;
  final String displaySubjectName;
  final int totalChapters;
  final int completedChapters;
  final double progressPercentage;
  final int? currentChapterId;
  final String? currentChapterName;
  final int totalTimeSpentMinutes;
  final DateTime? lastStudiedDateTime;
  final String lastStudiedDisplay;
  final List<TeacherModel> teachers;

  SubjectModel({
    required this.subjectId,
    required this.classId,
    required this.subjectName,
    required this.subjectCode,
    required this.subjectDescription,
    required this.displaySubjectName,
    required this.totalChapters,
    required this.completedChapters,
    required this.progressPercentage,
    this.currentChapterId,
    this.currentChapterName,
    required this.totalTimeSpentMinutes,
    this.lastStudiedDateTime,
    required this.lastStudiedDisplay,
    required this.teachers,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      subjectId: _parseInt(json['SubjectID']),
      classId: _parseInt(json['ClassID']),
      subjectName: json['SubjectName'] ?? '',
      subjectCode: json['SubjectCode'] ?? '',
      subjectDescription: json['SubjectDescription'] ?? '',
      displaySubjectName: json['Display_Subject_Name'] ?? '',
      totalChapters: _parseInt(json['Total_Chapters']),
      completedChapters: _parseInt(json['Completed_Chapters']),
      progressPercentage: _parseDouble(json['Progress_Percentage']),
      currentChapterId: json['Current_ChapterID'] != null
          ? _parseInt(json['Current_ChapterID'])
          : null,
      currentChapterName: json['Current_Chapter_Name'],
      totalTimeSpentMinutes: _parseInt(json['Total_Time_Spent_Minutes']),
      lastStudiedDateTime:
      _parseDateTime(json['Last_Studied_DateTime']),
      lastStudiedDisplay: json['Last_Studied_Display'] ?? 'Never',
      teachers: (json['teachers'] as List?)
          ?.map((item) => TeacherModel.fromJson(item))
          .toList() ??
          [],
    );
  }
}

// ========================================
// TEACHER MODEL (UPDATED)
// ========================================

class TeacherModel {
  final int allotmentRecNo;
  final int subjectId;
  final int classId;
  final int teacherRecNo;
  final String teacherCode;
  final String? employeeCode;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String teacherFullName;
  final String? designation;
  final String? department;
  final String mobileNumber;
  final String? institutionalEmail;
  final String? teacherPhoto;
  final DateTime? dateOfJoining;
  final int experienceYears;
  final String? employeeStatus;
  final bool isActive;
  final int statusId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String academicYear;
  final bool isCurrentTeacher;

  TeacherModel({
    required this.allotmentRecNo,
    required this.subjectId,
    required this.classId,
    required this.teacherRecNo,
    required this.teacherCode,
    this.employeeCode,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.teacherFullName,
    this.designation,
    this.department,
    required this.mobileNumber,
    this.institutionalEmail,
    this.teacherPhoto,
    this.dateOfJoining,
    required this.experienceYears,
    this.employeeStatus,
    required this.isActive,
    required this.statusId,
    this.startDate,
    this.endDate,
    required this.academicYear,
    required this.isCurrentTeacher,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      allotmentRecNo: _parseInt(json['Allotment_RecNo']),
      subjectId: _parseInt(json['SubjectID']),
      classId: _parseInt(json['ClassID']),
      teacherRecNo: _parseInt(json['TeacherRecNo']),
      teacherCode: json['TeacherCode'] ?? '',
      employeeCode: json['EmployeeCode'],
      firstName: json['FirstName'] ?? '',
      middleName: json['MiddleName'],
      lastName: json['LastName'] ?? '',
      teacherFullName: json['TeacherFullName'] ?? '',
      designation: json['Designation'],
      department: json['Department'],
      mobileNumber: json['MobileNumber'] ?? '',
      institutionalEmail: json['InstitutionalEmail'],
      teacherPhoto: json['TeacherPhoto'],
      dateOfJoining: _parseDateTime(json['DateOfJoining']),
      experienceYears: _parseInt(json['ExperienceYears']),
      employeeStatus: json['EmployeeStatus'],
      isActive: _parseBool(json['IsActive']),
      statusId: _parseInt(json['Status_ID']),
      startDate: _parseDateTime(json['Start_Date']),
      endDate: _parseDateTime(json['End_Date']),
      academicYear: json['Academic_Year'] ?? '',
      isCurrentTeacher: _parseBool(json['Is_Current_Teacher']),
    );
  }
}

// ========================================
// UTILITY PARSING FUNCTIONS
// ========================================

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is double) return value.toInt();
  return 0;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

bool _parseBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return false;
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}


class ChaptersResponse {
  final String status;
  final SubjectInfo subjectInfo;
  final List<ChapterModel> chapters;

  ChaptersResponse({
    required this.status,
    required this.subjectInfo,
    required this.chapters,
  });

  factory ChaptersResponse.fromJson(Map<String, dynamic> json) {
    return ChaptersResponse(
      status: json['status'] ?? '',
      subjectInfo: SubjectInfo.fromJson(json['subject_info'] ?? {}),
      chapters: (json['chapters'] as List?)
          ?.map((item) => ChapterModel.fromJson(item))
          .toList() ??
          [],
    );
  }
}

class MaterialsResponse {
  final String status;
  final ChapterInfo chapterInfo;
  final Map<String, dynamic> materials;
  final int materialCount;

  MaterialsResponse({
    required this.status,
    required this.chapterInfo,
    required this.materials,
    required this.materialCount,
  });

  factory MaterialsResponse.fromJson(Map<String, dynamic> json) {
    dynamic materialsData = json['materials'];
    Map<String, dynamic> materialsMap = {};

    if (materialsData is Map) {
      materialsMap = materialsData as Map<String, dynamic>;
    } else if (materialsData is List) {
      for (var item in materialsData) {
        if (item is Map && item.containsKey('type')) {
          materialsMap[item['type']] = item;
        }
      }
    }

    return MaterialsResponse(
      status: json['status'] ?? '',
      chapterInfo: ChapterInfo.fromJson(json['chapter_info'] ?? {}),
      materials: materialsMap,
      materialCount: json['material_count'] ?? 0,
    );
  }
}



class MaterialFile {
  final int sno;
  final String path;
  final String type;
  final String name;

  // ✅ ADD THESE FIELDS TO MATCH API RESPONSE
  final double? progress;
  final int? lastPosition;
  final bool? completed;
  final int? viewCount;
  final String? lastAccessed;

  MaterialFile({
    required this.sno,
    required this.path,
    required this.type,
    required this.name,
    this.progress,
    this.lastPosition,
    this.completed,
    this.viewCount,
    this.lastAccessed,
  });

  factory MaterialFile.fromJson(Map<String, dynamic> json) {
    return MaterialFile(
      sno: json['sno'] as int,
      path: json['path'] as String,
      type: json['type'] as String,
      name: json['name'] as String? ?? 'Unnamed File',
      // ✅ Parse progress fields from API
      progress: (json['progress'] as num?)?.toDouble(),
      lastPosition: (json['last_position'] as num?)?.toInt(),
      completed: json['completed'] as bool?,
      viewCount: (json['view_count'] as num?)?.toInt(),
      lastAccessed: json['last_accessed'] as String?,
    );
  }

  String get fullUrl => 'https://storage.googleapis.com/upload-images-34/documents/LMS/$path';
}



class SubjectInfo {
  final int subjectId;
  final String subjectName;
  final String? teacherNames;
  final int totalChapters;
  final int completedChapters;
  final double overallProgress;

  SubjectInfo({
    required this.subjectId,
    required this.subjectName,
    this.teacherNames,
    required this.totalChapters,
    required this.completedChapters,
    required this.overallProgress,
  });

  factory SubjectInfo.fromJson(Map<String, dynamic> json) {
    return SubjectInfo(
      subjectId: json['SubjectID'] ?? 0,
      subjectName: json['SubjectName'] ?? '',
      teacherNames: json['Teacher_Names'],
      totalChapters: json['Total_Chapters'] ?? 0,
      completedChapters: json['Completed_Chapters'] ?? 0,
      overallProgress: (json['Overall_Progress'] ?? 0).toDouble(),
    );
  }
}

class ChapterModel {
  final int chapterId;
  final String chapterName;
  final String displayChapterName;
  final String? chapterDescription;
  final int chapterOrder;
  final int materialCount;
  final String completionStatus;
  final double progressPercentage;
  final int timeSpentMinutes;
  final String? lastAccessedDate;
  final bool isFavorite;
  final bool isLocked;
  final String lastAccessedDisplay;

  ChapterModel({
    required this.chapterId,
    required this.chapterName,
    required this.displayChapterName,
    this.chapterDescription,
    required this.chapterOrder,
    required this.materialCount,
    required this.completionStatus,
    required this.progressPercentage,
    required this.timeSpentMinutes,
    this.lastAccessedDate,
    required this.isFavorite,
    required this.isLocked,
    required this.lastAccessedDisplay,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      chapterId: json['ChapterID'] ?? 0,
      chapterName: json['ChapterName'] ?? '',
      displayChapterName: json['Display_Chapter_Name'] ?? '',
      chapterDescription: json['ChapterDescription'],
      chapterOrder: json['ChapterOrder'] ?? 0,
      materialCount: json['Material_Count'] ?? 0,
      completionStatus: json['Completion_Status'] ?? 'Not Started',
      progressPercentage: (json['Progress_Percentage'] ?? 0).toDouble(),
      timeSpentMinutes: json['Time_Spent_Minutes'] ?? 0,
      lastAccessedDate: json['Last_Accessed_Date'],
      isFavorite: json['Is_Favorite'] == 1 || json['Is_Favorite'] == true,
      isLocked: json['Is_Locked'] == 1 || json['Is_Locked'] == true,
      lastAccessedDisplay: json['Last_Accessed_Display'] ?? 'Never',
    );
  }
}

class ChapterInfo {
  final int chapterId;
  final String chapterName;
  final String? chapterDescription;
  final String subjectName;
  final double progressPercentage;
  final int timeSpentMinutes;
  final String completionStatus;

  ChapterInfo({
    required this.chapterId,
    required this.chapterName,
    this.chapterDescription,
    required this.subjectName,
    required this.progressPercentage,
    required this.timeSpentMinutes,
    required this.completionStatus,
  });

  factory ChapterInfo.fromJson(Map<String, dynamic> json) {
    return ChapterInfo(
      chapterId: json['ChapterID'] ?? 0,
      chapterName: json['ChapterName'] ?? '',
      chapterDescription: json['ChapterDescription'],
      subjectName: json['SubjectName'] ?? '',
      progressPercentage: (json['Progress_Percentage'] ?? 0).toDouble(),
      timeSpentMinutes: json['Time_Spent_Minutes'] ?? 0,
      completionStatus: json['Completion_Status'] ?? 'Not Started',
    );
  }
}

