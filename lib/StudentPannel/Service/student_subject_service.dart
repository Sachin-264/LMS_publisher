import 'dart:convert';
import 'package:http/http.dart' as http;

class StudentSubjectService {
  // API URLs
  static const String baseUrl = 'http://10.100.2.119/AquareLMS';
  static const String documentBaseUrl = "https://storage.googleapis.com/upload-images-34/documents/LMS/";

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

  static Future<ChaptersResponse> getSubjectChapters(
      String studentId,
      int subjectId,
      ) async {
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

  static Future<MaterialsResponse> getChapterMaterials(
      String studentId,
      int chapterId,
      ) async {
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
}

// ========== RESPONSE MODELS ==========

class SubjectsResponse {
  final String status;
  final String studentId;
  final int count;
  final List<SubjectModel> subjects;

  SubjectsResponse({
    required this.status,
    required this.studentId,
    required this.count,
    required this.subjects,
  });

  factory SubjectsResponse.fromJson(Map<String, dynamic> json) {
    return SubjectsResponse(
      status: json['status'] ?? '',
      studentId: json['student_id'] ?? '',
      count: json['count'] ?? 0,
      subjects: (json['data'] as List?)
          ?.map((item) => SubjectModel.fromJson(item))
          .toList() ??
          [],
    );
  }
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

// ========== DATA MODELS ==========

class MaterialFile {
  final int sno;
  final String path;
  final String type;
  final String name;

  MaterialFile({
    required this.sno,
    required this.path,
    required this.type,
    required this.name,
  });

  factory MaterialFile.fromJson(Map<String, dynamic> json) {
    return MaterialFile(
      sno: json['sno'] ?? 0,
      path: json['path'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
    );
  }

  String get fullUrl {
    if (type == 'video' || path.startsWith('http')) {
      return path;
    }
    return StudentSubjectService.getDocumentUrl(path);
  }
}

class SubjectModel {
  final int subjectId;
  final String subjectName;
  final String displaySubjectName;
  final String? subjectDescription;
  final String? teacherNames;
  final int totalChapters;
  final int completedChapters;
  final double progressPercentage;
  final int? currentChapterId;
  final String? currentChapterName;
  final int totalTimeSpentMinutes;
  final String? lastStudiedDateTime;
  final String lastStudiedDisplay;

  SubjectModel({
    required this.subjectId,
    required this.subjectName,
    required this.displaySubjectName,
    this.subjectDescription,
    this.teacherNames,
    required this.totalChapters,
    required this.completedChapters,
    required this.progressPercentage,
    this.currentChapterId,
    this.currentChapterName,
    required this.totalTimeSpentMinutes,
    this.lastStudiedDateTime,
    required this.lastStudiedDisplay,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      subjectId: json['SubjectID'] ?? 0,
      subjectName: json['SubjectName'] ?? '',
      displaySubjectName: json['Display_Subject_Name'] ?? '',
      subjectDescription: json['SubjectDescription'],
      teacherNames: json['Teacher_Names'],
      totalChapters: json['Total_Chapters'] ?? 0,
      completedChapters: json['Completed_Chapters'] ?? 0,
      progressPercentage: (json['Progress_Percentage'] ?? 0).toDouble(),
      currentChapterId: json['Current_ChapterID'],
      currentChapterName: json['Current_Chapter_Name'],
      totalTimeSpentMinutes: json['Total_Time_Spent_Minutes'] ?? 0,
      lastStudiedDateTime: json['Last_Studied_DateTime'],
      lastStudiedDisplay: json['Last_Studied_Display'] ?? 'Never',
    );
  }
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
