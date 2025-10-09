// academics_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:lms_publisher/Theme/apptheme.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1/AquareLMS';
  static const String _logoBaseUrl = "http://127.0.0.1/AquareCRM/uploadgcp.php";
  static const String  _imageBaseUrl = "https://storage.googleapis.com/upload-images-34/images/LMS/";
  static const String  _documentBaseUrl = "https://storage.googleapis.com/upload-images-34/documents/LMS/";

  // KPI API
  static Future<Map<String, dynamic>> getAcademicsKPI() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_acadKPI.php'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load KPI data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Generic POST API for all operations
  static Future<Map<String, dynamic>> manageAcademicModule(Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/manage_acad_module.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      // Try to decode the response body even if statusCode != 200
      final Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseBody; // success or error returned from backend
      } else {
        // If backend sends a friendly error message, pass it along
        return {
          'status': responseBody['status'] ?? 'Error',
          'message': responseBody['message'] ?? 'Failed to perform operation'
        };
      }
    } catch (e) {
      // Catch any other exception (network, parsing, etc.)
      return {
        'status': 'Error',
        'message': 'Error: $e'
      };
    }
  }

  // Add this helper function to determine MIME type
  static String _getMimeTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
    // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';

    // Documents
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
      case 'rtf':
        return 'application/rtf';
      case 'odt':
        return 'application/vnd.oasis.opendocument.text';
      case 'ods':
        return 'application/vnd.oasis.opendocument.spreadsheet';
      case 'odp':
        return 'application/vnd.oasis.opendocument.presentation';

    // Videos
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'wmv':
        return 'video/x-ms-wmv';
      case 'flv':
        return 'video/x-flv';
      case 'mkv':
        return 'video/x-matroska';

    // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      case 'aac':
        return 'audio/aac';
      case 'flac':
        return 'audio/flac';

    // Archives
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case '7z':
        return 'application/x-7z-compressed';
      case 'tar':
        return 'application/x-tar';
      case 'gz':
        return 'application/gzip';

    // Code
      case 'js':
        return 'application/javascript';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'html':
        return 'text/html';
      case 'css':
        return 'text/css';
      case 'py':
        return 'text/x-python';
      case 'java':
        return 'text/x-java-source';
      case 'cpp':
      case 'c':
        return 'text/x-c';

      default:
        return 'application/octet-stream';
    }
  }

  // Now update the uploadDocument function to use this helper
  static Future<String?> uploadDocument(XFile file, {BuildContext? context}) async {
    print("🚀 [uploadDocument] Starting upload for: ${file.path}");
    final stopwatch = Stopwatch()..start();
    try {
      final fileBytes = await file.readAsBytes();
      String base64File = base64Encode(fileBytes);
      print("📄 [uploadDocument] File successfully encoded to base64. Base64 size: ${base64File.length} bytes.");

      // Determine file type from extension
      String fileName = file.name;
      if (fileName.isEmpty) {
        // Extract filename from path if name is empty
        fileName = file.path.split('/').last;
      }

      final fileExtension = fileName.split('.').last.toLowerCase();
      final isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'].contains(fileExtension);

      // Use our helper function to determine MIME type
      String mimeType = _getMimeTypeFromExtension(fileExtension);

      // If we still can't determine the MIME type and we have a context, ask the user
      if (mimeType == 'application/octet-stream' && context != null) {
        final String? userSelectedType = await _showFileTypeSelectionDialog(context, fileName);
        if (userSelectedType != null) {
          mimeType = userSelectedType;
        }
      }

      // Create the base64 data URI with proper MIME type
      String dataUri = 'data:$mimeType;base64,$base64File';

      final payload = {
        'userID': 1, // Placeholder
        'groupCode': 1, // Placeholder
        'folderName': 'LMS',
        'stationImages': isImage ? [dataUri] : [],
        'documents': !isImage ? [dataUri] : [],
      };

      final url = Uri.parse(_logoBaseUrl);
      print("📤 [uploadDocument] Sending POST request to: $url");
      print("🔍 [uploadDocument] Request details: isImage=$isImage, MIME Type=$mimeType.");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 30));

      stopwatch.stop();
      print("✅ [uploadDocument] Received response. Status: ${response.statusCode} in ${stopwatch.elapsedMilliseconds}ms");
      print("📦 [uploadDocument] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        // Check for success based on the ACTUAL server response
        final errorObject = responseBody['Status'];
        if (errorObject != null && errorObject['code'] == 200) {
          // Extract the list of uploaded files based on type
          List<dynamic> uploads = [];

          if (isImage && responseBody['stationUploads'] != null) {
            uploads = responseBody['stationUploads'] as List<dynamic>;
          } else if (!isImage && responseBody['documentUploads'] != null) {
            uploads = responseBody['documentUploads'] as List<dynamic>;
          }

          // Make sure the list exists and is not empty
          if (uploads.isNotEmpty) {
            // Get the filename from the first item in the list
            final String uniqueFileName = uploads[0]['UniqueFileName'];

            // Return ONLY the filename (not the full URL)
            print("✅ [uploadDocument] Success! Filename: $uniqueFileName");
            return uniqueFileName;
          } else {
            print("❌ [uploadDocument] API indicated success but no file path was returned.");
            throw Exception("Server returned success but no file path was found.");
          }
        } else {
          final errorMessage = errorObject?['message'] ?? 'Unknown API error';
          print("❌ [uploadDocument] API indicated failure: $errorMessage");
          throw Exception("Server returned failure status: $errorMessage");
        }
      } else {
        print("❌ [uploadDocument] HTTP Error. Status Code: ${response.statusCode}");
        throw HttpException('Server responded with status code ${response.statusCode}');
      }
    } on SocketException catch (e) {
      stopwatch.stop();
      print("❌ [uploadDocument] Network Error after ${stopwatch.elapsedMilliseconds}ms: $e");
      throw Exception('Network Error: Please check your internet connection and CORS policy on the server.');
    } on TimeoutException catch (e) {
      stopwatch.stop();
      print("❌ [uploadDocument] Request timed out after ${stopwatch.elapsedMilliseconds}ms: $e");
      throw Exception('Request timed out. The server took too long to respond.');
    } catch (e) {
      stopwatch.stop();
      print('❌ [uploadDocument] An unexpected error occurred after ${stopwatch.elapsedMilliseconds}ms: $e');
      throw Exception('Failed to upload document: $e');
    }
  }
