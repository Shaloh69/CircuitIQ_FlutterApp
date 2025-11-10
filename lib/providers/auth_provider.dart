import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  
  bool _isAuthenticated = false;
  String? _username;
  String? _deviceId;
  String? _serverUrl;

  AuthProvider(this.prefs) {
    _loadAuthState();
  }

  bool get isAuthenticated => _isAuthenticated;
  String? get username => _username;
  String? get deviceId => _deviceId;
  String? get serverUrl => _serverUrl;

  void _loadAuthState() {
    _isAuthenticated = prefs.getBool(AppConstants.keyRememberMe) ?? false;
    _username = prefs.getString(AppConstants.keyUsername);
    _deviceId = prefs.getString(AppConstants.keyDeviceId);
    _serverUrl = prefs.getString(AppConstants.keyServerUrl) ?? 
        AppConstants.defaultServerUrl;
    notifyListeners();
  }

  Future<bool> login(String username, String password, String serverUrl, 
      {String? deviceId, bool rememberMe = false}) async {
    try {
      // Save credentials
      await prefs.setString(AppConstants.keyUsername, username);
      await prefs.setString(AppConstants.keyPassword, password);
      await prefs.setString(AppConstants.keyServerUrl, serverUrl);
      await prefs.setBool(AppConstants.keyRememberMe, rememberMe);
      
      if (deviceId != null && deviceId.isNotEmpty) {
        await prefs.setString(AppConstants.keyDeviceId, deviceId);
        _deviceId = deviceId;
      }

      _username = username;
      _serverUrl = serverUrl;
      _isAuthenticated = true;
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    if (!prefs.getBool(AppConstants.keyRememberMe)!) {
      await prefs.remove(AppConstants.keyUsername);
      await prefs.remove(AppConstants.keyPassword);
    }
    
    await prefs.setBool(AppConstants.keyRememberMe, false);
    
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> setDeviceId(String deviceId) async {
    await prefs.setString(AppConstants.keyDeviceId, deviceId);
    _deviceId = deviceId;
    notifyListeners();
  }

  Future<void> clearDeviceId() async {
    await prefs.remove(AppConstants.keyDeviceId);
    _deviceId = null;
    notifyListeners();
  }
}
