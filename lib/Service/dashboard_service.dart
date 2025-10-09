import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardApiService {
  final String _baseUrl = "http://localhost/AquareLMS/GetPublisher.php";

  Future<Map<String, dynamic>> fetchDashboardData() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['success'] == true) {
          return decodedResponse['data'];
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        // Handle non-200 status codes
        throw Exception('Failed to load dashboard data. StatusCode: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network errors or decoding errors
      throw Exception('Failed to fetch dashboard data: $e');
    }
  }
}