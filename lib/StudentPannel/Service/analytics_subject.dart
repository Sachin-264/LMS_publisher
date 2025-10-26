import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalyticsService {
  // API URLs (using same base URL as StudentSubjectService)
  static const String baseUrl = 'http://10.100.2.119/AquareLMS';

  static Future<Map<String, dynamic>> updateChapterProgress({
    required String userCode,
    required int subjectId,
    required int chapterId,
    required String completionStatus, // 'Not Started', 'In Progress', 'Completed'
    required double progressPercentage,
    int timeSpentMinutes = 0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/MySubject.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'UPDATE_PROGRESS',
          'Student_ID': userCode,
          'SubjectID': subjectId,
          'ChapterID': chapterId,
          'Completion_Status': completionStatus,
          'Progress_Percentage': progressPercentage,
          'Time_Spent_Minutes': timeSpentMinutes,
        }),
      );
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Failed to update progress: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error updating progress: $e');
    }
  }

  /**
   * ========================================
   * UPDATE MATERIAL PROGRESS (MODIFIED)
   * ========================================
   * Now includes 'fileSno' to track progress for individual files.
   * Your backend API must be updated to handle the 'File_SNO' parameter.
   */
  static Future<Map<String, dynamic>> updateMaterialProgress({
    required String userCode,
    required int chapterId,
    required String materialType,
    int? fileSno, // FIX: Added fileSno to identify the specific file.
    double? watchProgressPercentage,
    int? lastWatchedPositionSeconds,
    int? totalWatchTimeSeconds,
    bool isCompleted = false,
  }) async {
    try {
      final body = {
        'action': 'UPDATE_MATERIAL',
        'Student_ID': userCode,
        'ChapterID': chapterId,
        'Material_Type': materialType,
        'Is_Completed': isCompleted ? 1 : 0,
      };

      // FIX: Add the file serial number to the request body if available.
      // Your PHP script needs to use this to update the correct row.
      if (fileSno != null) {
        body['File_SNO'] = fileSno;
      }

      if (watchProgressPercentage != null) {
        body['Watch_Progress_Percentage'] = watchProgressPercentage;
      }
      if (lastWatchedPositionSeconds != null) {
        body['Last_Watched_Position_Seconds'] = lastWatchedPositionSeconds;
      }
      if (totalWatchTimeSeconds != null) {
        body['Total_Watch_Time_Seconds'] = totalWatchTimeSeconds;
      }

      // LOGGING: Print the data being sent to the server.
      print('📦 [AnalyticsService] Syncing Material Progress: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/MySubject.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update material progress: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating material progress: $e');
    }
  }

  /**
   * ========================================
   * MANAGE FAVORITES
   * ========================================
   * Add or remove chapter from favorites
   */
  static Future<Map<String, dynamic>> manageFavorite({
    required String userCode,
    required int chapterId,
    required String action, // 'ADD' or 'REMOVE'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/MySubject.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'MANAGE_FAVORITE',
          'Student_ID': userCode,
          'ChapterID': chapterId,
          'FavoriteAction': action,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to manage favorite: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error managing favorite: $e');
    }
  }


  static Future<AnalyticsDashboardResponse> getAnalyticsDashboard({
    required String userCode,
    int? subjectId,
  }) async {
    try {
      final body = {
        'action': 'GET_DASHBOARD',
        'Student_ID': userCode,
      };

      if (subjectId != null) {
        body['SubjectID'] = subjectId as String;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/MySubject.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AnalyticsDashboardResponse.fromJson(data);
      } else {
        throw Exception('Failed to load analytics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching analytics: $e');
    }
  }

  /**
   * ========================================
   * GET CHAPTER DETAILS
   * ========================================
   * Fetch detailed progress for specific chapter
   */
  static Future<ChapterAnalyticsResponse> getChapterDetails({
    required String userCode,
    required int chapterId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/MySubject.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'GET_CHAPTER_DETAILS',
          'Student_ID': userCode,
          'ChapterID': chapterId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ChapterAnalyticsResponse.fromJson(data);
      } else {
        throw Exception('Failed to load chapter details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching chapter details: $e');
    }
  }

  /**
   * ========================================
   * GET FAVORITES LIST
   * ========================================
   * Fetch all favorited chapters
   */
  static Future<FavoritesResponse> getFavorites({
    required String userCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/MySubject.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'GET_FAVORITES',
          'Student_ID': userCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FavoritesResponse.fromJson(data);
      } else {
        throw Exception('Failed to load favorites: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching favorites: $e');
    }
  }
}

// ========================================
// RESPONSE MODELS
// ========================================

class AnalyticsDashboardResponse {
  final String status;
  final String studentId;
  final AnalyticsSummary summary;
  final List<ChapterProgress> chapters;
  final List<MaterialTypeSummary> materialSummary;

