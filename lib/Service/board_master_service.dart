import 'dart:convert';
import 'package:http/http.dart' as http;

class BoardMasterService {
  static final BoardMasterService _instance = BoardMasterService._internal();
  factory BoardMasterService() => _instance;
  BoardMasterService._internal();

  // Base URL for the API
  final String _baseUrl = "http://localhost/Aquarelms";

  // Helper to get specific endpoints
  Uri _getUri(String fileName) => Uri.parse('$_baseUrl/$fileName');

  // --- School Types (getBoard.php) ---

  Future<List<Map<String, String>>> getSchoolTypes() async {
    final body = {'action': 'getSchoolTypes'};
    final response = await http.post(
      _getUri('getBoard.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return List<Map<String, String>>.from(data['data'].map((x) => <String, String>{
          'id': x['SchoolType_ID'].toString(),
          'name': x['SchoolType_Name']?.toString() ?? '',
        }));
      }
    }
    throw Exception('Failed to load school types');
  }

  Future<String> insertSchoolType(String name) async {
    final body = {'action': 'addSchoolType', 'SchoolType_Name': name};
    final response = await http.post(
      _getUri('getBoard.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return data['insertedId'].toString();
      }
    }
    throw Exception('Failed to add school type');
  }

  Future<int> updateSchoolType(String id, String name) async {
    final body = {'action': 'updateSchoolType', 'SchoolType_ID': id, 'SchoolType_Name': name};
    final response = await http.post(
      _getUri('getBoard.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return int.parse(data['rowsAffected'].toString());
      }
    }
    throw Exception('Failed to update school type');
  }

  Future<int> deleteSchoolType(String id) async {
    final body = {'action': 'deleteSchoolType', 'SchoolType_ID': id};
    final response = await http.post(
      _getUri('getBoard.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return int.parse(data['rowsAffected'].toString());
      }
    }
    throw Exception('Failed to delete school type');
  }

  // --- Medium Instructions (getBoard.php) ---

  Future<List<Map<String, String>>> getMediumInstructions() async {
    final body = {'action': 'getMediumInstructions'};
    final response = await http.post(
      _getUri('getBoard.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return List<Map<String, String>>.from(data['data'].map((x) => <String, String>{
          'id': x['Medium_ID'].toString(),
          'name': x['Medium_Name']?.toString() ?? '',
        }));
      }
    }
    throw Exception('Failed to load medium instructions');
  }

  Future<String> insertMediumInstruction(String name) async {
    final body = {'action': 'addMediumInstruction', 'Medium_Name': name};
    final response = await http.post(
      _getUri('getBoard.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return data['insertedId'].toString();
      }
    }
    throw Exception('Failed to add medium instruction');
  }

  Future<int> updateMediumInstruction(String id, String name) async {
    final body = {'action': 'updateMediumInstruction', 'Medium_ID': id, 'Medium_Name': name};
    final response = await http.post(
      _getUri('getBoard.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return int.parse(data['rowsAffected'].toString());
      }
    }
    throw Exception('Failed to update medium instruction');
  }

  Future<int> deleteMediumInstruction(String id) async {
    final body = {'action': 'deleteMediumInstruction', 'Medium_ID': id};
    final response = await http.post(
      _getUri('getBoard.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return int.parse(data['rowsAffected'].toString());
      }
    }
    throw Exception('Failed to delete medium instruction');
  }

  // --- Board Affiliations (getBoard.php) ---

  Future<List<Map<String, String>>> getBoardAffiliations() async {
    final body = {'action': 'getBoardAffliations'};
    final response = await http.post(
      _getUri('getBoard.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return List<Map<String, String>>.from(data['data'].map((x) => <String, String>{
          'id': x['BoardAffliation_ID'].toString(),
          'name': x['BoardAffliation_Name']?.toString() ?? '',
        }));
      }
    }
    throw Exception('Failed to load board affiliations');
  }

  Future<String> insertBoardAffiliation(String name) async {
    final body = {'action': 'addBoardAffliation', 'BoardAffliation_Name': name};
    final response = await http.post(
      _getUri('getBoard.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return data['insertedId'].toString();
      }
    }
    throw Exception('Failed to add board affiliation');
  }

  Future<int> updateBoardAffiliation(String id, String name) async {
    final body = {'action': 'updateBoardAffliation', 'BoardAffliation_ID': id, 'BoardAffliation_Name': name};
    final response = await http.post(
      _getUri('getBoard.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return int.parse(data['rowsAffected'].toString());
      }
    }
    throw Exception('Failed to update board affiliation');
  }

  Future<int> deleteBoardAffiliation(String id) async {
    final body = {'action': 'deleteBoardAffliation', 'BoardAffliation_ID': id};
    final response = await http.post(
      _getUri('getBoard.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return int.parse(data['rowsAffected'].toString());
      }
    }
    throw Exception('Failed to delete board affiliation');
  }

  // --- Management Types (getBoard.php) ---

  Future<List<Map<String, String>>> getManagementTypes() async {
    final body = {'action': 'getManagementTypes'};
    final response = await http.post(
      _getUri('getBoard.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return List<Map<String, String>>.from(data['data'].map((x) => <String, String>{
          'id': x['Management_ID'].toString(),
          'name': x['Management_Name']?.toString() ?? '',
        }));
      }
    }
    throw Exception('Failed to load management types');
  }

  Future<String> insertManagementType(String name) async {
    final body = {'action': 'addManagementType', 'Management_Name': name};
    final response = await http.post(
      _getUri('getBoard.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return data['insertedId'].toString();
      }
    }
    throw Exception('Failed to add management type');
  }

  Future<int> updateManagementType(String id, String name) async {
    final body = {'action': 'updateManagementType', 'Management_ID': id, 'Management_Name': name};
    final response = await http.post(
      _getUri('getBoard.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return int.parse(data['rowsAffected'].toString());
      }
    }
    throw Exception('Failed to update management type');
  }

  Future<int> deleteManagementType(String id) async {
    final body = {'action': 'deleteManagementType', 'Management_ID': id};
    final response = await http.post(
      _getUri('getBoard.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return int.parse(data['rowsAffected'].toString());
      }
    }
    throw Exception('Failed to delete management type');
  }

  // --- NEW: Status Master (GetSchool.php) ---

  Future<List<Map<String, String>>> getStatuses() async {
    final body = {'action': 'statuslist'};
    final response = await http.post(
      _getUri('GetSchool.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return List<Map<String, String>>.from(data['data'].map((x) => <String, String>{
          'id': x['Status_ID'].toString(),
          'name': x['Status_Name']?.toString() ?? '',
        }));
      }
    }
    throw Exception('Failed to load statuses');
  }

  Future<String> insertStatus(String name) async {
    final body = {'action': 'addStatus', 'Status_Name': name};
    final response = await http.post(
      _getUri('GetSchool.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return data['Status_ID'].toString();
      } else {
        throw Exception(data['message']);
      }
    }
    throw Exception('Failed to add status');
  }

  Future<void> updateStatus(String id, String name) async {
    final body = {'action': 'updateStatusMaster', 'Status_ID': id, 'Status_Name': name};
    final response = await http.post(
      _getUri('GetSchool.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (!data['success']) {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Failed to update status');
    }
  }

  Future<void> deleteStatus(String id) async {
    final body = {'action': 'deleteStatus', 'Status_ID': id};
    final response = await http.post(
      _getUri('GetSchool.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (!data['success']) {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Failed to delete status');
    }
  }
}