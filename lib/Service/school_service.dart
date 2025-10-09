
// lib/service/school_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lms_publisher/screens/School/school_model.dart'; // Import XFile


class SchoolApiService {
  final String _baseUrl = "http://localhost/AquareLMS/";
  final String _imageUploadUrl = "https://www.aquare.co.in/mobileAPI/sachin/photogcp1.php";

  Future<Map<String, dynamic>> _get(String endpoint) async {
    final stopwatch = Stopwatch()..start();
    print("🚀 Making GET request to endpoint: $endpoint");
    final url = Uri.parse('$_baseUrl$endpoint');
    try {
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});
      print("✅ GET response from $endpoint: ${response.statusCode} in ${stopwatch.elapsedMilliseconds}ms");
      print("📦 GET response body from $endpoint: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = json.decode(response.body);
        if (responseBody['success'] == true) {
          return responseBody;
        } else {
          print("❌ GET request to $endpoint failed with message: ${responseBody['message']}");
          throw Exception(responseBody['message'] ?? 'API request failed');
        }
      } else {
        throw HttpException('Server Error: ${response.statusCode}');
      }
    } on SocketException {
      print("❌ Network error on GET request to $endpoint after ${stopwatch.elapsedMilliseconds}ms");
      throw Exception('Network error: Please check your connection.');
    } catch (e) {
      print("❌ Unexpected error on GET request to $endpoint after ${stopwatch.elapsedMilliseconds}ms: $e");
      throw Exception('An unexpected error occurred: $e');
    } finally {
      stopwatch.stop();
    }
  }

  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> body) async {
    final stopwatch = Stopwatch()..start();
    print("🚀 Making POST request to endpoint: $endpoint with body: ${json.encode(body)}");
    final url = Uri.parse('$_baseUrl$endpoint');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      print("✅ POST response from $endpoint: ${response.statusCode} in ${stopwatch.elapsedMilliseconds}ms");
      print("📦 POST response body from $endpoint: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = json.decode(response.body);
        if (responseBody['success'] == true) {
          return responseBody;
        } else {
          print("❌ POST request to $endpoint failed with message: ${responseBody['message']}");
          throw Exception(responseBody['message'] ?? 'API request failed');
        }
      } else {
        throw HttpException('Server Error: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print("❌ Network error on POST request to $endpoint after ${stopwatch.elapsedMilliseconds}ms");
      throw Exception('Network error: Please check your connection.');
    } catch (e) {
      print("❌ Unexpected error on POST request to $endpoint after ${stopwatch.elapsedMilliseconds}ms: $e");
      throw Exception('An unexpected error occurred: $e');
    } finally {
      stopwatch.stop();
    }
  }


  Future<String?> uploadLogo(XFile imageFile) async {
    print("🚀 [uploadLogo] Starting logo upload for: ${imageFile.path}");
    final stopwatch = Stopwatch()..start();
    try {
      final imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      print("🖼️ [uploadLogo] Image successfully encoded to base64.");

      final payload = {
        'userID': 1,
        'groupCode': 1,
        'imageType': 'LMS',
        'stationImages': [base64Image],
      };

      final url = Uri.parse(_imageUploadUrl);
      print("📤 [uploadLogo] Sending POST request to: $url");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 30));

      stopwatch.stop();
      print("✅ [uploadLogo] Received response. Status: ${response.statusCode} in ${stopwatch.elapsedMilliseconds}ms");
      print("📦 [uploadLogo] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

// --- CHANGED: PARSING LOGIC STARTS HERE ---

// 1. Check for success based on the ACTUAL server response
        final errorObject = responseBody['error'];
        if (errorObject != null && errorObject['code'] == 200) {

// 2. Extract the list of uploaded files
          final stationUploads = responseBody['stationUploads'] as List<dynamic>?;

// 3. Make sure the list exists and is not empty
          if (stationUploads != null && stationUploads.isNotEmpty) {

// 4. Get the filename from the first item in the list
            final String uniqueFileName = stationUploads[0]['UniqueFileName'];

// 5. Construct the full, public URL for the image
            print("✅ [uploadLogo] Success! Filename: $uniqueFileName");
            return uniqueFileName; // Return ONLY the filename

          } else {
// This case handles a 200 OK but no files uploaded, which is an error
            print("❌ [uploadLogo] API indicated success but no image path was returned.");
            throw Exception("Server returned success but no image path was found.");
          }
        } else {
// This handles cases where the server returns 200 but an error message inside
          final errorMessage = errorObject?['message'] ?? 'Unknown API error';
          print("❌ [uploadLogo] API indicated failure: $errorMessage");
          throw Exception("Server returned failure status: $errorMessage");
        }
// --- CHANGED: PARSING LOGIC ENDS HERE ---

      } else {
        print("❌ [uploadLogo] HTTP Error. Status Code: ${response.statusCode}");
        throw HttpException('Server responded with status code ${response.statusCode}');
      }
    } on SocketException catch (e) {
      stopwatch.stop();
      print("❌ [uploadLogo] Network Error after ${stopwatch.elapsedMilliseconds}ms: $e");
      throw Exception('Network Error: Please check your internet connection and CORS policy on the server.');
    } on TimeoutException catch (e) {
      stopwatch.stop();
      print("❌ [uploadLogo] Request timed out after ${stopwatch.elapsedMilliseconds}ms: $e");
      throw Exception('Request timed out. The server took too long to respond.');
    } catch (e) {
      stopwatch.stop();
      print('❌ [uploadLogo] An unexpected error occurred after ${stopwatch.elapsedMilliseconds}ms: $e');
      throw Exception('Failed to upload logo: $e');
    }
  }


