import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class StudentAnalyticsDashboardService {
  // API URLs
  static const String baseUrl = 'http://10.100.2.119/AquareLMS';
  static const String logoBaseUrl = "https://storage.googleapis.com/upload-images-34/images/LMS/";

  /// Get complete analytics dashboard data
  static Future<Map<String, dynamic>> getDashboardData({
    required String studentId,
    String timeRange = 'THIS_WEEK', // THIS_WEEK, THIS_MONTH, ALL_TIME
  }) async {
    try {
      print('\n========================================');
      print('📊 FETCHING ANALYTICS DASHBOARD');
      print('========================================');
      print('🆔 Student ID: $studentId');
      print('📅 Time Range: $timeRange');
      print('🌐 API URL: $baseUrl/student_analytics_dashboard_api.php');

      final response = await http.post(
        Uri.parse('$baseUrl/student_analytics_dashboard_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'Student_ID': studentId,
          'TimeRange': timeRange,
        }),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📦 Response Length: ${response.body.length} bytes');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          print('✅ SUCCESS: Dashboard data loaded');

          // Log overview data
          if (data['overview'] != null) {
            print('\n👤 STUDENT OVERVIEW:');
            print('   • Name: ${data['overview']['Student_Name']}');
            print('   • Class: ${data['overview']['Class_Name']}');
            print('   • Section: ${data['overview']['Section_Division']}');
            print('   • School: ${data['overview']['School_Name']}');
            print('   • Overall Progress: ${data['overview']['Overall_Progress']}%');
            print('   • Total Study Hours: ${data['overview']['Total_Study_Hours']}h');
            print('   • Average Score: ${data['overview']['Average_Score']}%');
            print('   • Max Streak: ${data['overview']['Max_Streak']} days');
            print('   • Subjects Enrolled: ${data['overview']['Subjects_Enrolled']}');
            print('   • Completed Chapters: ${data['overview']['Completed_Chapters']}/${data['overview']['Total_Chapters_Started']}');

            // Log school logo path
            if (data['overview']['School_Logo'] != null) {
              final logoPath = data['overview']['School_Logo'];
              final fullLogoUrl = '$logoBaseUrl$logoPath';
              print('   • School Logo: $fullLogoUrl');
              data['overview']['School_Logo_Full_URL'] = fullLogoUrl;
            }

            // Log student photo path
            if (data['overview']['Student_Photo_Path'] != null) {
              print('   • Student Photo: ${data['overview']['Student_Photo_Path']}');
            }
          }

          // Log subjects data
          if (data['subjects'] != null && data['subjects'].length > 0) {
            print('\n📚 SUBJECTS (${data['subjects'].length} total):');
            for (var subject in data['subjects']) {
              print('   • ${subject['SubjectName']}: ${subject['Average_Progress']}% (${subject['Chapters_Completed']}/${subject['Total_Chapters']} chapters)');
            }
          } else {
            print('\n⚠️ WARNING: No subjects data found');
          }

          // Log weekly study data
          if (data['weekly_study'] != null && data['weekly_study'].length > 0) {
            print('\n📅 WEEKLY STUDY DATA (${data['weekly_study'].length} days):');
            for (var day in data['weekly_study']) {
              print('   • ${day['Day_Name']}: ${day['Study_Hours']}h (${day['Chapters_Studied']} chapters)');
            }
          } else {
            print('\n⚠️ WARNING: No weekly study data found');
          }

          // Log activity heatmap
          if (data['activity_heatmap'] != null && data['activity_heatmap'].length > 0) {
            final activeDays = data['activity_heatmap'].where((d) => d['Is_Active'] == true).length;
            print('\n🗓️ ACTIVITY HEATMAP (${data['activity_heatmap'].length} days):');
            print('   • Active Days: $activeDays/${data['activity_heatmap'].length}');
          } else {
            print('\n⚠️ WARNING: No activity heatmap data found');
          }

          // Log achievements
          if (data['achievements'] != null && data['achievements'].length > 0) {
            print('\n🏆 ACHIEVEMENTS (${data['achievements'].length} total):');
            for (var achievement in data['achievements'].take(3)) {
              print('   • ${achievement['Achievement_Icon']} ${achievement['Achievement_Title']} (${achievement['Days_Ago']} days ago)');
            }
          } else {
            print('\n⚠️ WARNING: No achievements data found');
          }

          // Log recent chapters
          if (data['recent_chapters'] != null && data['recent_chapters'].length > 0) {
            print('\n📖 RECENT CHAPTERS (${data['recent_chapters'].length} total):');
            for (var chapter in data['recent_chapters'].take(3)) {
              print('   • ${chapter['ChapterName']}: ${chapter['Progress_Percentage']}% (${chapter['Completion_Status']})');
            }
          } else {
            print('\n⚠️ WARNING: No recent chapters data found');
          }

          print('\n========================================');
          print('✅ DASHBOARD DATA SUCCESSFULLY LOADED');
          print('========================================\n');

          return data;
        } else {
          throw Exception(data['error'] ?? 'Failed to load dashboard data');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('\n========================================');
      print('❌ ERROR LOADING DASHBOARD');
      print('========================================');
      print('Error: $e');
      print('========================================\n');
      rethrow;
    }
  }

  /// Get full logo URL
  static String getLogoUrl(String? logoPath) {
    if (logoPath == null || logoPath.isEmpty) {
      return 'https://via.placeholder.com/200x200/4CAF50/FFFFFF?text=School+Logo';
    }
    return '$logoBaseUrl$logoPath';
  }

  /// Get full student photo URL (if needed)
  static String getStudentPhotoUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) {
      return 'https://via.placeholder.com/200x200/2196F3/FFFFFF?text=Student';
    }
    // Assuming same base URL pattern
    return '$logoBaseUrl$photoPath';
  }
}
