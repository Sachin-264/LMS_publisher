// lib/Service/academics_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Service/navigation_service.dart';
import 'package:provider/provider.dart';

class ApiService {
  // Singleton instance
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  static const String baseUrl = 'http://localhost/AquareLMS';
  static const String _logoBaseUrl = "http://localhost/AquareCRM/uploadgcp.php";
  static const String _imageBaseUrl = "https://storage.googleapis.com/upload-images-34/images/LMS/";
  static const String _documentBaseUrl = "https://storage.googleapis.com/upload-images-34/documents/LMS/";

  // 🔥 Automatic access to userCode as PubCode (Integer)
  int get _pubCode {
    try {
      final context = NavigationService.context;
      if (context != null) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userCode = userProvider.userCode;
        return userCode != null ? int.tryParse(userCode) ?? 0 : 0;
      }
    } catch (e) {
      print("⚠️ Warning: Could not access UserProvider. Error: $e");
    }
    return 0;
  }

  // ============= STATIC WRAPPERS (Call instance methods) =============

  static Future<Map<String, dynamic>> getAcademicsKPI() => _instance._getAcademicsKPI();
  static Future<Map<String, dynamic>> manageAcademicModule(Map<String, dynamic> body) => _instance._manageAcademicModule(body);
  static Future<String> uploadDocument(XFile file, {BuildContext? context}) => _instance._uploadDocument(file, context: context);
  static String getImageUrl(String filename) => _instance._getImageUrl(filename);
  static String getDocumentUrl(String filename) => _instance._getDocumentUrl(filename);

  // Class methods
  static Future<Map<String, dynamic>> getClasses({int? schoolRecNo, int? classId, String? className, int? isActive}) =>
      _instance._getClasses(schoolRecNo: schoolRecNo, classId: classId, className: className, isActive: isActive);
  static Future<Map<String, dynamic>> addClass(String className, String description, int displayOrder, int schoolRecNo, String createdBy) =>
      _instance._addClass(className, description, displayOrder, schoolRecNo, createdBy);
  static Future<Map<String, dynamic>> updateClass(int classId, String? description, int? displayOrder, String modifiedBy) =>
      _instance._updateClass(classId, description, displayOrder, modifiedBy);

  // Subject methods
  static Future<Map<String, dynamic>> getSubjects({int? schoolRecNo, int? classId, int? subjectId, String? subjectCode, int? isActive}) =>
      _instance._getSubjects(schoolRecNo: schoolRecNo, classId: classId, subjectId: subjectId, subjectCode: subjectCode, isActive: isActive);
  static Future<Map<String, dynamic>> addSubject(int classId, String subjectName, String subjectCode, String description, String createdBy) =>
      _instance._addSubject(classId, subjectName, subjectCode, description, createdBy);
  static Future<Map<String, dynamic>> updateSubject(int subjectId, String? description, int? isActive, String modifiedBy) =>
      _instance._updateSubject(subjectId, description, isActive, modifiedBy);

  // Chapter methods
  static Future<Map<String, dynamic>> getChapters({int? schoolRecNo, int? classId, int? subjectId, int? chapterId, String? chapterCode, int? isActive}) =>
      _instance._getChapters(schoolRecNo: schoolRecNo, classId: classId, subjectId: subjectId, chapterId: chapterId, chapterCode: chapterCode, isActive: isActive);
  static Future<Map<String, dynamic>> addChapter(int subjectId, String chapterName, String chapterCode, String description, int chapterOrder, String createdBy) =>
      _instance._addChapter(subjectId, chapterName, chapterCode, description, chapterOrder, createdBy);
  static Future<Map<String, dynamic>> updateChapter(int chapterId, String? description, int? chapterOrder, int? isActive, String modifiedBy) =>
      _instance._updateChapter(chapterId, description, chapterOrder, isActive, modifiedBy);

  // Material methods
  static Future<Map<String, dynamic>> getMaterials({int? schoolRecNo, int? classId, int? subjectId, int? chapterId, int? recNo, int? materialId}) =>
      _instance._getMaterials(schoolRecNo: schoolRecNo, classId: classId, subjectId: subjectId, chapterId: chapterId, recNo: recNo, materialId: materialId);
  static Future<Map<String, dynamic>> addMaterial({
    required int chapterId,
    int? materialId,
    String? videoLink,
    String? videoFilePath,
    String? worksheetPath,
    String? extraQuestionsPath,
    String? solvedQuestionsPath,
    String? revisionNotesPath,
    String? lessonPlansPath,
    String? teachingAidsPath,
    String? assessmentToolsPath,
    String? homeworkToolsPath,
    String? practiceZonePath,
    String? learningPathPath,
  }) => _instance._addMaterial(
    chapterId: chapterId,
    materialId: materialId,
    videoLink: videoLink,
    videoFilePath: videoFilePath,
    worksheetPath: worksheetPath,
    extraQuestionsPath: extraQuestionsPath,
    solvedQuestionsPath: solvedQuestionsPath,
    revisionNotesPath: revisionNotesPath,
    lessonPlansPath: lessonPlansPath,
    teachingAidsPath: teachingAidsPath,
    assessmentToolsPath: assessmentToolsPath,
    homeworkToolsPath: homeworkToolsPath,
    practiceZonePath: practiceZonePath,
    learningPathPath: learningPathPath,
  );
  static Future<Map<String, dynamic>> updateMaterial({
    required int recNo,
    String? videoLink,
    String? worksheetPath,
    String? extraQuestionsPath,
    String? solvedQuestionsPath,
    String? revisionNotesPath,
    String? lessonPlansPath,
    String? teachingAidsPath,
    String? assessmentToolsPath,
    String? homeworkToolsPath,
    String? practiceZonePath,
    String? learningPathPath,
  }) => _instance._updateMaterial(
    recNo: recNo,
    videoLink: videoLink,
    worksheetPath: worksheetPath,
    extraQuestionsPath: extraQuestionsPath,
    solvedQuestionsPath: solvedQuestionsPath,
    revisionNotesPath: revisionNotesPath,
    lessonPlansPath: lessonPlansPath,
    teachingAidsPath: teachingAidsPath,
    assessmentToolsPath: assessmentToolsPath,
    homeworkToolsPath: homeworkToolsPath,
    practiceZonePath: practiceZonePath,
    learningPathPath: learningPathPath,
  );

  static String? getYoutubeVideoId(String url) => _instance._getYoutubeVideoId(url);
  static String getYoutubeThumbnail(String url) => _instance._getYoutubeThumbnail(url);

  // ============= INSTANCE METHODS (With underscore prefix) =============

  // KPI API
  Future<Map<String, dynamic>> _getAcademicsKPI() async {
    try {
      print("🚀 Calling getAcademicsKPI with PubCode: $_pubCode");

      // Send PubCode as GET parameter in the URL
      final url = Uri.parse('$baseUrl/get_acadKPI.php?PubCode=$_pubCode');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print("📡 getAcademicsKPI Response Status: ${response.statusCode}");
      print("📡 getAcademicsKPI Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Check if the response indicates success
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['error'] ?? 'Failed to load KPI data');
        }
      } else {
        throw Exception('Failed to load KPI data. Status: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ getAcademicsKPI Error: $e");
      throw Exception('Error: $e');
    }
  }


  // 🔥 Generic POST API - Automatically injects PubCode
  Future<Map<String, dynamic>> _manageAcademicModule(Map<String, dynamic> body) async {
    try {
      // Automatically inject PubCode into every request
      final updatedBody = {
        ...body,
        'PubCode': _pubCode,
      };

      print('🛰️ [API] manageAcademicModule → Request Body: ${json.encode(updatedBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/manage_acad_module.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedBody),
      );

      final Map<String, dynamic> responseBody = json.decode(response.body);
      print('🛰️ [API] manageAcademicModule ← Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        return {
          'status': responseBody['status'] ?? 'Error',
          'message': responseBody['message'] ?? 'Failed to perform operation'
        };
      }
    } catch (e) {
      return {
        'status': 'Error',
        'message': 'Error: $e'
      };
    }
  }

  // Helper function to determine MIME type
  static String _getMimeTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  // Upload document function
  Future<String> _uploadDocument(XFile file, {BuildContext? context}) async {
    print("🚀 [uploadDocument] Starting upload for: ${file.path}");
    final stopwatch = Stopwatch()..start();

    try {
      final fileBytes = await file.readAsBytes();
      String base64File = base64Encode(fileBytes);

      String fileName = file.name;
      if (fileName.isEmpty) {
        fileName = file.path.split('/').last;
      }

      final fileExtension = fileName.split('.').last.toLowerCase();
      final isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'].contains(fileExtension);

      String mimeType = _getMimeTypeFromExtension(fileExtension);
      String dataUri = 'data:$mimeType;base64,$base64File';

      final payload = {
        'userID': 1,
        'groupCode': 1,
        'folderName': 'LMS',
        'stationImages': isImage ? [dataUri] : [],
        'documents': !isImage ? [dataUri] : [],
      };

      final url = Uri.parse(_logoBaseUrl);
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 30));

      stopwatch.stop();
      print("✅ [uploadDocument] Status: ${response.statusCode} in ${stopwatch.elapsedMilliseconds}ms");

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final errorObject = responseBody['Status'];

        if (errorObject != null && errorObject['code'] == 200) {
          List uploads = [];
          if (isImage && responseBody['stationUploads'] != null) {
            uploads = responseBody['stationUploads'] as List;
          } else if (!isImage && responseBody['documentUploads'] != null) {
            uploads = responseBody['documentUploads'] as List;
          }

          if (uploads.isNotEmpty) {
            final String uniqueFileName = uploads[0]['UniqueFileName'];
            print("✅ [uploadDocument] Success! Filename: $uniqueFileName");
            return uniqueFileName;
          } else {
            throw Exception("Server returned success but no file path was found.");
          }
        } else {
          final errorMessage = errorObject?['message'] ?? 'Unknown API error';
          throw Exception("Server returned failure status: $errorMessage");
        }
      } else {
        throw HttpException('Server responded with status code ${response.statusCode}');
      }
    } catch (e) {
      stopwatch.stop();
      print('❌ [uploadDocument] Error: $e');
      throw Exception('Failed to upload document: $e');
    }
  }

  String _getImageUrl(String filename) {
    if (filename.isEmpty) return '';
    return '$_imageBaseUrl$filename';
  }

  String _getDocumentUrl(String filename) {
    if (filename.isEmpty) return '';
    return '$_documentBaseUrl$filename';
  }

  // Class Master APIs
  Future<Map<String, dynamic>> _getClasses({int? schoolRecNo, int? classId, String? className, int? isActive}) async {
    Map<String, dynamic> body = {
      'table': 'Class_Master',
      'operation': 'GET',
    };
    if (schoolRecNo != null) body['SchoolRecNo'] = schoolRecNo;
    if (classId != null) body['ClassID'] = classId;
    if (className != null) body['ClassName'] = className;
    if (isActive != null) body['IsActive'] = isActive;
    return _manageAcademicModule(body);
  }

  Future<Map<String, dynamic>> _addClass(String className, String description, int displayOrder, int schoolRecNo, String createdBy) async {
    return _manageAcademicModule({
      'table': 'Class_Master',
      'operation': 'ADD',
      'ClassName': className,
      'ClassDescription': description,
      'DisplayOrder': displayOrder,
      'SchoolRecNo': schoolRecNo,
      'CreatedBy': createdBy,
    });
  }

  Future<Map<String, dynamic>> _updateClass(int classId, String? description, int? displayOrder, String modifiedBy) async {
    Map<String, dynamic> body = {
      'table': 'Class_Master',
      'operation': 'UPDATE',
      'ClassID': classId,
      'ModifiedBy': modifiedBy,
    };
    if (description != null) body['ClassDescription'] = description;
    if (displayOrder != null) body['DisplayOrder'] = displayOrder;
    return _manageAcademicModule(body);
  }

  // Subject Master APIs
  Future<Map<String, dynamic>> _getSubjects({int? schoolRecNo, int? classId, int? subjectId, String? subjectCode, int? isActive}) async {
    Map<String, dynamic> body = {
      'table': 'Subject_Name_Master',
      'operation': 'GET',
    };
    if (schoolRecNo != null) body['SchoolRecNo'] = schoolRecNo;
    if (classId != null) body['ClassID'] = classId;
    if (subjectId != null) body['SubjectID'] = subjectId;
    if (subjectCode != null) body['SubjectCode'] = subjectCode;
    if (isActive != null) body['IsActive'] = isActive;
    return _manageAcademicModule(body);
  }

  Future<Map<String, dynamic>> _addSubject(int classId, String subjectName, String subjectCode, String description, String createdBy) async {
    return _manageAcademicModule({
      'table': 'Subject_Name_Master',
      'operation': 'ADD',
      'ClassID': classId,
      'SubjectName': subjectName,
      'SubjectCode': subjectCode,
      'SubjectDescription': description,
      'CreatedBy': createdBy,
    });
  }

  Future<Map<String, dynamic>> _updateSubject(int subjectId, String? description, int? isActive, String modifiedBy) async {
    Map<String, dynamic> body = {
      'table': 'Subject_Name_Master',
      'operation': 'UPDATE',
      'SubjectID': subjectId,
      'ModifiedBy': modifiedBy,
    };
    if (description != null) body['SubjectDescription'] = description;
    if (isActive != null) body['IsActive'] = isActive;
    return _manageAcademicModule(body);
  }

  // Chapter Master APIs
  Future<Map<String, dynamic>> _getChapters({int? schoolRecNo, int? classId, int? subjectId, int? chapterId, String? chapterCode, int? isActive}) async {
    Map<String, dynamic> body = {
      'table': 'Chapter_Master',
      'operation': 'GET',
    };
    if (schoolRecNo != null) body['SchoolRecNo'] = schoolRecNo;
    if (classId != null) body['ClassID'] = classId;
    if (subjectId != null) body['SubjectID'] = subjectId;
    if (chapterId != null) body['ChapterID'] = chapterId;
    if (chapterCode != null) body['ChapterCode'] = chapterCode;
    if (isActive != null) body['IsActive'] = isActive;
    return _manageAcademicModule(body);
  }

  Future<Map<String, dynamic>> _addChapter(int subjectId, String chapterName, String chapterCode, String description, int chapterOrder, String createdBy) async {
    return _manageAcademicModule({
      'table': 'Chapter_Master',
      'operation': 'ADD',
      'SubjectID': subjectId,
      'ChapterName': chapterName,
      'ChapterCode': chapterCode,
      'ChapterDescription': description,
      'ChapterOrder': chapterOrder,
      'CreatedBy': createdBy,
    });
  }

  Future<Map<String, dynamic>> _updateChapter(int chapterId, String? description, int? chapterOrder, int? isActive, String modifiedBy) async {
    Map<String, dynamic> body = {
      'table': 'Chapter_Master',
      'operation': 'UPDATE',
      'ChapterID': chapterId,
      'ModifiedBy': modifiedBy,
    };
    if (description != null) body['ChapterDescription'] = description;
    if (chapterOrder != null) body['ChapterOrder'] = chapterOrder;
    if (isActive != null) body['IsActive'] = isActive;
    return _manageAcademicModule(body);
  }

  // Study Material APIs
  Future<Map<String, dynamic>> _getMaterials({int? schoolRecNo, int? classId, int? subjectId, int? chapterId, int? recNo, int? materialId}) async {
    Map<String, dynamic> body = {
      'table': 'Study_Material',
      'operation': 'GET',
    };
    if (schoolRecNo != null) body['SchoolRecNo'] = schoolRecNo;
    if (classId != null) body['ClassID'] = classId;
    if (subjectId != null) body['SubjectID'] = subjectId;
    if (chapterId != null) body['Chapter_ID'] = chapterId;
    if (recNo != null) body['RecNo'] = recNo;
    if (materialId != null) body['Material_ID'] = materialId;
    return _manageAcademicModule(body);
  }

  Future<Map<String, dynamic>> _addMaterial({
    required int chapterId,
    int? materialId,
    String? videoLink,
    String? videoFilePath,
    String? worksheetPath,
    String? extraQuestionsPath,
    String? solvedQuestionsPath,
    String? revisionNotesPath,
    String? lessonPlansPath,
    String? teachingAidsPath,
    String? assessmentToolsPath,
    String? homeworkToolsPath,
    String? practiceZonePath,
    String? learningPathPath,
  }) async {
    Map<String, dynamic> body = {
      'table': 'Study_Material',
      'operation': 'ADD',
      'Chapter_ID': chapterId,
    };

    if (materialId != null) body['Material_ID'] = materialId;
    if (videoLink != null && videoLink.isNotEmpty) body['Video_Link'] = videoLink;
    if (videoFilePath != null && videoFilePath.isNotEmpty) {
      body['Video_File_Path'] = videoFilePath;
      body['Is_Video_File'] = true;
    }
    if (worksheetPath != null && worksheetPath.isNotEmpty) body['Worksheet_Path'] = worksheetPath;
    if (extraQuestionsPath != null && extraQuestionsPath.isNotEmpty) body['Extra_Questions_Path'] = extraQuestionsPath;
    if (solvedQuestionsPath != null && solvedQuestionsPath.isNotEmpty) body['Solved_Questions_Path'] = solvedQuestionsPath;
    if (revisionNotesPath != null && revisionNotesPath.isNotEmpty) body['Revision_Notes_Path'] = revisionNotesPath;
    if (lessonPlansPath != null && lessonPlansPath.isNotEmpty) body['Lesson_Plans_Path'] = lessonPlansPath;
    if (teachingAidsPath != null && teachingAidsPath.isNotEmpty) body['Teaching_Aids_Path'] = teachingAidsPath;
    if (assessmentToolsPath != null && assessmentToolsPath.isNotEmpty) body['Assessment_Tools_Path'] = assessmentToolsPath;
    if (homeworkToolsPath != null && homeworkToolsPath.isNotEmpty) body['Homework_Tools_Path'] = homeworkToolsPath;
    if (practiceZonePath != null && practiceZonePath.isNotEmpty) body['Practice_Zone_Path'] = practiceZonePath;
    if (learningPathPath != null && learningPathPath.isNotEmpty) body['Learning_Path_Path'] = learningPathPath;

    return await _manageAcademicModule(body);
  }

  Future<Map<String, dynamic>> _updateMaterial({
    required int recNo,
    String? videoLink,
    String? worksheetPath,
    String? extraQuestionsPath,
    String? solvedQuestionsPath,
    String? revisionNotesPath,
    String? lessonPlansPath,
    String? teachingAidsPath,
    String? assessmentToolsPath,
    String? homeworkToolsPath,
    String? practiceZonePath,
    String? learningPathPath,
  }) async {
    Map<String, dynamic> body = {
      'table': 'Study_Material',
      'operation': 'UPDATE',
      'RecNo': recNo,
    };

    if (videoLink != null) body['Video_Link'] = videoLink;
    if (worksheetPath != null) body['Worksheet_Path'] = worksheetPath;
    if (extraQuestionsPath != null) body['Extra_Questions_Path'] = extraQuestionsPath;
    if (solvedQuestionsPath != null) body['Solved_Questions_Path'] = solvedQuestionsPath;
    if (revisionNotesPath != null) body['Revision_Notes_Path'] = revisionNotesPath;
    if (lessonPlansPath != null) body['Lesson_Plans_Path'] = lessonPlansPath;
    if (teachingAidsPath != null) body['Teaching_Aids_Path'] = teachingAidsPath;
    if (assessmentToolsPath != null) body['Assessment_Tools_Path'] = assessmentToolsPath;
    if (homeworkToolsPath != null) body['Homework_Tools_Path'] = homeworkToolsPath;
    if (practiceZonePath != null) body['Practice_Zone_Path'] = practiceZonePath;
    if (learningPathPath != null) body['Learning_Path_Path'] = learningPathPath;
    return _manageAcademicModule(body);
  }

  String? _getYoutubeVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([^&\s?]+)',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  String _getYoutubeThumbnail(String url) {
    final videoId = _getYoutubeVideoId(url);
    if (videoId != null) {
      return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
    }
    return '';
  }
}
