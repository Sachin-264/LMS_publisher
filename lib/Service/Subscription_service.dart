// lib/Service/Subscription_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lms_publisher/Util/AppUrl.dart';
import 'package:lms_publisher/screens/SubscriptionScreen/subscription_model.dart';
import 'package:lms_publisher/Provider/UserProvider.dart';
import 'package:lms_publisher/Service/navigation_service.dart';
import 'package:provider/provider.dart';

class SubscriptionApiService {
  // Singleton instance
  static final SubscriptionApiService _instance = SubscriptionApiService._internal();

  factory SubscriptionApiService() {
    return _instance;
  }

  SubscriptionApiService._internal();

  final String _baseUrl = AppUrls.baseUrl;
  final String _planUrl = "/AddSubPlan.php"; // URL for CUD operations
  final String _fetchUrl = "/GetSchool.php";

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

  // 🔥 Updated: Passes PubCode as query parameter or in body
// Update fetchDashboardData method in Subscription_service.dart

  Future<DashboardData> fetchDashboardData() async {
    try {
      print("🚀 Calling fetchDashboardData with PubCode: $_pubCode");

      // Send as POST with PubCode in body (not GET with query param)
      final body = {
        'PubCode': _pubCode,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/GetSubDash.php'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));

      print("📤 Request body: ${json.encode(body)}");
      print("📥 Response status: ${response.statusCode}");
      print("📥 Response body: ${response.body}");

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
        kpis: KpiData(
          activePlans: '0',
          totalRevenue: '₹0',
          subscribers: '0',
          expiringSoon: '0',
        ),
      );
    }
  }


  // 🔥 Updated: Automatically includes PubCode
  Future<List<Plan>> fetchSubscriptionPlans() async {
    try {
      print("🚀 Calling fetchSubscriptionPlans with PubCode: $_pubCode");

      final body = {
        'action': 'subdetail',
        'PubCode': _pubCode, // Automatically inject PubCode
      };

      final response = await http.post(
        Uri.parse('$_baseUrl$_fetchUrl'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(body),
      );

      print("📥 Response status: ${response.statusCode}");
      print("📥 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List data = jsonResponse['data'];
          return data.map((item) => Plan.fromJson(item)).toList();
        } else {
          throw Exception('API Error: ${jsonResponse['message'] ?? jsonResponse['details']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode} - Body: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching plans: $e');
      rethrow;
    }
  }

  Future<bool> addPlan(Map<String, dynamic> planData, int pubCode) async {
    print("🚀 Adding plan with PubCode: $_pubCode");

    // Add PubCode to the planData explicitly
    final updatedPlanData = {
      ...planData,
      'PubCode': pubCode, // Use the passed value
    };

    print("📤 Adding plan with data: $updatedPlanData");

    final response = await http.post(
      Uri.parse('$_baseUrl$_planUrl'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updatedPlanData),
    );

    print("📥 Response status: ${response.statusCode}");
    print("📥 Response body: ${response.body}");

    if (response.statusCode == 200) {
      final success = json.decode(response.body)['success'] ?? false;
      print("✅ Add plan success: $success");
      return success;
    }

    return false;
  }


  Future<bool> updatePlan(Map<String, dynamic> planUpdateData, int pubCode) async {
    print("🚀 Updating plan with PubCode: $_pubCode");

    // Add PubCode to the planUpdateData explicitly
    final updatedPlanData = {
      ...planUpdateData,
      'PubCode': pubCode, // Use the passed value
    };

    print("📤 Updating plan with data: $updatedPlanData");

    final response = await http.post(
      Uri.parse('$_baseUrl$_planUrl'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updatedPlanData),
    );

    print("📥 Response status: ${response.statusCode}");
    print("📥 Response body: ${response.body}");

    if (response.statusCode == 200) {
      final success = json.decode(response.body)['success'] ?? false;
      print("✅ Update plan success: $success");
      return success;
    }

    return false;
  }

  // DELETE: Remove a plan (PubCode not needed for delete)
  Future<bool> deletePlan({required String recNo, required String deletedBy}) async {
    print("🚀 Deleting plan RecNo: $recNo by $deletedBy");

    final response = await http.delete(
      Uri.parse('$_baseUrl$_planUrl'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'RecNo': recNo,
        'Deleted_By': deletedBy,
      }),
    );

    print("📥 Response status: ${response.statusCode}");
    print("📥 Response body: ${response.body}");

    if (response.statusCode == 200) {
      final success = json.decode(response.body)['success'] ?? false;
      print("✅ Delete plan success: $success");
      return success;
    }

    return false;
  }
}
