import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lms_publisher/AdminScreen/AdminPublish/publish_model.dart';
import 'package:lms_publisher/Service/user_right_service.dart';



// Helper function to safely parse a value to an integer.
int _parseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? defaultValue;
  }
  return defaultValue;
}

class PublisherApiService {
  final String _baseUrl = "https://aquare.co.in/mobileAPI/sachin/lms/";
  final String _imageUploadUrl = "https://www.aquare.co.in/mobileAPI/sachin/photogcp1.php";
  final String _logoBaseUrl = "https://storage.googleapis.com/upload-images-34/images/LMS/";

  String getLogoUrl(String fileName) {
    if (fileName.isEmpty) return '';
    return '$_logoBaseUrl$fileName';
  }

  Future<Map<String, dynamic>> _postRequest(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    print('---------------------------------------------------');
    print('🚀 [ApiService] Sending POST Request to: $url');
    print('📦 [ApiService] Request Body: ${json.encode(body)}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      print('✅ [ApiService] Received Response | Status: ${response.statusCode}');
      print('📄 [ApiService] Raw Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('👍 [ApiService] Successfully parsed JSON response.');
        print('---------------------------------------------------');
        return responseData;
      } else {
        print('❌ [ApiService] API Error: Status code ${response.statusCode}');
        print('---------------------------------------------------');
        throw Exception('API Error: Status code ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [ApiService] Failed API Request for endpoint $endpoint: $e');
      print('---------------------------------------------------');
      throw Exception('Failed API Request: $e');
    }
  }

  Future<List<UserGroup>> getUserGroups() async {
    try {
      print("🔍 Fetching user groups...");

      final response = await http.post(
        Uri.parse('$_baseUrl/UserRights.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Operation': 'GET_GROUPS'}),
      );

      print("✅ getUserGroups response: ${response.statusCode}");
      print("📦 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List groups = data['data']['resultSet_0'];
          return groups.map((json) => UserGroup.fromJson(json)).toList();
        }
        throw Exception(data['details'] ?? 'Invalid response format');
      }
      throw Exception('Failed to load user groups: ${response.statusCode}');
    } catch (e) {
      print("❌ Error fetching user groups: $e");
      throw Exception('Network error while fetching groups: $e');
    }
  }

  Future<AdminKPIs> getAdminKPIs() async {
    print('[ApiService] Fetching Admin KPIs...');
    final response = await _postRequest("StateMaster.php", {"action": "AdminKPI"});
    if (response['success'] == true && response['data'] != null) {
      print('[ApiService] Admin KPIs data received. Parsing...');
      return AdminKPIs.fromJson(response['data']);
    } else {
      throw Exception('Failed to load KPIs');
    }
  }

  Future<List<Publisher>> getAllPublishers() async {
    print('[ApiService] Fetching all publishers...');
    final response = await _postRequest("AdminPublish.php", {"Operation": "GET_ALL"});
    if (response['success'] == true && response['data']['resultSet_0'] != null) {
      final List<dynamic> data = response['data']['resultSet_0'];
      print('[ApiService] All publishers data received (${data.length} items). Parsing...');
      return data.map((json) => Publisher.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  Future<PublisherDetail> getPublisherDetails(int recNo) async {
    print('[ApiService] Fetching details for publisher RecNo: $recNo...');
    final response = await _postRequest("AdminPublish.php", {"Operation": "GET_DETAIL_BY_ID", "RecNo": recNo});
    if (response['success'] == true && response['data']['resultSet_0'] != null) {
      print('[ApiService] Publisher details data received. Parsing...');
      return PublisherDetail.fromJson(response['data']['resultSet_0'][0]);
    } else {
      throw Exception('Failed to load publisher details');
    }
  }

  Future<Map<String, dynamic>> addPublisher(Map<String, dynamic> data) async {
    print('[ApiService] Adding a new publisher...');
    data['Operation'] = 'INSERT';

    // Ensure required fields are present
    if (data['UserID'] == null || data['UserPassword'] == null || data['UserGroupCode'] == null) {
      throw Exception('UserID, UserPassword, and UserGroupCode are required for publisher creation');
    }

    final response = await _postRequest("AdminPublish.php", data);

    // Return the full response which includes PubCode and RecNo
    if (response['success'] == true && response['data'] != null) {
      return {
        'success': true,
        'pubCode': response['data']['PubCode'],
        'recNo': response['data']['RecNo'],
        'message': response['data']['Message'] ?? 'Publisher created successfully'
      };
    } else {
      throw Exception(response['error'] ?? 'Failed to add publisher');
    }
  }


  Future<bool> updatePublisher(Map<String, dynamic> data) async {
    print('[ApiService] Updating publisher RecNo: ${data["RecNo"]}...');
    data['Operation'] = 'UPDATE';
    final response = await _postRequest("AdminPublish.php", data);

    // Check for error in response
    if (response['success'] == false) {
      throw Exception(response['error'] ?? 'Failed to update publisher');
    }

    return response['success'] ?? false;
  }


  Future<bool> softDeletePublisher(int recNo) async {
    print('[ApiService] Soft deleting publisher RecNo: $recNo...');
    final response = await _postRequest("AdminPublish.php", {"Operation": "SOFT_DELETE", "RecNo": recNo, "ModifiedBy": "Admin"});
    return response['success'];
  }

  Future<bool> hardDeletePublisher(int recNo) async {
    print('[ApiService] Hard deleting publisher RecNo: $recNo...');
    final response = await _postRequest("AdminPublish.php", {"Operation": "HARD_DELETE", "RecNo": recNo, "ModifiedBy": "Admin"});
    return response['success'];
  }

  // --- FIX APPLIED TO THE NEXT 4 METHODS ---

  Future<List<dynamic>> getStates() async {
    print('[ApiService] Fetching states...');
    final response = await _postRequest("StateMaster.php", {"action": "getStates"});
    if (response['success'] == true && response['data'] is List) {
      // Manually parse the ID to an integer before returning
      return (response['data'] as List).map((state) {
        state['State_ID'] = _parseInt(state['State_ID']);
        return state;
      }).toList();
    }
    return [];
  }

  Future<List<dynamic>> getDistricts(int stateId) async {
    print('[ApiService] Fetching districts for State ID: $stateId...');
    final response = await _postRequest("StateMaster.php", {"action": "getDistricts", "State_ID": stateId});
    if (response['success'] == true && response['data'] is List) {
      return (response['data'] as List).map((district) {
        district['District_ID'] = _parseInt(district['District_ID']);
        return district;
      }).toList();
    }
    return [];
  }

  Future<List<dynamic>> getCities(int districtId) async {
    print('[ApiService] Fetching cities for District ID: $districtId...');
    final response = await _postRequest("StateMaster.php", {"action": "getCities", "District_ID": districtId});
    if (response['success'] == true && response['data'] is List) {
      return (response['data'] as List).map((city) {
        city['City_ID'] = _parseInt(city['City_ID']);
        return city;
      }).toList();
    }
    return [];
  }

  // NEW METHOD - Get user credentials for a publisher
  Future<Map<String, dynamic>> getPublisherCredentials(int pubCode) async {
    print('[ApiService] Fetching credentials for PubCode: $pubCode...');
    final response = await _postRequest("AdminPublish.php", {
      "Operation": "GET_CREDENTIALS",
      "PubCode": pubCode
    });

    if (response['success'] == true && response['data']['resultSet_0'] != null) {
      print('[ApiService] Credentials data received.');
      return response['data']['resultSet_0'][0];
    } else {
      throw Exception('Failed to load credentials');
    }
  }

  // NEW METHOD - Update user credentials
  Future<bool> updatePublisherCredentials(int pubCode, String userID, String userPassword, String modifiedBy) async {
    print('[ApiService] Updating credentials for PubCode: $pubCode...');
    final response = await _postRequest("AdminPublish.php", {
      "Operation": "UPDATE_CREDENTIALS",
      "PubCode": pubCode,
      "UserID": userID,
      "UserPassword": userPassword,
      "ModifiedBy": modifiedBy
    });

    return response['success'] ?? false;
  }



  Future<List<dynamic>> getPaymentTerms() async {
    print('[ApiService] Fetching payment terms...');
    final response = await _postRequest("StateMaster.php", {"action": "getPaymentTerms"});
    if (response['success'] == true && response['data'] is List) {
      return (response['data'] as List).map((term) {
        term['PaymentID'] = _parseInt(term['PaymentID']);
        return term;
      }).toList();
    }
    return [];
  }
  Future<bool> activatePublisher(int recNo) async {
    print('[ApiService] Activating publisher RecNo: $recNo...');
    final response = await _postRequest("AdminPublish.php", {
      "Operation": "ACTIVATE",
      "RecNo": recNo,
      "ModifiedBy": "Admin"
    });
    return response['success'];
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

      final response = await http
          .post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      )
          .timeout(const Duration(seconds: 30));

      stopwatch.stop();
      print("✅ [uploadLogo] Received response. Status: ${response.statusCode} in ${stopwatch.elapsedMilliseconds}ms");
      print("📦 [uploadLogo] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final errorObject = responseBody['error'];
        if (errorObject != null && errorObject['code'] == 200) {
          final stationUploads = responseBody['stationUploads'] as List<dynamic>?;
          if (stationUploads != null && stationUploads.isNotEmpty) {
            final String uniqueFileName = stationUploads[0]['UniqueFileName'];
            print("✅ [uploadLogo] Success! Filename: $uniqueFileName");
            return uniqueFileName;
          } else {
            print("❌ [uploadLogo] API indicated success but no image path was returned.");
            throw Exception("Server returned success but no image path was found.");
          }
        } else {
          final errorMessage = errorObject?['message'] ?? 'Unknown API error';
          print("❌ [uploadLogo] API indicated failure: $errorMessage");
          throw Exception("Server returned failure status: $errorMessage");
        }
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
}