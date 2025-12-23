import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:lms_publisher/Util/AppUrl.dart';

class UserRightsService {
  static const String baseUrl = AppUrls.baseUrl;

  // Fetch all user groups/roles
  Future<List<UserGroup>> getUserGroups() async {
    try {
      print("🔍 Fetching user groups...");

      final response = await http.post(
        Uri.parse('$baseUrl/UserRights.php'),
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

  // Add these methods to your UserRightsService class

  /// Check if UserID exists in the database
  Future<bool> checkUserIdExists(String userId) async {
    try {
      print("🔍 Checking if UserID exists: $userId");

      final response = await http.post(
        Uri.parse('$baseUrl/UserRights.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Operation': 'CHECK_USERID',
          'UserID': userId,
        }),
      );

      print("✅ Check UserID response: ${response.statusCode}");
      print("📦 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final resultSet = data['data']['resultSet_0'];
          if (resultSet != null && resultSet.isNotEmpty) {
            final userIdExists = resultSet[0]['UserIDExists'] == 'True';
            print("✅ UserID exists: $userIdExists");
            return userIdExists;
          }
        }
        return false;
      }

      throw Exception('Failed to check UserID: ${response.statusCode}');
    } catch (e) {
      print("❌ Error checking UserID: $e");
      throw Exception('Error checking UserID: $e');
    }
  }

  /// Reset password using UserID
  Future<void> resetPasswordByUserId({
    required String userId,
    required String newPassword,
  }) async {
    try {
      print("🔄 Resetting password for UserID: $userId");

      // Generate salt and encrypt password
      final salt = _generateSalt();
      final encryptedPassword = _encryptPassword(newPassword, salt);

      final response = await http.post(
        Uri.parse('$baseUrl/UserRights.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Operation': 'UPDATE_CREDENTIALS',
          'UserID': userId,
          'NewPassword': newPassword,  // Will be encrypted by PHP
          'ModifiedBy': 'system_reset',
        }),
      );

      print("✅ Reset password response: ${response.statusCode}");
      print("📦 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['success'] == true) {
          print("✅ Password reset successful");
          return;
        } else {
          throw Exception(data['message'] ?? 'Failed to reset password');
        }
      }

      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      print("❌ Error resetting password: $e");
      throw Exception('Error resetting password: $e');
    }
  }


  // Login with username and password
  Future<LoginResponse> login({
    required String userId,
    required String password,
  }) async {
    try {
      print("🔐 Login attempt for UserID: $userId");

      final response = await http.post(
        Uri.parse('$baseUrl/UserRights.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Operation': 'LOGIN',
          'UserID': userId,
          'UserPassword': password,
        }),
      );

      print("✅ Login response: ${response.statusCode}");
      print("📦 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          return LoginResponse.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Login failed');
        }
      }
      throw Exception('Failed to login: ${response.statusCode}');
    } catch (e) {
      print("❌ Login error: $e");
      throw Exception('Login error: $e');
    }
  }

  // INSERT a new user - Returns UserCode as String
  Future<Map<String, dynamic>> insertUser(Map<String, dynamic> userData) async {
    try {
      print("🚀 Inserting user with data: ${jsonEncode(userData)}");

      final response = await http.post(
        Uri.parse('$baseUrl/UserRights.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Operation': 'INSERT',
          ...userData,
        }),
      );

      print("✅ Insert user response: ${response.statusCode}");
      print("📦 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['success'] == true) {
          print("🔍 Checking for UserCode in response...");

          // Check if UserCode is directly in data
          if (data['data']['UserCode'] != null) {
            // Convert int to String
            final userCode = data['data']['UserCode'].toString();
            data['data']['UserCode'] = userCode;
            print("✅ UserCode found directly: $userCode");
            return data;
          }
          // Or check in resultSet_0
          else if (data['data']['resultSet_0'] != null &&
              data['data']['resultSet_0'].isNotEmpty &&
              data['data']['resultSet_0'][0]['UserCode'] != null) {
            // Convert int to String
            final userCode = data['data']['resultSet_0'][0]['UserCode'].toString();
            data['data']['UserCode'] = userCode;
            print("✅ UserCode found in resultSet_0: $userCode");
            return data;
          } else {
            print("❌ UserCode not found in response!");
            print("📦 Available keys in data: ${data['data'].keys.toList()}");
            throw Exception('UserCode not returned from server');
          }
        } else {
          throw Exception(data['details'] ?? data['message'] ?? 'Failed to insert user');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Error inserting user: $e");
      throw Exception('Error inserting user: $e');
    }
  }

  // DELETE a user by their UserCode
  Future<void> deleteUser(String userCode) async {
    try {
      print("🗑️ Deleting user: $userCode");

      final response = await http.post(
        Uri.parse('$baseUrl/UserRights.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Operation': 'DELETE',
          'UserCode': userCode,
        }),
      );

      print("✅ Delete user response: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw Exception(data['details'] ?? 'Failed to delete user');
        }
      } else {
        throw Exception('Server error on delete: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Error deleting user: $e");
      throw Exception('Error deleting user: $e');
    }
  }

  /// Get user credentials by UserCode (Student_ID)
  Future<Map<String, dynamic>> getUserCredentials({
    required int userCode,
  }) async {
    try {
      print("🔍 Fetching credentials for UserCode: $userCode");
      final response = await http.post(
        Uri.parse('$baseUrl/manage_user_cred.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'GET',
          'UserCode': userCode,
        }),
      );

      print("✅ Get credentials response: ${response.statusCode}");
      print("📦 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data;
        }
        throw Exception(data['message'] ?? 'Failed to fetch credentials');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      print("❌ Error fetching credentials: $e");
      throw Exception('Error fetching credentials: $e');
    }
  }

  /// Update user credentials (UserID and/or Password)
  Future<void> updateUserCredentials({
    required int userCode,
    String? newUserID,
    String? newPassword,
    required String modifiedBy,
  }) async {
    try {
      print("🔄 Updating credentials for UserCode: $userCode");

      final Map<String, dynamic> requestBody = {
        'action': 'UPDATE',
        'UserCode': userCode,
        'ModifiedBy': modifiedBy,
      };

      // Add UserID if provided
      if (newUserID != null && newUserID.trim().isNotEmpty) {
        requestBody['NewUserID'] = newUserID.trim();
      }

      // Add encrypted password if provided
      if (newPassword != null && newPassword.trim().isNotEmpty) {
        final salt = _generateSalt();
        final encryptedPassword = _encryptPassword(newPassword, salt);
        requestBody['NewEncryptPassword'] = encryptedPassword;
        requestBody['NewSalt'] = salt;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/manage_user_cred.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print("✅ Update credentials response: ${response.statusCode}");
      print("📦 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] != 'success') {
          throw Exception(data['message'] ?? 'Failed to update credentials');
        }
        return;
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      print("❌ Error updating credentials: $e");
      throw Exception('Error updating credentials: $e');
    }
  }

  /// Delete user credentials (archives and removes)
  Future<void> deleteUserCredentials({
    required int userCode,
  }) async {
    try {
      print("🗑️ Deleting credentials for UserCode: $userCode");

      final response = await http.post(
        Uri.parse('$baseUrl/manage_user_cred.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'DELETE',
          'UserCode': userCode,
        }),
      );

      print("✅ Delete credentials response: ${response.statusCode}");
      print("📦 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] != 'success') {
          throw Exception(data['message'] ?? 'Failed to delete credentials');
        }
        return;
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      print("❌ Error deleting credentials: $e");
      throw Exception('Error deleting credentials: $e');
    }
  }

  // ============================================================================
  // ENCRYPTION HELPERS
  // ============================================================================

  /// Generate random salt for password encryption
  String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Encrypt password using SHA-256 with salt
  /// Encrypt password using SHA-256 with salt
  /// ✅ FIXED: password + salt (matches stored hashes)
  String _encryptPassword(String password, String salt) {
    // ✅ CRITICAL: password + salt order
    final bytes = utf8.encode(password + salt);
    final hash = sha256.convert(bytes);
    print("🔐 Dart Encryption: password + salt");
    print("   Password: ${password.substring(0, min(3, password.length))}***");
    print("   Salt: ${salt.substring(0, min(8, salt.length))}...");
    print("   Hash: ${hash.toString().substring(0, 16)}...");
    return hash.toString();
  }


}


