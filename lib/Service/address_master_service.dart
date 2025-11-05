import 'dart:convert';
import 'package:http/http.dart' as http;

class AddressMasterService {
  static const String baseUrl = 'http://localhost/AquareLMS';

  // Generic API call method
  Future<Map<String, dynamic>> _callApi({
    required String table,
    required String action,
    Map<String, dynamic>? data,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/Addressmaster.php');

      final requestBody = {
        'table': table,
        'action': action,
        ...?data,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API call failed: $e');
    }
  }

  // ==================== STATE OPERATIONS ====================

  Future<List<StateModel>> getStates({int? stateId}) async {
    final response = await _callApi(
      table: 'State_Master',
      action: 'GET',
      data: stateId != null ? {'State_ID': stateId} : null,
    );

    if (response['status'] == 'success' && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => StateModel.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> insertState(String stateName) async {
    return await _callApi(
      table: 'State_Master',
      action: 'INSERT',
      data: {'State_Name': stateName},
    );
  }

  Future<Map<String, dynamic>> updateState(int stateId, String stateName) async {
    return await _callApi(
      table: 'State_Master',
      action: 'UPDATE',
      data: {
        'State_ID': stateId,
        'State_Name': stateName,
      },
    );
  }

  Future<Map<String, dynamic>> deleteState(int stateId) async {
    return await _callApi(
      table: 'State_Master',
      action: 'DELETE',
      data: {'State_ID': stateId},
    );
  }

  // ==================== DISTRICT OPERATIONS ====================

  Future<List<DistrictModel>> getDistricts({int? districtId, int? stateId}) async {
    final response = await _callApi(
      table: 'District_Master',
      action: 'GET',
      data: {
        if (districtId != null) 'District_ID': districtId,
        if (stateId != null) 'State_ID': stateId,
      },
    );

    if (response['status'] == 'success' && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => DistrictModel.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> insertDistrict(String districtName, int stateId) async {
    return await _callApi(
      table: 'District_Master',
      action: 'INSERT',
      data: {
        'District_Name': districtName,
        'State_ID': stateId,
      },
    );
  }

  Future<Map<String, dynamic>> updateDistrict(
      int districtId,
      String districtName,
      int stateId,
      ) async {
    return await _callApi(
      table: 'District_Master',
      action: 'UPDATE',
      data: {
        'District_ID': districtId,
        'District_Name': districtName,
        'State_ID': stateId,
      },
    );
  }

  Future<Map<String, dynamic>> deleteDistrict(int districtId) async {
    return await _callApi(
      table: 'District_Master',
      action: 'DELETE',
      data: {'District_ID': districtId},
    );
  }

  // ==================== CITY OPERATIONS ====================

  Future<List<CityModel>> getCities({
    int? cityId,
    int? districtId,
    int? stateId,
  }) async {
    final response = await _callApi(
      table: 'City_Master',
      action: 'GET',
      data: {
        if (cityId != null) 'City_ID': cityId,
        if (districtId != null) 'District_ID': districtId,
        if (stateId != null) 'State_ID': stateId,
      },
    );

    if (response['status'] == 'success' && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => CityModel.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> insertCity(String cityName, int districtId) async {
    return await _callApi(
      table: 'City_Master',
      action: 'INSERT',
      data: {
        'City_Name': cityName,
        'District_ID': districtId,
      },
    );
  }

  Future<Map<String, dynamic>> updateCity(
      int cityId,
      String cityName,
      int districtId,
      ) async {
    return await _callApi(
      table: 'City_Master',
      action: 'UPDATE',
      data: {
        'City_ID': cityId,
        'City_Name': cityName,
        'District_ID': districtId,
      },
    );
  }

  Future<Map<String, dynamic>> deleteCity(int cityId) async {
    return await _callApi(
      table: 'City_Master',
      action: 'DELETE',
      data: {'City_ID': cityId},
    );
  }
}

// ==================== MODELS ====================

class StateModel {
  final int stateId;
  final String stateName;

  StateModel({required this.stateId, required this.stateName});

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      stateId: int.parse(json['State_ID'].toString()),
      stateName: json['State_Name'] ?? '',
    );
  }
}

class DistrictModel {
  final int districtId;
  final String districtName;
  final int stateId;
  final String? stateName;

  DistrictModel({
    required this.districtId,
    required this.districtName,
    required this.stateId,
    this.stateName,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      districtId: int.parse(json['District_ID'].toString()),
      districtName: json['District_Name'] ?? '',
      stateId: int.parse(json['State_ID'].toString()),
      stateName: json['State_Name'],
    );
  }
}

class CityModel {
  final int cityId;
  final String cityName;
  final int districtId;
  final String? districtName;
  final int? stateId;
  final String? stateName;

  CityModel({
    required this.cityId,
    required this.cityName,
    required this.districtId,
    this.districtName,
    this.stateId,
    this.stateName,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      cityId: int.parse(json['City_ID'].toString()),
      cityName: json['City_Name'] ?? '',
      districtId: int.parse(json['District_ID'].toString()),
      districtName: json['District_Name'],
      stateId: json['State_ID'] != null ? int.parse(json['State_ID'].toString()) : null,
      stateName: json['State_Name'],
    );
  }
}