  AnalyticsDashboardResponse({
    required this.status,
    required this.studentId,
    required this.summary,
    required this.chapters,
    required this.materialSummary,
  });

  factory AnalyticsDashboardResponse.fromJson(Map<String, dynamic> json) {
    return AnalyticsDashboardResponse(
      status: json['status'] ?? '',
      studentId: json['student_id'] ?? '',
      summary: AnalyticsSummary.fromJson(json['summary'] ?? {}),
      chapters: (json['chapters'] as List?)
          ?.map((item) => ChapterProgress.fromJson(item))
          .toList() ??
          [],
      materialSummary: (json['material_summary'] as List?)
          ?.map((item) => MaterialTypeSummary.fromJson(item))
          .toList() ??
          [],
    );
  }
}

class AnalyticsSummary {
  final int totalChaptersStarted;
  final int completedChapters;
  final double averageProgress;
  final int totalTimeSpentMinutes;
  final String? lastActivityDate;

  AnalyticsSummary({
    required this.totalChaptersStarted,
    required this.completedChapters,
    required this.averageProgress,
    required this.totalTimeSpentMinutes,
    this.lastActivityDate,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      totalChaptersStarted: json['Total_Chapters_Started'] ?? 0,
      completedChapters: json['Completed_Chapters'] ?? 0,
      averageProgress: (json['Average_Progress'] ?? 0).toDouble(),
      totalTimeSpentMinutes: json['Total_Time_Spent_Minutes'] ?? 0,
      lastActivityDate: json['Last_Activity_Date'],
    );
  }
}

class ChapterProgress {
  final int chapterId;
  final String chapterName;
  final String chapterCode;
  final int chapterOrder;
  final int subjectId;
  final String completionStatus;
  final double progressPercentage;
  final int timeSpentMinutes;
  final String? lastAccessedDate;
  final String? firstAccessedDate;
  final String? completedDate;
  final bool isFavorite;

  ChapterProgress({
    required this.chapterId,
    required this.chapterName,
    required this.chapterCode,
    required this.chapterOrder,
    required this.subjectId,
    required this.completionStatus,
    required this.progressPercentage,
    required this.timeSpentMinutes,
    this.lastAccessedDate,
    this.firstAccessedDate,
    this.completedDate,
    required this.isFavorite,
  });

  factory ChapterProgress.fromJson(Map<String, dynamic> json) {
    return ChapterProgress(
      chapterId: json['ChapterID'] ?? 0,
      chapterName: json['ChapterName'] ?? '',
      chapterCode: json['ChapterCode'] ?? '',
      chapterOrder: json['ChapterOrder'] ?? 0,
      subjectId: json['SubjectID'] ?? 0,
      completionStatus: json['Completion_Status'] ?? 'Not Started',
      progressPercentage: (json['Progress_Percentage'] ?? 0).toDouble(),
      timeSpentMinutes: json['Time_Spent_Minutes'] ?? 0,
      lastAccessedDate: json['Last_Accessed_Date'],
      firstAccessedDate: json['First_Accessed_Date'],
      completedDate: json['Completed_Date'],
      isFavorite: json['Is_Favorite'] == 1 || json['Is_Favorite'] == true,
    );
  }
}

class MaterialTypeSummary {
  final String materialType;
  final int totalMaterials;
  final int completedMaterials;
  final double averageProgress;
  final int totalViews;

  MaterialTypeSummary({
    required this.materialType,
    required this.totalMaterials,
    required this.completedMaterials,
    required this.averageProgress,
    required this.totalViews,
  });

  factory MaterialTypeSummary.fromJson(Map<String, dynamic> json) {
    return MaterialTypeSummary(
      materialType: json['Material_Type'] ?? '',
      totalMaterials: json['Total_Materials'] ?? 0,
      completedMaterials: json['Completed_Materials'] ?? 0,
      averageProgress: (json['Average_Progress'] ?? 0).toDouble(),
      totalViews: json['Total_Views'] ?? 0,
    );
  }
}

class ChapterAnalyticsResponse {
  final String status;
  final int chapterId;
  final ChapterProgressDetail chapterProgress;
  final List<MaterialProgress> materialProgress;

  ChapterAnalyticsResponse({
    required this.status,
    required this.chapterId,
    required this.chapterProgress,
    required this.materialProgress,
  });

  factory ChapterAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return ChapterAnalyticsResponse(
      status: json['status'] ?? '',
      chapterId: json['chapter_id'] ?? 0,
      chapterProgress: ChapterProgressDetail.fromJson(json['chapter_progress'] ?? {}),
      materialProgress: (json['material_progress'] as List?)
          ?.map((item) => MaterialProgress.fromJson(item))
          .toList() ??
          [],
    );
  }
}

