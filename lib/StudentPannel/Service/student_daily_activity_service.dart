import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:lms_publisher/Util/AppUrl.dart';

class StudentDailyActivityService {
  static const String baseUrl = AppUrls.baseUrl;

  /// Record daily activity (called periodically + on chapter exit)
  static Future<bool> recordDailyActivity({
    required String studentId,
    required int studyMinutes,
    required int chaptersStudied,
    required int materialsViewed,
    required int videosWatched,
    required int documentsRead,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      if (kDebugMode) {
        print('\n========================================');
        print('📊 RECORDING DAILY ACTIVITY');
        print('========================================');
        print('🆔 Student ID: $studentId');
        print('📅 Date: $today');
        print('⏱️ Study Minutes: $studyMinutes');
        print('📚 Chapters Studied: $chaptersStudied');
        print('📄 Materials Viewed: $materialsViewed');
        print('🎥 Videos Watched: $videosWatched');
        print('📝 Documents Read: $documentsRead');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/record_daily_activity_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'Student_ID': studentId,
          'Activity_Date': today,
          'Study_Minutes': studyMinutes,
          'Chapters_Studied': chaptersStudied,
          'Materials_Viewed': materialsViewed,
          'Videos_Watched': videosWatched,
          'Documents_Read': documentsRead,
        }),
      );

      if (kDebugMode) {
        print('📡 Response Status: ${response.statusCode}');
        print('📦 Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          if (kDebugMode) {
            print('✅ SUCCESS: ${data['message']}');
            print('   • Action: ${data['data']['action']}');
            print('   • Total Minutes: ${data['data']['total_study_minutes']}');
            print('   • Activity Score: ${data['data']['activity_score']}');
            print('========================================\n');
          }
          return true;
        } else {
          if (kDebugMode) {
            print('❌ ERROR: ${data['message']}');
            print('========================================\n');
          }
          return false;
        }
      } else {
        if (kDebugMode) {
          print('❌ HTTP ERROR: ${response.statusCode}');
          print('========================================\n');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ EXCEPTION: $e');
        print('========================================\n');
      }
      return false;
    }
  }
}