// academics_service.dart - _showFileTypeSelectionDialog function

  // Add this helper function to show a dialog for file type selection
  static Future<String?> _showFileTypeSelectionDialog(BuildContext context, String fileName) async {
    String? selectedType;

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Iconsax.warning_2, color: Colors.orange, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select File Type',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Could not determine the type of file:',
                    style: GoogleFonts.inter(color: AppTheme.bodyText),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      fileName,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppTheme.darkText),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Please select the file type:',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppTheme.darkText),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderGrey.withOpacity(0.3)),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text('Select file type', style: GoogleFonts.inter(color: AppTheme.bodyText)),
                      value: selectedType,
                      underline: SizedBox(),
                      items: [
                        DropdownMenuItem(value: 'application/pdf', child: Row(children: [Icon(Icons.picture_as_pdf, color: Colors.red, size: 20), SizedBox(width: 8), Text('PDF Document')])),
                        DropdownMenuItem(value: 'application/msword', child: Row(children: [Icon(Icons.description, color: Colors.blue, size: 20), SizedBox(width: 8), Text('Word Document (.doc)')])),
                        DropdownMenuItem(value: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', child: Row(children: [Icon(Icons.description, color: Colors.blue, size: 20), SizedBox(width: 8), Text('Word Document (.docx)')])),
                        DropdownMenuItem(value: 'application/vnd.ms-excel', child: Row(children: [Icon(Icons.table_chart, color: Colors.green, size: 20), SizedBox(width: 8), Text('Excel Spreadsheet (.xls)')])),
                        DropdownMenuItem(value: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', child: Row(children: [Icon(Icons.table_chart, color: Colors.green, size: 20), SizedBox(width: 8), Text('Excel Spreadsheet (.xlsx)')])),
                        DropdownMenuItem(value: 'application/vnd.ms-powerpoint', child: Row(children: [Icon(Icons.slideshow, color: Colors.orange, size: 20), SizedBox(width: 8), Text('PowerPoint Presentation (.ppt)')])),
                        DropdownMenuItem(value: 'application/vnd.openxmlformats-officedocument.presentationml.presentation', child: Row(children: [Icon(Icons.slideshow, color: Colors.orange, size: 20), SizedBox(width: 8), Text('PowerPoint Presentation (.pptx)')])),
                        DropdownMenuItem(value: 'text/plain', child: Row(children: [Icon(Icons.text_snippet, color: Colors.grey, size: 20), SizedBox(width: 8), Text('Plain Text (.txt)')])),
                        DropdownMenuItem(value: 'video/mp4', child: Row(children: [Icon(Icons.videocam, color: Colors.red, size: 20), SizedBox(width: 8), Text('Video File (.mp4)')])),
                        DropdownMenuItem(value: 'video/webm', child: Row(children: [Icon(Icons.videocam, color: Colors.red, size: 20), SizedBox(width: 8), Text('Video File (.webm)')])),
                        DropdownMenuItem(value: 'video/quicktime', child: Row(children: [Icon(Icons.videocam, color: Colors.red, size: 20), SizedBox(width: 8), Text('Video File (.mov)')])),
                        DropdownMenuItem(value: 'application/zip', child: Row(children: [Icon(Icons.folder_zip, color: Colors.purple, size: 20), SizedBox(width: 8), Text('Archive File (.zip)')])),
                        DropdownMenuItem(value: 'application/octet-stream', child: Row(children: [Icon(Icons.insert_drive_file, color: Colors.grey, size: 20), SizedBox(width: 8), Text('Other')])),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          selectedType = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                ),
                ElevatedButton(
                  onPressed: selectedType != null ? () => Navigator.pop(context, selectedType) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Confirm', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Get the full URL for an image
  static String getImageUrl(String filename) {
    if (filename.isEmpty) return '';
    return '$_imageBaseUrl$filename';
  }

  /// Get the full URL for a document
  static String getDocumentUrl(String filename) {
    if (filename.isEmpty) return '';
    return '$_documentBaseUrl$filename';
  }

  // Class Master APIs
  static Future<Map<String, dynamic>> getClasses({int? schoolRecNo, int? classId, String? className, int? isActive}) async {
    Map<String, dynamic> body = {
      'table': 'Class_Master',
      'operation': 'GET',
    };
    if (schoolRecNo != null) body['SchoolRecNo'] = schoolRecNo;
    if (classId != null) body['ClassID'] = classId;
    if (className != null) body['ClassName'] = className;
    if (isActive != null) body['IsActive'] = isActive;

    return manageAcademicModule(body);
  }

  static Future<Map<String, dynamic>> addClass(String className, String description, int displayOrder, int schoolRecNo, String createdBy) async {
    return manageAcademicModule({
      'table': 'Class_Master',
      'operation': 'ADD',
      'ClassName': className,
      'ClassDescription': description,
      'DisplayOrder': displayOrder,
      'SchoolRecNo': schoolRecNo,
      'CreatedBy': createdBy,
    });
  }

  static Future<Map<String, dynamic>> updateClass(int classId, String? description, int? displayOrder, String modifiedBy) async {
    Map<String, dynamic> body = {
      'table': 'Class_Master',
      'operation': 'UPDATE',
      'ClassID': classId,
      'ModifiedBy': modifiedBy,
    };
    if (description != null) body['ClassDescription'] = description;
    if (displayOrder != null) body['DisplayOrder'] = displayOrder;

    return manageAcademicModule(body);
  }

  // Subject Master APIs
  static Future<Map<String, dynamic>> getSubjects({int? schoolRecNo, int? classId, int? subjectId, String? subjectCode, int? isActive}) async {
    Map<String, dynamic> body = {
      'table': 'Subject_Name_Master',
      'operation': 'GET',
    };
    if (schoolRecNo != null) body['SchoolRecNo'] = schoolRecNo;
    if (classId != null) body['ClassID'] = classId;
    if (subjectId != null) body['SubjectID'] = subjectId;
    if (subjectCode != null) body['SubjectCode'] = subjectCode;
    if (isActive != null) body['IsActive'] = isActive;

    return manageAcademicModule(body);
  }

  static Future<Map<String, dynamic>> addSubject(int classId, String subjectName, String subjectCode, String description, String createdBy) async {
    return manageAcademicModule({
      'table': 'Subject_Name_Master',
      'operation': 'ADD',
      'ClassID': classId,
      'SubjectName': subjectName,
      'SubjectCode': subjectCode,
      'SubjectDescription': description,
      'CreatedBy': createdBy,
    });
  }

  static Future<Map<String, dynamic>> updateSubject(int subjectId, String? description, int? isActive, String modifiedBy) async {
    Map<String, dynamic> body = {
      'table': 'Subject_Name_Master',
      'operation': 'UPDATE',
      'SubjectID': subjectId,
      'ModifiedBy': modifiedBy,
    };
    if (description != null) body['SubjectDescription'] = description;
    if (isActive != null) body['IsActive'] = isActive;

    return manageAcademicModule(body);
  }

  // Chapter Master APIs
  static Future<Map<String, dynamic>> getChapters({int? schoolRecNo, int? classId, int? subjectId, int? chapterId, String? chapterCode, int? isActive}) async {
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

    return manageAcademicModule(body);
  }

  static Future<Map<String, dynamic>> addChapter(int subjectId, String chapterName, String chapterCode, String description, int chapterOrder, String createdBy) async {
    return manageAcademicModule({
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

  static Future<Map<String, dynamic>> updateChapter(int chapterId, String? description, int? chapterOrder, int? isActive, String modifiedBy) async {
    Map<String, dynamic> body = {
      'table': 'Chapter_Master',
      'operation': 'UPDATE',
      'ChapterID': chapterId,
      'ModifiedBy': modifiedBy,
    };
    if (description != null) body['ChapterDescription'] = description;
    if (chapterOrder != null) body['ChapterOrder'] = chapterOrder;
    if (isActive != null) body['IsActive'] = isActive;

    return manageAcademicModule(body);
  }

  // Study Material APIs
  static Future<Map<String, dynamic>> getMaterials({int? schoolRecNo, int? classId, int? subjectId, int? chapterId, int? recNo, int? materialId}) async {
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

    return manageAcademicModule(body);
  }

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
  }) async {
    print('🔍 [addMaterial] Starting material addition process');
    print('   ChapterID: $chapterId');
    print('   MaterialID: $materialId');

    Map<String, dynamic> body = {
      'table': 'Study_Material',
      'operation': 'ADD',
      'Chapter_ID': chapterId,
    };

    if (materialId != null) body['Material_ID'] = materialId;

    // Corrected field names for video
    if (videoLink != null && videoLink.isNotEmpty) {
      body['Video_Link'] = videoLink;
      print('   Adding Video_Link: $videoLink');
    }

    if (videoFilePath != null && videoFilePath.isNotEmpty) {
      body['Video_File_Path'] = videoFilePath;
      body['Is_Video_File'] = true;
      print('   Adding Video_File_Path: $videoFilePath');
    }

    if (worksheetPath != null && worksheetPath.isNotEmpty) {
      body['Worksheet_Path'] = worksheetPath;
      print('   Adding Worksheet_Path: $worksheetPath');
    }
    if (extraQuestionsPath != null && extraQuestionsPath.isNotEmpty) {
      body['Extra_Questions_Path'] = extraQuestionsPath;
      print('   Adding Extra_Questions_Path: $extraQuestionsPath');
    }
    if (solvedQuestionsPath != null && solvedQuestionsPath.isNotEmpty) {
      body['Solved_Questions_Path'] = solvedQuestionsPath;
      print('   Adding Solved_Questions_Path: $solvedQuestionsPath');
    }
    if (revisionNotesPath != null && revisionNotesPath.isNotEmpty) {
      body['Revision_Notes_Path'] = revisionNotesPath;
      print('   Adding Revision_Notes_Path: $revisionNotesPath');
    }
    if (lessonPlansPath != null && lessonPlansPath.isNotEmpty) {
      body['Lesson_Plans_Path'] = lessonPlansPath;
      print('   Adding Lesson_Plans_Path: $lessonPlansPath');
    }
    if (teachingAidsPath != null && teachingAidsPath.isNotEmpty) {
      body['Teaching_Aids_Path'] = teachingAidsPath;
      print('   Adding Teaching_Aids_Path: $teachingAidsPath');
    }
    if (assessmentToolsPath != null && assessmentToolsPath.isNotEmpty) {
      body['Assessment_Tools_Path'] = assessmentToolsPath;
      print('   Adding Assessment_Tools_Path: $assessmentToolsPath');
    }
    if (homeworkToolsPath != null && homeworkToolsPath.isNotEmpty) {
      body['Homework_Tools_Path'] = homeworkToolsPath;
      print('   Adding Homework_Tools_Path: $homeworkToolsPath');
    }
    if (practiceZonePath != null && practiceZonePath.isNotEmpty) {
      body['Practice_Zone_Path'] = practiceZonePath;
      print('   Adding Practice_Zone_Path: $practiceZonePath');
    }
    if (learningPathPath != null && learningPathPath.isNotEmpty) {
      body['Learning_Path_Path'] = learningPathPath;
      print('   Adding Learning_Path_Path: $learningPathPath');
    }

    print('📤 [addMaterial] Sending request with body: $body');

    return await manageAcademicModule(body);
  }

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

    return manageAcademicModule(body);
  }

  // Helper method to extract YouTube video ID
  static String? getYoutubeVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([^&\s?]+)',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  // Generate YouTube thumbnail URL
  static String getYoutubeThumbnail(String url) {
    final videoId = getYoutubeVideoId(url);
    if (videoId != null) {
      return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
    }
    return '';
  }
}