// FIXED: This method now correctly accepts an XFile?
  Future<Map<String, dynamic>> addSchool({
    required Map<String, dynamic> schoolMasterData,
    required Map<String, dynamic> subscriptionData,
    XFile? logoFile,
    String? createdBy,
  }) async {
    print("🚀 Calling addSchool for school: ${schoolMasterData['School_Name']}");
    if (logoFile != null) {
      print("🖼️ Logo file provided, starting upload process...");
      final uploadedLogoUrl = await uploadLogo(logoFile);
      schoolMasterData['Logo_Path'] = uploadedLogoUrl;
      print("🔗 Logo URL to be added to school data: $uploadedLogoUrl");
    } else {
      print("ℹ️ No logo file provided for this school.");
      schoolMasterData['Logo_Path'] = null;
    }

    final body = {
      "School_ID": 0,
      "School_Master_Data": schoolMasterData,
      "Subscription_Data": subscriptionData,
      "Created_By": createdBy ?? 'flutter_app',
    };
    print("➡️ Prepared addSchool request body: ${json.encode(body)}");
    return await _post('AddEditSchool.php', body);
  }

  Future<List<FeeStructure>> fetchFeeStructures() async {
    print("🚀 Calling fetchFeeStructures");
    final response = await _get('getFeesSt.php');
    final List<dynamic> data = response['data'] ?? [];
    print("ℹ️ Received ${data.length} fee structure entries. Processing...");

    var uniqueFees = <String, FeeStructure>{};
    for (var item in data) {
      String key = "${item['FeeID']}-${item['FeeName']}";
      if (!uniqueFees.containsKey(key)) {
        uniqueFees[key] = FeeStructure(
          id: item['FeeID'].toString(),
          name: item['FeeName'].toString(),
        );
      }
    }
    print("✅ Fetched and processed ${uniqueFees.length} unique fee structures.");
    return uniqueFees.values.toList();
  }

  Future<String> addFeeStructure({
    String?schoolRecNo, // <--- 1. ADD THIS PARAMETER
    required Map<String, dynamic> feeData
  }) async {
    print("🚀 Calling addFeeStructure for SchoolRecNo: $schoolRecNo with data: ${json.encode(feeData)}");

// 2. USE THE PARAMETER IN THE BODY
    final body = {
      "SchoolRecNo": schoolRecNo,
      ...feeData
    };

    print("➡️ Prepared addFeeStructure request body: ${json.encode(body)}");
    final response = await _post('fee_stucuture_add.php', body);

    if (response['success'] == true && response.containsKey('FeeID')) {
      print("✅ Fee structure added with ID: ${response['FeeID']} for SchoolRecNo: $schoolRecNo");
      return response['FeeID'].toString();
    } else {
      print("❌ Failed to create fee structure. Response: ${json.encode(response)}");
      throw Exception(response['message'] ?? 'Failed to create fee structure');
    }
  }


