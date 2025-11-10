import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_models.dart';
import '../utils/constants.dart';

class ApiService extends ChangeNotifier {
  final SharedPreferences prefs;
  String _serverUrl = AppConstants.defaultServerUrl;
  String? _username;
  String? _password;

  ApiService(this.prefs) {
    _loadSettings();
  }

  String get serverUrl => _serverUrl;
  bool get isConfigured => _username != null && _password != null;

  void _loadSettings() {
    _serverUrl = prefs.getString(AppConstants.keyServerUrl) ?? 
        AppConstants.defaultServerUrl;
    _username = prefs.getString(AppConstants.keyUsername);
    _password = prefs.getString(AppConstants.keyPassword);
    notifyListeners();
  }

  Future<void> updateServerUrl(String url) async {
    _serverUrl = url;
    await prefs.setString(AppConstants.keyServerUrl, url);
    notifyListeners();
  }

  Future<void> setCredentials(String username, String password) async {
    _username = username;
    _password = password;
    await prefs.setString(AppConstants.keyUsername, username);
    await prefs.setString(AppConstants.keyPassword, password);
    notifyListeners();
  }

  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (_username != null && _password != null) {
      final credentials = base64Encode(utf8.encode('$_username:$_password'));
      headers['Authorization'] = 'Basic $credentials';
    }

    return headers;
  }

  // Health Check
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_serverUrl${AppConstants.apiHealth}'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Get all devices
  Future<List<DeviceInfo>> getDevices() async {
    try {
      final response = await http.get(
        Uri.parse('$_serverUrl${AppConstants.apiDevices}'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => DeviceInfo.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load devices: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading devices: $e');
    }
  }

  // Get specific device
  Future<DeviceInfo> getDevice(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$_serverUrl${AppConstants.apiDevices}/$deviceId'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return DeviceInfo.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Device not found');
      } else {
        throw Exception('Failed to load device: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading device: $e');
    }
  }

  // Get device readings
  Future<List<DeviceData>> getReadings(String deviceId, {int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$_serverUrl${AppConstants.apiDevices}/$deviceId/readings?limit=$limit'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => DeviceData.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load readings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading readings: $e');
    }
  }

  // Get statistics
  Future<Statistics?> getStatistics(String? deviceId) async {
    try {
      String url = '$_serverUrl${AppConstants.apiStats}';
      if (deviceId != null) {
        url += '?deviceId=$deviceId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['cirquitiq'] != null) {
          return Statistics.fromJson(data['cirquitiq']);
        }
        return null;
      } else {
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading statistics: $e');
    }
  }

  // Send command to device
  Future<bool> sendCommand(String deviceId, String command, {String? parameters}) async {
    try {
      final body = {
        'command': command,
        if (parameters != null) 'parameters': parameters,
      };

      final response = await http.post(
        Uri.parse('$_serverUrl${AppConstants.apiCommand}/$deviceId'),
        headers: _getHeaders(),
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error sending command: $e');
      return false;
    }
  }

  // Control relay
  Future<bool> controlRelay(String deviceId, bool turnOn, {int? channel}) async {
    try {
      String url = '$_serverUrl${AppConstants.apiRelay}/$deviceId/${turnOn ? 'on' : 'off'}';
      
      if (channel != null) {
        url += '?channel=$channel';
      }

      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error controlling relay: $e');
      return false;
    }
  }

  // System reset
  Future<bool> systemReset(String deviceId) async {
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl${AppConstants.apiSystem}/$deviceId/reset'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error resetting system: $e');
      return false;
    }
  }

  // System restart
  Future<bool> systemRestart(String deviceId) async {
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl${AppConstants.apiSystem}/$deviceId/restart'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error restarting system: $e');
      return false;
    }
  }

  // Set configuration
  Future<bool> setConfig(String deviceId, String parameter, dynamic value) async {
    try {
      final body = {
        'parameter': parameter,
        'value': value,
      };

      final response = await http.post(
        Uri.parse('$_serverUrl${AppConstants.apiConfig}/$deviceId'),
        headers: _getHeaders(),
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error setting config: $e');
      return false;
    }
  }

  // Generate mock data (for testing)
  Future<bool> generateMockData(String deviceId, {int count = 1}) async {
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/api/mock/data/$deviceId?type=CIRQUITIQ&count=$count'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error generating mock data: $e');
      return false;
    }
  }
}
