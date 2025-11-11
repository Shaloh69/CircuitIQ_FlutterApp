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
    debugPrint('🔐 Auth state loaded: isAuthenticated=$_isAuthenticated, username=$_username');
    notifyListeners();
  }

  Future<bool> login(String username, String password, String serverUrl, 
      {String? deviceId, bool rememberMe = false}) async {
    try {
      debugPrint('🔐 Logging in as $username to $serverUrl');
      
      // Save credentials
      await prefs.setString(AppConstants.keyUsername, username);
      await prefs.setString(AppConstants.keyPassword, password);
      await prefs.setString(AppConstants.keyServerUrl, serverUrl);
      await prefs.setBool(AppConstants.keyRememberMe, rememberMe);
      
      if (deviceId != null && deviceId.isNotEmpty) {
        await prefs.setString(AppConstants.keyDeviceId, deviceId);
        _deviceId = deviceId;
        debugPrint('🔐 Device ID set: $deviceId');
      }

      _username = username;
      _serverUrl = serverUrl;
      _isAuthenticated = true;
      
      debugPrint('✅ Login successful');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    debugPrint('🔐 Logging out...');
    
    // FIXED: Check for null before using !
    final rememberMe = prefs.getBool(AppConstants.keyRememberMe) ?? false;
    
    if (!rememberMe) {
      // Only clear credentials if "remember me" is not enabled
      await prefs.remove(AppConstants.keyUsername);
      await prefs.remove(AppConstants.keyPassword);
      debugPrint('🔐 Credentials cleared');
    } else {
      debugPrint('🔐 Credentials kept (remember me enabled)');
    }
    
    // Always disable remember me and clear authentication on logout
    await prefs.setBool(AppConstants.keyRememberMe, false);
    
    _isAuthenticated = false;
    debugPrint('✅ Logout successful');
    notifyListeners();
  }

  Future<void> setDeviceId(String deviceId) async {
    debugPrint('🔐 Setting device ID: $deviceId');
    await prefs.setString(AppConstants.keyDeviceId, deviceId);
    _deviceId = deviceId;
    notifyListeners();
  }

  Future<void> clearDeviceId() async {
    debugPrint('🔐 Clearing device ID');
    await prefs.remove(AppConstants.keyDeviceId);
    _deviceId = null;
    notifyListeners();
  }

  // ADDED: Method to check if credentials are saved
  bool hasStoredCredentials() {
    return prefs.getString(AppConstants.keyUsername) != null &&
           prefs.getString(AppConstants.keyPassword) != null;
  }

  // ADDED: Method to get stored credentials
  Map<String, String>? getStoredCredentials() {
    final username = prefs.getString(AppConstants.keyUsername);
    final password = prefs.getString(AppConstants.keyPassword);
    
    if (username != null && password != null) {
      return {
        'username': username,
        'password': password,
      };
    }
    return null;
  }

  // ADDED: Method to update server URL without re-authentication
  Future<void> updateServerUrl(String serverUrl) async {
    debugPrint('🔐 Updating server URL: $serverUrl');
    await prefs.setString(AppConstants.keyServerUrl, serverUrl);
    _serverUrl = serverUrl;
    notifyListeners();
  }
}