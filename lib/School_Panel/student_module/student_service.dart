import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException, HttpException;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lms_publisher/School_Panel/student_module/student_model.dart';


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

class StudentApiService {
  // Update this with your actual API URL
  static const String baseUrl =  'https://aquare.co.in/mobileAPI/sachin/lms';
  static const String _imageBaseUrl = "https://storage.googleapis.com/upload-images-34/images/LMS/";
  // static const String _imageUploadUrl = "$baseUrl/upload-image-gcp/uploadgcp.php";

  static const String _imageUploadUrl = "https://www.aquare.co.in/mobileAPI/sachin/photogcp1.php";
  // School RecNo must be provided by callers via parameters or payload

  // List Students
// List Students
  Future<List<StudentModel>> fetchStudents({
    required int schoolRecNo,
    int? classRecNo,
    bool? isActive,
    String? academicYear,  // ADD THIS
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'action': 'LIST',
'School_RecNo': schoolRecNo,
        if (classRecNo != null) 'ClassRecNo': classRecNo,
        if (isActive != null) 'IsActive': isActive ? 1 : 0,
        if (academicYear != null) 'Academic_Year': academicYear,  // ADD THIS
      };

      final response = await http.post(
        Uri.parse('$baseUrl/manage_students.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => StudentModel.fromJson(json)).toList();
        } else {
          throw Exception(jsonResponse['error'] ?? 'Failed to fetch students');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch students: $e');
    }
  }

  // Get Single Student Details
  Future<StudentModel> fetchStudentDetails({required int recNo}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/manage_students.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'GET',
          'RecNo': recNo,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          if (data.isNotEmpty) {
            return StudentModel.fromJson(data[0]);
          } else {
            throw Exception('Student not found');
          }
        } else {
          throw Exception(jsonResponse['error'] ?? 'Failed to fetch student');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch student details: $e');
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

  // Add New Student
  Future<Map<String, dynamic>> addStudent({
    required Map<String, dynamic> studentData,
  }) async {
    try {
      print('\n========================================');
      print('🚀 ADD STUDENT - START');
      print('========================================');

      final requestBody = {
        'action': 'INSERT',
'School_RecNo': studentData['School_RecNo'],
        ...studentData,
      };

      print('📤 Request URL: $baseUrl/manage_students.php');
      print('📋 Request Body:');
      print(jsonEncode(requestBody)); // Print entire request as JSON
      print('----------------------------------------');

      // Print key fields for debugging
      print('🔑 Key Fields:');
      print('  - Action: ${requestBody['action']}');
      print('  - School_RecNo: ${requestBody['School_RecNo']}');
      print('  - Student_ID: ${requestBody['Student_ID']}');
      print('  - Admission_Number: ${requestBody['Admission_Number']}');
      print('  - First_Name: ${requestBody['First_Name']}');
      print('  - Last_Name: ${requestBody['Last_Name']}');
      print('  - Student_Username: ${requestBody['Student_Username']}');
      print('  - Parent_Username: ${requestBody['Parent_Username']}');
      print('----------------------------------------');

      final response = await http.post(
        Uri.parse('$baseUrl/manage_students.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body:');
      print(response.body);
      print('----------------------------------------');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        print('✅ Response Decoded Successfully');
        print('📊 Response Status: ${jsonResponse['status']}');

        if (jsonResponse['status'] == 'success') {
          print('✅ Student Added Successfully!');
          print('📋 Response Data: ${jsonResponse['data']}');
          print('========================================\n');
          return jsonResponse['data'];
        } else {
          String errorMsg = jsonResponse['error'] ?? 'Failed to add student';

          // ✅ Check for UserID duplicate error
          if (errorMsg.contains('UserID already exists') ||
              errorMsg.contains('Student_ID already exists') ||
              errorMsg.contains('Username already exists')) {
            throw Exception('⚠️ This Student ID or Username already exists. Please use a unique ID.');
          }
          // Print additional error details if available
          if (jsonResponse.containsKey('details')) {
            print('🔍 Error Details: ${jsonResponse['details']}');
          }
          if (jsonResponse.containsKey('action')) {
            print('🔍 Action: ${jsonResponse['action']}');
          }

          print('========================================\n');
          throw Exception(errorMsg);
        }
      } else {
        print('❌ Server Error!');
        print('Status Code: ${response.statusCode}');
        print('Response: ${response.body}');
        print('========================================\n');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ EXCEPTION CAUGHT!');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('Stack Trace:');
      print(StackTrace.current);
      print('========================================\n');
      throw Exception('Failed to add student: $e');
    }
  }


  // ✅ NEW: Get State Name by ID
  Future<String?> getStateName(int stateId) async {
    try {
      final states = await fetchStates();
      final state = states.firstWhere(
            (s) => s.id == stateId.toString(),
        orElse: () => StateModel(id: '', name: ''),
      );
      return state.name.isNotEmpty ? state.name : null;
    } catch (e) {
      print("❌ Error fetching state name: $e");
      return null;
    }
  }

// ✅ NEW: Get District Name by ID
  Future<String?> getDistrictName(int stateId, int districtId) async {
    try {
      final districts = await fetchDistricts(stateId.toString());
      final district = districts.firstWhere(
            (d) => d.id == districtId.toString(),
        orElse: () => DistrictModel(id: '', name: ''),
      );
      return district.name.isNotEmpty ? district.name : null;
    } catch (e) {
      print("❌ Error fetching district name: $e");
      return null;
    }
  }

// ✅ NEW: Get City Name by ID
  Future<String?> getCityName(int districtId, int cityId) async {
    try {
      final cities = await fetchCities(districtId.toString());
      final city = cities.firstWhere(
            (c) => c.id == cityId.toString(),
        orElse: () => CityModel(id: '', name: ''),
      );
      return city.name.isNotEmpty ? city.name : null;
    } catch (e) {
      print("❌ Error fetching city name: $e");
      return null;
    }
  }

// ✅ NEW: Get Complete Address with Real Names
  Future<String> getCompleteAddress({
    String? streetAddress,
    int? cityId,
    int? districtId,
    int? stateId,
    String? country,
    String? pin,
  }) async {
    final addressParts = <String>[];

    // Add street address
    if (streetAddress?.isNotEmpty == true) {
      addressParts.add(streetAddress!);
    }

    // Fetch and add city name
    if (cityId != null && districtId != null) {
      final cityName = await getCityName(districtId, cityId);
      if (cityName != null) addressParts.add(cityName);
    }

    // Fetch and add district name
    if (districtId != null && stateId != null) {
      final districtName = await getDistrictName(stateId, districtId);
      if (districtName != null) addressParts.add(districtName);
    }

    // Fetch and add state name
    if (stateId != null) {
      final stateName = await getStateName(stateId);
      if (stateName != null) addressParts.add(stateName);
    }

    // Add country
    if (country?.isNotEmpty == true) {
      addressParts.add(country!);
    }

    // Add PIN code
    if (pin?.isNotEmpty == true) {
      addressParts.add('PIN: $pin');
    }

    return addressParts.join(', ');
  }


  // Update Student
  Future<Map<String, dynamic>> updateStudent({
    required int recNo,
    required Map<String, dynamic> studentData,
  }) async {
    try {
      final requestBody = {
        'action': 'UPDATE',
        'RecNo': recNo,
'School_RecNo': studentData['School_RecNo'],
        ...studentData,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/manage_students.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data'];
        } else {
          throw Exception(jsonResponse['error'] ?? 'Failed to update student');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }

  // Delete Single Student
  Future<void> deleteStudent({
    required int recNo,
    required String operationBy,
    String? reasonForChange,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/manage_students.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'DELETE',
          'RecNo': recNo,
          'Operation_By': operationBy,
          if (reasonForChange != null) 'Reason_For_Change': reasonForChange,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] != 'success') {
          throw Exception(jsonResponse['error'] ?? 'Failed to delete student');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }

  // Delete Multiple Students
  Future<Map<String, dynamic>> deleteStudentsBulk({
    required List<int> recNoList,
    required String operationBy,
    String? reasonForChange,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/manage_students.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'DELETE_BULK',
          'RecNoList': recNoList,
          'Operation_By': operationBy,
          if (reasonForChange != null) 'Reason_For_Change': reasonForChange,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data'];
        } else {
          throw Exception(jsonResponse['error'] ?? 'Failed to delete students');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete students: $e');
    }
  }

  // Get Student History
  Future<List<Map<String, dynamic>>> fetchStudentHistory({
    required int recNo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/manage_students.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'HISTORY',
          'RecNo': recNo,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          return List<Map<String, dynamic>>.from(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['error'] ?? 'Failed to fetch history');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch student history: $e');
    }
  }


  // Get Classes by School
  Future<List<Map<String, dynamic>>> fetchClassesBySchool({
    required int schoolRecNo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/manage_students.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'GET_CLASSES',
          'School_RecNo': schoolRecNo,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          return List<Map<String, dynamic>>.from(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['error'] ?? 'Failed to fetch classes');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch classes: $e');
    }
  }

// Insert User Master (for student authentication)
// Insert User Master (for student authentication)
  Future<Map<String, dynamic>> insertUserMaster({
    required String userName,
    required int userGroupCode,
    required String userId,
    String? userPassword,  // CHANGE: Made optional with ?
    String? salt,
    String? encryptPassword,
    int isBlocked = 0,
    required String addUser,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/manage_students.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'INSERT_USER',
          'UserName': userName,
          'UserGroupCode': userGroupCode,
          'UserID': userId,
          'UserPassword': userPassword,  // Can be null now
          'Salt': salt,
          'EncryptPassword': encryptPassword,
          'IsBlocked': isBlocked,
          'AddUser': addUser,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data'];
        } else {
          throw Exception(jsonResponse['error'] ?? 'Failed to insert user');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to insert user: $e');
    }
  }


// Hash Password API
  Future<Map<String, dynamic>> hashPassword({
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hash_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return {
            'salt': jsonResponse['salt'],
            'hashedPassword': jsonResponse['hashedPassword'],
          };
        } else {
          throw Exception(jsonResponse['error'] ?? 'Failed to hash password');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to hash password: $e');
    }
  }

  Future<String?> uploadStudentPhoto(XFile imageFile) async {
    print("🚀 [uploadStudentPhoto] Starting photo upload for: ${imageFile.path}");
    final stopwatch = Stopwatch()..start();
    try {
      final imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      print("🖼 [uploadStudentPhoto] Image successfully encoded to base64.");

      final payload = {
        'userID': 1,
        'groupCode': 1,
        'imageType': 'LMS',
        'stationImages': [base64Image],
        'str':""
      };

      final url = Uri.parse(_imageUploadUrl);
      print("📤 [uploadStudentPhoto] Sending POST request to: $url");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 30));

      stopwatch.stop();
      print("✅ [uploadStudentPhoto] Received response. Status: ${response.statusCode} in ${stopwatch.elapsedMilliseconds}ms");
      print("📦 [uploadStudentPhoto] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        final errorObject = responseBody['error'];
        if (errorObject != null && errorObject['code'] == 200) {
          final stationUploads = responseBody['stationUploads'] as List<dynamic>?;

          if (stationUploads != null && stationUploads.isNotEmpty) {
            final String uniqueFileName = stationUploads[0]['UniqueFileName'];

            print("✅ [uploadStudentPhoto] Success! Filename: $uniqueFileName");
            return uniqueFileName;
          } else {
            print("❌ [uploadStudentPhoto] API indicated success but no image path was returned.");
            throw Exception("Server returned success but no image path was found.");
          }
        } else {
          final errorMessage = errorObject?['message'] ?? 'Unknown API error';
          print("❌ [uploadStudentPhoto] API indicated failure: $errorMessage");
          throw Exception("Server returned failure status: $errorMessage");
        }
      } else {
        print("❌ [uploadStudentPhoto] HTTP Error. Status Code: ${response.statusCode}");
        throw HttpException('Server responded with status code ${response.statusCode}');
      }
    } on SocketException catch (e) {
      stopwatch.stop();
      print("❌ [uploadStudentPhoto] Network Error after ${stopwatch.elapsedMilliseconds}ms: $e");
      throw Exception('Network Error: Please check your internet connection and CORS policy on the server.');
    } on TimeoutException catch (e) {
      stopwatch.stop();
      print("❌ [uploadStudentPhoto] Request timed out after ${stopwatch.elapsedMilliseconds}ms: $e");
      throw Exception('Request timed out. The server took too long to respond.');
    } catch (e) {
      stopwatch.stop();
      print('❌ [uploadStudentPhoto] An unexpected error occurred after ${stopwatch.elapsedMilliseconds}ms: $e');
      throw Exception('Failed to upload photo: $e');
    }
  }

// Helper method to get full photo URL - MAKE IT STATIC
  static String getStudentPhotoUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return '';
    return '$_imageBaseUrl$photoPath';
  }



}