// In lib/service/school_service.dart

// ... (inside the SchoolApiService class)

  Future<List<dynamic>> fetchFeeStructureDetails(String feeId) async {
    print("🚀 Calling fetchFeeStructureDetails for Fee ID: $feeId");
// Note: This is a GET request as per your documentation.
// We modify the _get method slightly or create a new one if needed.
// For simplicity, let's create a direct http.get call here.
    final url = Uri.parse('$_baseUrl/getFeesSt.php?action=details&FeeID=$feeId');
    try {
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});
      print("✅ GET response from getFeesSt.php details: ${response.statusCode}");
      print("📦 GET response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['success'] == true && responseBody['Details'] is List) {
          return responseBody['Details'];
        } else {
          throw Exception(responseBody['message'] ?? 'Failed to parse fee details');
        }
      } else {
        throw HttpException('Server Error: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Network error: Please check your connection.');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }



  Future<Map<String, dynamic>> login(String email, String password) async {
    print("🚀 Calling login for user: $email");
// Note: Do not log the password in a real application for security reasons.
    final response = await _post('Login.php', {'email': email, 'password': password});
    print("✅ Login successful for user: $email. Response: ${json.encode(response)}");
    return response;
  }

  Future<List<School>> fetchSchools() async {
    print("🚀 Calling fetchSchools");
    final response = await _post('GetSchool.php', {'action': 'list'});
    final List<dynamic> schoolData = response['data'] ?? [];
    print("✅ Fetched ${schoolData.length} schools. Parsing data...");
    final schools = schoolData.map((json) => School.fromListJson(json)).toList();
    print("👍 Successfully parsed ${schools.length} schools.");
    return schools;
  }
  Future<School> fetchSchoolDetails({required String schoolId}) async {
    print("🚀 Calling fetchSchoolDetails for School ID: $schoolId");

// Assuming _post returns the entire decoded JSON object
    final response = await _post('GetSchool.php', {'action': 'detail', 'School_ID': int.parse(schoolId)});

    print("✅ Fetched details for School ID: $schoolId. Parsing data...");

// *** IMPORTANT CHANGE HERE ***
// Pass the 'data' object from the response to the factory constructor.
    final school = School.fromDetailJson(response['data']);

    print("👍 Successfully parsed details for school: ${school.name}");
    return school;
  }

  Future<bool> deleteSchool({required String schoolId}) async {
    print("🚀 Calling deleteSchool for School ID: $schoolId");
    final response = await _post('GetSchool.php', {'action': 'delete', 'School_ID': int.parse(schoolId), 'Deleted_By': 'app_user'});
    print("✅ Delete request for School ID $schoolId returned: ${response['success']}");
    if (!response['success']) {
      print("❌ Delete failed for School ID $schoolId. Reason: ${response['message']}");
    }
    return response['success'];
  }

  Future<bool> renewSubscription({
    required String schoolId,
    required int newSubscriptionId,
    required String newEndDate,
  }) async {
    print("🚀 Calling renewSubscription for School ID: $schoolId");
    print("   - New Subscription ID: $newSubscriptionId");
    print("   - New End Date: $newEndDate");
    final response = await _post('GetSchool.php', {'action': 'renew', 'School_ID': int.parse(schoolId), 'New_Subscription_ID': newSubscriptionId, 'New_End_Date': newEndDate, 'Modified_B': 'app_user'});
    print("✅ Renew subscription for School ID $schoolId returned: ${response['success']}");
    if (!response['success']) {
      print("❌ Subscription renewal failed for School ID $schoolId. Reason: ${response['message']}");
    }
    return response['success'];
  }

  Future<List<SubscriptionPlan>> fetchSubscriptions() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/GetSchool.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'subdetail'}),
      ).timeout(const Duration(seconds: 30));

      print('✅ Fetching subscription plans...');
      print('📡 Request: POST $_baseUrl/GetSchool.php');
      print('📤 Body: {"action": "subdetail"}');
      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'] as List;
          print('✅ Fetched ${data.length} subscription plans. Parsing...');