class UserData {
  final String? userCode; // Keep as String for Flutter usage
  final String userGroupCode;
  final String userName;
  final String userID;
  final String? userPassword;
  final bool isBlocked;

  UserData({
    this.userCode,
    required this.userGroupCode,
    required this.userName,
    required this.userID,
    this.userPassword,
    required this.isBlocked,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'UserGroupCode': userGroupCode,
      'UserName': userName,
      'UserID': userID,
      'IsBlocked': isBlocked ? 1 : 0, // Changed from '1'/'0' to int
    };

    if (userCode != null) {
      // Convert String to int for database
      data['UserCode'] = int.tryParse(userCode!) ?? userCode;
    }

    if (userPassword != null && userPassword!.isNotEmpty) {
      data['UserPassword'] = userPassword;
    }

    return data;
  }
}

// User Group Model
class UserGroup {
  final String userGroupCode;
  final String userGroupName;
  final String addUser;
  final String editUser;

  UserGroup({
    required this.userGroupCode,
    required this.userGroupName,
    required this.addUser,
    required this.editUser,
  });

  factory UserGroup.fromJson(Map<String, dynamic> json) {
    return UserGroup(
      userGroupCode: json['UserGroupCode']?.toString() ?? '',
      userGroupName: json['UserGroupName']?.toString() ?? '',
      addUser: json['AddUser']?.toString() ?? '0',
      editUser: json['EditUser']?.toString() ?? '0',
    );
  }
}

// Login Response Model
class LoginResponse {
  final bool success;
  final Map<String, dynamic> userData;
  final int resultSetsCount;

  LoginResponse({
    required this.success,
    required this.userData,
    required this.resultSetsCount,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      userData: json['data'] ?? {},
      resultSetsCount: json['resultSetsCount'] ?? 0,
    );
  }
}
