import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Service/navigation_service.dart';

class DashboardApiService {
  // Singleton instance
  static final DashboardApiService _instance = DashboardApiService._internal();
  factory DashboardApiService() => _instance;
  DashboardApiService._internal();

  static const String _baseUrl = "http://localhost/AquareLMS";

  // Automatic access to userCode as PubCode (Integer)
  int get _pubCode {
    try {
      final context = NavigationService.context;
      if (context != null) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userCode = userProvider.userCode;
        return userCode != null ? (int.tryParse(userCode) ?? 0) : 0;
      }
    } catch (e) {
      print("⚠️ Warning: Could not access UserProvider. Error: $e");
    }
    return 0;
  }

  /// Fetch Publisher Dashboard Data with PubCode
  Future<Map<String, dynamic>> fetchDashboardData() async {
    try {
      print("🚀 Calling fetchDashboardData with PubCode: $_pubCode");

      // Send PubCode as GET parameter
      final url = Uri.parse('$_baseUrl/GetPublisher.php?PubCode=$_pubCode');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print("📡 Dashboard Response Status: ${response.statusCode}");
      print("📡 Dashboard Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = json.decode(response.body);

        if (decodedResponse['success'] == true) {
          print("✅ Dashboard data loaded successfully");
          return decodedResponse;
        } else {
          final errorMsg = decodedResponse['error'] ?? 'API returned success: false';
          print("❌ Dashboard API Error: $errorMsg");
          throw Exception(errorMsg);
        }
      } else {
        throw Exception('Failed to load dashboard data. StatusCode: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ fetchDashboardData Error: $e");
      throw Exception('Failed to fetch dashboard data: $e');
    }
  }

  /// Alternative: POST method (also works with the PHP API)
  Future<Map<String, dynamic>> fetchDashboardDataPost() async {
    try {
      print("🚀 Calling fetchDashboardData (POST) with PubCode: $_pubCode");

      final response = await http.post(
        Uri.parse('$_baseUrl/GetPublisher.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'PubCode': _pubCode}),
      );

      print("📡 Dashboard Response Status: ${response.statusCode}");
      print("📡 Dashboard Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = json.decode(response.body);

        if (decodedResponse['success'] == true) {
          print("✅ Dashboard data loaded successfully");
          return decodedResponse;
        } else {
          final errorMsg = decodedResponse['error'] ?? 'API returned success: false';
          print("❌ Dashboard API Error: $errorMsg");
          throw Exception(errorMsg);
        }
      } else {
        throw Exception('Failed to load dashboard data. StatusCode: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ fetchDashboardData Error: $e");
      throw Exception('Failed to fetch dashboard data: $e');
    }
  }

  /// Static wrapper for easy access (like ApiService pattern)
  static Future<Map<String, dynamic>> getDashboardData() =>
      _instance.fetchDashboardData();
}
