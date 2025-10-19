import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lms_publisher/School_Panel/teacher_module/teacher_model.dart';

// ✅ Location Models
class StateModel {
  final String id;
  final String name;
  StateModel({required this.id, required this.name});
}

class DistrictModel {
  final String id;
  final String name;
  DistrictModel({required this.id, required this.name});
}

class CityModel {
  final String id;
  final String name;
  CityModel({required this.id, required this.name});
}


class TeacherApiService {
  static const String baseUrl =  'http://localhost/AquareLMS';
  static const int defaultSchoolRecNo = 1;

  static const String _imageUploadUrl = "https://www.aquare.co.in/mobileAPI/sachin/photogcp1.php";
  static const String _imageBaseUrl = "https://storage.googleapis.com/upload-images-34/images/LMS/";



  // ✅ Helper method for POST requests
  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == 'success') {
        return jsonResponse;
      } else {
        throw Exception(jsonResponse['error'] ?? 'Request failed');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }
// ✅ FIXED: Fetch States
  Future<List<StateModel>> fetchStates() async {
    print("🚀 Calling fetchStates");
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/StateMaster.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'getStates'}),
      );

      print("📡 Response Status: ${response.statusCode}");
      print("📡 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // ✅ FIX: Check for 'success' instead of 'status'
        if (jsonResponse['success'] == true) {
          final List data = jsonResponse['data'] ?? [];
          print("✅ Fetched ${data.length} states. Parsing...");

          final states = data.map((item) => StateModel(
              id: item['State_ID'].toString(),
              name: item['State_Name']
          )).toList();

          print("👍 Successfully parsed ${states.length} states.");
          return states;
        } else {
          throw Exception(jsonResponse['error'] ?? 'Failed to fetch states');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Error in fetchStates: $e");
      throw Exception('Request failed: $e');
    }
  }

// ✅ FIXED: Fetch Districts by State
  Future<List<DistrictModel>> fetchDistricts(String stateId) async {
    print("🚀 Calling fetchDistricts for State ID: $stateId");
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/StateMaster.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'getDistricts',
          'State_ID': int.parse(stateId)
        }),
      );

      print("📡 Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // ✅ FIX: Check for 'success' instead of 'status'
        if (jsonResponse['success'] == true) {
          final List data = jsonResponse['data'] ?? [];
          print("✅ Fetched ${data.length} districts for State ID: $stateId");

          final districts = data.map((item) => DistrictModel(
              id: item['District_ID'].toString(),
              name: item['District_Name']
          )).toList();

          print("👍 Successfully parsed ${districts.length} districts.");
          return districts;
        } else {
          throw Exception(jsonResponse['error'] ?? 'Failed to fetch districts');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Error in fetchDistricts: $e");
      throw Exception('Request failed: $e');
    }
  }

