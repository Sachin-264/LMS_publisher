import 'dart:convert';
import 'package:http/http.dart' as http;

class TeacherMaterialService {
  static const String baseUrl = 'http://localhost/AquareLMS/teacher_material.php';

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
          final List<dynamic> chaptersData = decoded['chapters'] ?? [];
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

  // Upload new material
  static Future<Map<String, dynamic>> uploadMaterial({
    required String teacherCode,
    required int chapterId,
    required String materialType,
    required String title,
    String? description,
    String? materialPath,
    String? materialLink,
    String? scheduleReleaseDate,
  }) async {
    print('🟡 [UPLOAD_MATERIAL] Starting API call...');
    print('🟡 TeacherCode: $teacherCode, ChapterID: $chapterId');
    print('🟡 Title: $title, Type: $materialType');

    try {
      final requestBody = {
        "action": "UPLOAD_MATERIAL",
        "TeacherCode": teacherCode,
        "ChapterID": chapterId,
        "MaterialType": materialType,
        "MaterialTitle": title,
        "Description": description,
        "MaterialPath": materialPath,
        "MaterialLink": materialLink,
        "ScheduleReleaseDate": scheduleReleaseDate,
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
      print('✅ [UPLOAD_MATERIAL] Complete');
      return decoded;
    } catch (e) {
      print('❌ [UPLOAD_MATERIAL] Exception: $e');
      rethrow;
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
      print('✅ [DELETE_MATERIAL] Complete');
      return decoded;
    } catch (e) {
      print('❌ [DELETE_MATERIAL] Exception: $e');
      rethrow;
    }
  }
}
