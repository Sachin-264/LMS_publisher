import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lms_publisher/Util/AppUrl.dart';

class StudentAssignmentService {
  // Base URL from your other services
  static const String baseUrl = AppUrls.baseUrl;

  /// Calls the SP_SubmitAssignment stored procedure via the API.
  /// This is called *after* the file has been uploaded.
  static Future<Map<String, dynamic>> submitAssignment({
    required String studentCode,
    required int materialRecNo,
    required String submissionType,
    String? submissionFilePath,
    String? submissionText,
    String? submissionLink,
    String? studentComments,
  }) async {
    final url = Uri.parse('$baseUrl/assignment_api.php');

    final body = {
      'action': 'SUBMIT_ASSIGNMENT',
      'StudentCode': studentCode,
      'MaterialRecNo': materialRecNo,
      'SubmissionType': submissionType,
      'SubmissionFilePath': submissionFilePath,
      'SubmissionText': submissionText,
      'SubmissionLink': submissionLink,
      'StudentComments': studentComments,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      print('Submitting Assignment: ${json.encode(body)}');
      print('Submission Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data;
        } else {
          // The API returns a 'message' on failure (e.g., attempt limit)
          throw Exception(data['message'] ?? 'Failed to submit assignment');
        }
      } else {
        final data = json.decode(response.body);
        // Also check for API-level error messages on non-200 status
        throw Exception(data['error'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in submitAssignment: $e');
      throw Exception('Error submitting assignment: $e');
    }
  }
}