// ✅ FIXED: Fetch Cities by District
  Future<List<CityModel>> fetchCities(String districtId) async {
    print("🚀 Calling fetchCities for District ID: $districtId");
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/StateMaster.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'getCities',
          'District_ID': int.parse(districtId)
        }),
      );

      print("📡 Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // ✅ FIX: Check for 'success' instead of 'status'
        if (jsonResponse['success'] == true) {
          final List data = jsonResponse['data'] ?? [];
          print("✅ Fetched ${data.length} cities for District ID: $districtId");

          final cities = data.map((item) => CityModel(
              id: item['City_ID'].toString(),
              name: item['City_Name']
          )).toList();

          print("👍 Successfully parsed ${cities.length} cities.");
          return cities;
        } else {
          throw Exception(jsonResponse['error'] ?? 'Failed to fetch cities');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Error in fetchCities: $e");
      throw Exception('Request failed: $e');
    }
  }




  // ✅ NEW: Hash Password using API
  Future<Map<String, dynamic>> hashPassword(String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hash_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': password}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse;
        } else {
          throw Exception(jsonResponse['error'] ?? 'Failed to hash password');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error hashing password: $e');
    }
  }

  // ✅ Insert User for Teacher Login (with hashed password from API)
  Future<Map<String, dynamic>> insertUser({
    required String userName,
    required int userGroupCode,
    required String userID,
    required String hashedPassword,
    required String salt,
    int isBlocked = 0,
    String addUser = 'Admin',
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'action': 'INSERT_USER',
        'UserName': userName,
        'UserGroupCode': userGroupCode,
        'UserID': userID,
        'UserPassword': hashedPassword,
        'Salt': salt,
        'EncryptPassword': null,
        'IsBlocked': isBlocked,
        'AddUser': addUser,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/manage_teacher.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          return jsonResponse;
        } else {
          throw Exception(jsonResponse['error'] ?? 'Failed to insert user');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error inserting user: $e');
    }
  }

  // Fetch all teachers
  Future<List<TeacherModel>> fetchTeachers({
    int? schoolRecNo,
    bool? isActive,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'action': 'GET_LIST',
        'SchoolRecNo': schoolRecNo ?? defaultSchoolRecNo,
        if (isActive != null) 'IsActive': isActive ? 1 : 0,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/manage_teacher.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => TeacherModel.fromJson(json)).toList();
        } else {
          throw Exception(jsonResponse['error'] ?? 'Failed to fetch teachers');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching teachers: $e');
    }
  }

  // Fetch single teacher details
  Future<TeacherModel> fetchTeacherDetails({required int recNo}) async {
    try {
      final Map<String, dynamic> requestBody = {
        'action': 'GET_DETAILS',
        'RecNo': recNo,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/manage_teacher.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          if (data.isNotEmpty) {
            return TeacherModel.fromJson(data.first);
          } else {
            throw Exception('No teacher found with RecNo: $recNo');
          }
        } else {
          throw Exception(jsonResponse['error'] ?? 'Failed to fetch teacher details');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching teacher details: $e');
    }
  }

  // Add new teacher
  Future<Map<String, dynamic>> addTeacher({
    required Map<String, dynamic> teacherData,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'action': 'INSERT',
        ...teacherData,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/manage_teacher.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data'];
        } else {
          throw Exception(jsonResponse['error'] ?? 'Failed to add teacher');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding teacher: $e');
    }
  }

  // Update existing teacher
  Future<Map<String, dynamic>> updateTeacher({
    required int recNo,
    required Map<String, dynamic> teacherData,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'action': 'UPDATE',
        'RecNo': recNo,
        ...teacherData,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/manage_teacher.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data'];
        } else {
          throw Exception(jsonResponse['error'] ?? 'Failed to update teacher');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating teacher: $e');
    }
  }

  // ✅ Delete single teacher (Check Status field)
  Future<void> deleteTeacher({
    required int recNo,
    required String operationBy,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'action': 'DELETE',
        'RecNo': recNo,
        'ModifiedBy': operationBy,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/manage_teacher.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // ✅ Check if response has data with Status field
        if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];

          // ✅ If Status is ERROR, throw exception with message
          if (data is List && data.isNotEmpty && data.first['Status'] == 'ERROR') {
            throw Exception(data.first['Message']);
          } else if (data is Map && data['Status'] == 'ERROR') {
            throw Exception(data['Message']);
          }
        } else if (jsonResponse['status'] != 'success') {
          throw Exception(jsonResponse['details'] ?? jsonResponse['error'] ?? 'Failed to delete teacher');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ✅ Delete multiple teachers (Check Status field)
  Future<Map<String, dynamic>> deleteTeachersBulk({
    required List<int> recNoList,
    required String operationBy,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'action': 'DELETE_MULTIPLE',
        'RecNos': recNoList.join(','),
        'ModifiedBy': operationBy,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/manage_teacher.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // ✅ Check if response has data with Status field
        if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];

          // ✅ If Status is ERROR, throw exception with message
          if (data is List && data.isNotEmpty && data.first['Status'] == 'ERROR') {
            throw Exception(data.first['Message']);
          } else if (data is Map && data['Status'] == 'ERROR') {
            throw Exception(data['Message']);
          }

          return jsonResponse['data'];
        } else {
          throw Exception(jsonResponse['error'] ?? 'Failed to delete teachers');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }


  Future<String?> uploadTeacherPhoto(XFile imageFile) async {
    print("🚀 [uploadTeacherPhoto] Starting photo upload for: ${imageFile.path}");
    final stopwatch = Stopwatch()..start();
    try {
      final imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      print("🖼 [uploadTeacherPhoto] Image successfully encoded to base64.");

      final payload = {
        'userID': 1,
        'groupCode': 1,
        'imageType': 'LMS',
        'stationImages': [base64Image],
        'str':""
      };

      final url = Uri.parse(_imageUploadUrl);
      print("📤 [uploadTeacherPhoto] Sending POST request to: $url");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 30));

      stopwatch.stop();
      print("✅ [uploadTeacherPhoto] Received response. Status: ${response.statusCode} in ${stopwatch.elapsedMilliseconds}ms");
      print("📦 [uploadTeacherPhoto] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        final errorObject = responseBody['error'];
        if (errorObject != null && errorObject['code'] == 200) {
          final stationUploads = responseBody['stationUploads'] as List<dynamic>?;

          if (stationUploads != null && stationUploads.isNotEmpty) {
            final String uniqueFileName = stationUploads[0]['UniqueFileName'];

            print("✅ [uploadTeacherPhoto] Success! Filename: $uniqueFileName");
            return uniqueFileName;
          } else {
            print("❌ [uploadTeacherPhoto] API indicated success but no image path was returned.");
            throw Exception("Server returned success but no image path was found.");
          }
        } else {
          final errorMessage = errorObject?['message'] ?? 'Unknown API error';
          print("❌ [uploadTeacherPhoto] API indicated failure: $errorMessage");
          throw Exception("Server returned failure status: $errorMessage");
        }
      } else {
        print("❌ [uploadTeacherPhoto] HTTP Error. Status Code: ${response.statusCode}");
        throw HttpException('Server responded with status code ${response.statusCode}');
      }
    } on SocketException catch (e) {
      stopwatch.stop();
      print("❌ [uploadTeacherPhoto] Network Error after ${stopwatch.elapsedMilliseconds}ms: $e");
      throw Exception('Network Error: Please check your internet connection and CORS policy on the server.');
    } on TimeoutException catch (e) {
      stopwatch.stop();
      print("❌ [uploadTeacherPhoto] Request timed out after ${stopwatch.elapsedMilliseconds}ms: $e");
      throw Exception('Request timed out. The server took too long to respond.');
    } catch (e) {
      stopwatch.stop();
      print('❌ [uploadTeacherPhoto] An unexpected error occurred after ${stopwatch.elapsedMilliseconds}ms: $e');
      throw Exception('Failed to upload photo: $e');
    }
  }

// Helper method to get full photo URL
  static String getTeacherPhotoUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return '';
    return '$_imageBaseUrl$photoPath';
  }
}