class ChapterProgressDetail {
  final int chapterId;
  final int subjectId;
  final String completionStatus;
  final double progressPercentage;
  final int timeSpentMinutes;
  final String? lastAccessedDate;
  final String? firstAccessedDate;
  final String? completedDate;
  final bool isFavorite;

  ChapterProgressDetail({
    required this.chapterId,
    required this.subjectId,
    required this.completionStatus,
    required this.progressPercentage,
    required this.timeSpentMinutes,
    this.lastAccessedDate,
    this.firstAccessedDate,
    this.completedDate,
    required this.isFavorite,
  });

  factory ChapterProgressDetail.fromJson(Map<String, dynamic> json) {
    return ChapterProgressDetail(
      chapterId: json['ChapterID'] ?? 0,
      subjectId: json['SubjectID'] ?? 0,
      completionStatus: json['Completion_Status'] ?? 'Not Started',
      progressPercentage: (json['Progress_Percentage'] ?? 0).toDouble(),
      timeSpentMinutes: json['Time_Spent_Minutes'] ?? 0,
      lastAccessedDate: json['Last_Accessed_Date'],
      firstAccessedDate: json['First_Accessed_Date'],
      completedDate: json['Completed_Date'],
      isFavorite: json['Is_Favorite'] == 1 || json['Is_Favorite'] == true,
    );
  }
}

class MaterialProgress {
  final String materialType;
  final double watchProgressPercentage;
  final int lastWatchedPositionSeconds;
  final int totalWatchTimeSeconds;
  final int lastPageViewed;
  final int totalPages;
  final bool isCompleted;
  final int viewCount;
  final String? lastAccessedDate;

  MaterialProgress({
    required this.materialType,
    required this.watchProgressPercentage,
    required this.lastWatchedPositionSeconds,
    required this.totalWatchTimeSeconds,
    required this.lastPageViewed,
    required this.totalPages,
    required this.isCompleted,
    required this.viewCount,
    this.lastAccessedDate,
  });

  factory MaterialProgress.fromJson(Map<String, dynamic> json) {
    return MaterialProgress(
      materialType: json['Material_Type'] ?? '',
      watchProgressPercentage: (json['Watch_Progress_Percentage'] ?? 0).toDouble(),
      lastWatchedPositionSeconds: json['Last_Watched_Position_Seconds'] ?? 0,
      totalWatchTimeSeconds: json['Total_Watch_Time_Seconds'] ?? 0,
      lastPageViewed: json['Last_Page_Viewed'] ?? 0,
      totalPages: json['Total_Pages'] ?? 0,
      isCompleted: json['Is_Completed'] == 1 || json['Is_Completed'] == true,
      viewCount: json['View_Count'] ?? 0,
      lastAccessedDate: json['Last_Accessed_Date'],
    );
  }
}

class FavoritesResponse {
  final String status;
  final String studentId;
  final int favoriteCount;
  final List<FavoriteChapter> favorites;

  FavoritesResponse({
    required this.status,
    required this.studentId,
    required this.favoriteCount,
    required this.favorites,
  });

  factory FavoritesResponse.fromJson(Map<String, dynamic> json) {
    return FavoritesResponse(
      status: json['status'] ?? '',
      studentId: json['student_id'] ?? '',
      favoriteCount: json['favorite_count'] ?? 0,
      favorites: (json['favorites'] as List?)
          ?.map((item) => FavoriteChapter.fromJson(item))
          .toList() ??
          [],
    );
  }
}

class FavoriteChapter {
  final int chapterId;
  final String chapterName;
  final String chapterCode;
  final int chapterOrder;
  final int subjectId;
  final double progressPercentage;
  final String completionStatus;
  final String? lastAccessedDate;
  final String favoritedDate;

  FavoriteChapter({
    required this.chapterId,
    required this.chapterName,
    required this.chapterCode,
    required this.chapterOrder,
    required this.subjectId,
    required this.progressPercentage,
    required this.completionStatus,
    this.lastAccessedDate,
    required this.favoritedDate,
  });

  factory FavoriteChapter.fromJson(Map<String, dynamic> json) {
    return FavoriteChapter(
      chapterId: json['ChapterID'] ?? 0,
      chapterName: json['ChapterName'] ?? '',
      chapterCode: json['ChapterCode'] ?? '',
      chapterOrder: json['ChapterOrder'] ?? 0,
      subjectId: json['SubjectID'] ?? 0,
      progressPercentage: (json['Progress_Percentage'] ?? 0).toDouble(),
      completionStatus: json['Completion_Status'] ?? 'Not Started',
      lastAccessedDate: json['Last_Accessed_Date'],
      favoritedDate: json['Favorited_Date'] ?? '',
    );
  }
}