// Convert each item to SubscriptionPlan using fromJson
          final List<SubscriptionPlan> plans = data.map((item) =>
              SubscriptionPlan.fromJson(item as Map<String, dynamic>)
          ).toList();

          print('👍 Successfully parsed ${plans.length} subscription plans.');

// Debug: Print parsed plans
          for (var plan in plans) {
            print('📋 Plan: ${plan.name} (${plan.planType}) - ${plan.displayPrice}');
          }

          return plans;
        } else {
          throw Exception('Failed to fetch subscription plans: ${jsonResponse['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching subscription plans: $e');
      throw Exception('Failed to fetch subscription plans: $e');
    }
  }

// NEW: Fetches the list of possible school statuses for the filter dropdown
  Future<List<SchoolStatusModel>> fetchSchoolStatuses() async {
    print("🚀 Calling fetchSchoolStatuses");
    final response = await _post('GetSchool.php', {'action': 'statuslist'});
    final List<dynamic> data = response['data'] ?? [];
    print("✅ Fetched ${data.length} statuses. Parsing...");
    final statuses = data
        .map((item) => SchoolStatusModel.fromJson(item as Map<String, dynamic>))
        .toList();
    print("👍 Successfully parsed ${statuses.length} statuses.");
    return statuses;
  }

// NEW: Updates the status for a given school
  Future<bool> updateSchoolStatus(
      {required String schoolId, required String statusId}) async {
    print(
        "🚀 Calling updateSchoolStatus for School ID: $schoolId with Status ID: $statusId");
    final response = await _post('GetSchool.php', {
      'action': 'updatestatus',
      'School_ID': int.parse(schoolId),
      'Status_ID': int.parse(statusId),
    });
    print(
        "✅ Update status request for School ID $schoolId returned: ${response['success']}");
    if (response['success'] == false) {
      print(
          "❌ Status update failed for School ID $schoolId. Reason: ${response['message']}");
    }
    return response['success'] as bool;
  }


  Future<Map<String, dynamic>> updateSchool({
    required String schoolId,
    required Map<String, dynamic> schoolMasterData,
    required Map<String, dynamic> subscriptionData,
    XFile? logoFile,
    String? createdBy,
    String? modifiedBy,
  }) async {
    print("🚀 Calling updateSchool for school ID: $schoolId");
    if (logoFile != null) {
      print("🖼️ New logo file provided, starting upload process...");
      final uploadedLogoUrl = await uploadLogo(logoFile);
      schoolMasterData['Logo_Path'] = uploadedLogoUrl;
      print("🔗 New logo URL to be added to school data: $uploadedLogoUrl");
    } else {
      print("ℹ️ No new logo file provided for this update.");
    }

    final body = {
      // Key difference for updates: School_ID is at the root
      "School_ID": int.tryParse(schoolId) ?? 0,
      "School_Master_Data": schoolMasterData,
      "Subscription_Data": subscriptionData,
      "Created_By": createdBy ?? 'flutter_app',
      "Modified_By": modifiedBy ?? 'flutter_app',
    };

    print("➡️ Prepared updateSchool request body: ${json.encode(body)}");
    // The same endpoint handles both Add and Edit
    return await _post('AddEditSchool.php', body);
  }


  Future<List<StateModel>> fetchStates() async {
    print("🚀 Calling fetchStates");
    final response = await _post('StateMaster.php', {'action': 'getStates'});
    final List<dynamic> data = response['data'] ?? [];
    print("✅ Fetched ${data.length} states. Parsing...");
    final states = data.map((item) => StateModel(id: item['State_ID'], name: item['State_Name'])).toList();
    print("👍 Successfully parsed ${states.length} states.");
    return states;
  }

  Future<List<DistrictModel>> fetchDistricts(String stateId) async {
    print("🚀 Calling fetchDistricts for State ID: $stateId");
    final response = await _post('StateMaster.php', {'action': 'getDistricts', 'State_ID': int.parse(stateId)});
    final List<dynamic> data = response['data'] ?? [];
    print("✅ Fetched ${data.length} districts for State ID: $stateId. Parsing...");
    final districts = data.map((item) => DistrictModel(id: item['District_ID'], name: item['District_Name'])).toList();
    print("👍 Successfully parsed ${districts.length} districts.");
    return districts;
  }

  Future<List<CityModel>> fetchCities(String districtId) async {
    print("🚀 Calling fetchCities for District ID: $districtId");
    final response = await _post('StateMaster.php', {'action': 'getCities', 'District_ID': int.parse(districtId)});
    final List<dynamic> data = response['data'] ?? [];
    print("✅ Fetched ${data.length} cities for District ID: $districtId. Parsing...");
    final cities = data.map((item) => CityModel(id: item['City_ID'], name: item['City_Name'])).toList();
    print("👍 Successfully parsed ${cities.length} cities.");
    return cities;
  }

  Future<List<Map<String, String>>> fetchSchoolTypes() async {
    print("🚀 Calling fetchSchoolTypes");
    final response = await _post('getBoard.php', {'action': 'getSchoolTypes'});
    final List<dynamic> data = response['data'] ?? [];
    print("✅ Fetched ${data.length} school types. Parsing...");
    final types = data.map((item) => {
      'id': item['SchoolType_ID'].toString(),
      'name': item['SchoolType_Name'].toString(),
    }).toList();
    print("👍 Successfully parsed ${types.length} school types.");
    return types;
  }

  Future<List<Map<String, String>>> fetchBoardAffiliations() async {
    print("🚀 Calling fetchBoardAffiliations");
    final response = await _post('getBoard.php', {'action': 'getBoardAffliations'});
    final List<dynamic> data = response['data'] ?? [];
    print("✅ Fetched ${data.length} board affiliations. Parsing...");
    final affiliations = data.map((item) => {
      'id': item['BoardAffliation_ID'].toString(),
      'name': item['BoardAffliation_Name'].toString(),
    }).toList();
    print("👍 Successfully parsed ${affiliations.length} board affiliations.");
    return affiliations;
  }

  Future<List<Map<String, String>>> fetchMediumInstructions() async {
    print("🚀 Calling fetchMediumInstructions");
    final response = await _post('getBoard.php', {'action': 'getMediumInstructions'});
    final List<dynamic> data = response['data'] ?? [];
    print("✅ Fetched ${data.length} medium instructions. Parsing...");
    final mediums = data.map((item) => {
      'id': item['Medium_ID'].toString(),
      'name': item['Medium_Name'].toString(),
    }).toList();
    print("👍 Successfully parsed ${mediums.length} medium instructions.");
    return mediums;
  }

  Future<List<Map<String, String>>> fetchManagementTypes() async {
    print("🚀 Calling fetchManagementTypes");
    final response = await _post('getBoard.php', {'action': 'getManagementTypes'});
    final List<dynamic> data = response['data'] ?? [];
    print("✅ Fetched ${data.length} management types. Parsing...");
    final types = data.map((item) => {
      'id': item['Management_ID'].toString(),
      'name': item['Management_Name'].toString(),
    }).toList();
    print("👍 Successfully parsed ${types.length} management types.");
    return types;
  }
}