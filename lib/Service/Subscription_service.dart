import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lms_publisher/screens/SubscriptionScreen/subscription_model.dart';

class SubscriptionApiService {
  final String _baseUrl = "http://localhost/AquareLMS";
  final String _planUrl = "/AddSubPlan.php"; // URL for CUD operations
  final String _fetchUrl = "/GetSchool.php";

  Future<DashboardData> fetchDashboardData() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/GetSubDash.php'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return DashboardData.fromJson(jsonResponse);
        } else {
          throw Exception('API returned an error: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching dashboard data: $e');
      return DashboardData(
        monthlyRevenue: [],
        planPopularity: [],
        recentActivities: [],
        kpis: KpiData(activePlans: '0', totalRevenue: '₹0', subscribers: '0', expiringSoon: '0'),
      );
    }
  }
  Future<List<Plan>> fetchSubscriptionPlans() async {
    try {
      // FIX: Add headers and the correct JSON body to the POST request.
      final response = await http.post(
        Uri.parse('$_baseUrl$_fetchUrl'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({'action': 'subdetail'}), // Send the required action
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((item) => Plan.fromJson(item)).toList();
        } else {
          // It's helpful to include the API's error message for debugging.
          throw Exception('API Error: ${jsonResponse['message'] ?? jsonResponse['details']}');
        }
      } else {
        // Also helpful to print the response body for non-200 status codes.
        throw Exception('HTTP Error: ${response.statusCode} - Body: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching plans: $e');
      rethrow; // Rethrow to be caught by FutureBuilder
    }
  }

  Future<bool> addPlan(Map<String, dynamic> planData) async {
    print("Adding plan with data: $planData"); // Print the data being sent

    final response = await http.post(
      Uri.parse('$_baseUrl$_planUrl'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(planData),
    );

    print("Response status: ${response.statusCode}"); // Print the HTTP status
    print("Response body: ${response.body}");         // Print the response body

    if (response.statusCode == 200) {
      final success = json.decode(response.body)['success'] ?? false;
      print("Add plan success: $success"); // Print the decoded success value
      return success;
    }

    return false;
  }

// UPDATE: Edit an existing plan
  Future<bool> updatePlan(Map<String, dynamic> planUpdateData) async {
    print("Updating plan with data: $planUpdateData"); // Print the data being sent

    final response = await http.post(
      Uri.parse('$_baseUrl$_planUrl'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(planUpdateData),
    );

    print("Response status: ${response.statusCode}"); // Print the HTTP status
    print("Response body: ${response.body}");         // Print the response body

    if (response.statusCode == 200) {
      final success = json.decode(response.body)['success'] ?? false;
      print("Update plan success: $success"); // Print the decoded success value
      return success;
    }

    return false;
  }


  // DELETE: Remove a plan
  Future<bool> deletePlan({required String recNo, required String deletedBy}) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$_planUrl'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'RecNo': recNo, 'Deleted_By': deletedBy}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['success'] ?? false;
    }
    return false;
  }
}
