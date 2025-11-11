import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/device_models.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../utils/constants.dart';

class DeviceProvider extends ChangeNotifier {
  WebSocketService _webSocketService;
  ApiService _apiService;

  DeviceProvider(this._webSocketService, this._apiService) {
    _webSocketService.addListener(_onWebSocketUpdate);
  }

  // Current device data
  DeviceData? _currentData;
  DeviceInfo? _deviceInfo;
  List<DeviceInfo> _allDevices = [];
  Statistics? _statistics;
  
  // Chart data
  final List<ChartDataPoint> _voltageData = [];
  final List<ChartDataPoint> _ch1CurrentData = [];
  final List<ChartDataPoint> _ch2CurrentData = [];
  final List<ChartDataPoint> _ch1PowerData = [];
  final List<ChartDataPoint> _ch2PowerData = [];
  final List<ChartDataPoint> _totalPowerData = [];
  
  // State
  bool _isLoading = false;
  String? _error;
  String? _selectedDeviceId;

  // Getters
  DeviceData? get currentData => _currentData;
  DeviceInfo? get deviceInfo => _deviceInfo;
  List<DeviceInfo> get allDevices => _allDevices;
  Statistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedDeviceId => _selectedDeviceId;
  bool get isConnected => _webSocketService.isConnected;

  List<ChartDataPoint> get voltageData => _voltageData;
  List<ChartDataPoint> get ch1CurrentData => _ch1CurrentData;
  List<ChartDataPoint> get ch2CurrentData => _ch2CurrentData;
  List<ChartDataPoint> get ch1PowerData => _ch1PowerData;
  List<ChartDataPoint> get ch2PowerData => _ch2PowerData;
  List<ChartDataPoint> get totalPowerData => _totalPowerData;

  void updateServices(WebSocketService ws, ApiService api) {
    _webSocketService.removeListener(_onWebSocketUpdate);
    _webSocketService = ws;
    _apiService = api;
    _webSocketService.addListener(_onWebSocketUpdate);
  }

  void _onWebSocketUpdate() {
    if (_selectedDeviceId != null) {
      final data = _webSocketService.getLatestData(_selectedDeviceId!);
      if (data != null) {
        _updateCurrentData(data);
      }
    }
    notifyListeners();
  }

  void _updateCurrentData(DeviceData data) {
    _currentData = data;
    _addToChartData(data);
    notifyListeners();
  }

  void _addToChartData(DeviceData data) {
    final now = data.timestamp;
    
    // Add new data points
    _voltageData.add(ChartDataPoint(now, data.voltage));
    _ch1CurrentData.add(ChartDataPoint(now, data.channel1.current));
    _ch2CurrentData.add(ChartDataPoint(now, data.channel2.current));
    _ch1PowerData.add(ChartDataPoint(now, data.channel1.power));
    _ch2PowerData.add(ChartDataPoint(now, data.channel2.power));
    _totalPowerData.add(ChartDataPoint(now, data.totalPower));
    
    // Keep only max data points
    if (_voltageData.length > AppConstants.maxDataPoints) {
      _voltageData.removeAt(0);
      _ch1CurrentData.removeAt(0);
      _ch2CurrentData.removeAt(0);
      _ch1PowerData.removeAt(0);
      _ch2PowerData.removeAt(0);
      _totalPowerData.removeAt(0);
    }
  }

  // Load all devices
  Future<void> loadDevices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('📡 Loading devices from API...');
      _allDevices = await _apiService.getDevices();
      _allDevices = _allDevices
          .where((d) => d.deviceType == AppConstants.deviceType)
          .toList();
      debugPrint('✅ Loaded ${_allDevices.length} devices');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading devices: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Select a device
  Future<void> selectDevice(String deviceId) async {
    debugPrint('🔄 Selecting device: $deviceId');
    _selectedDeviceId = deviceId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get device info
      debugPrint('📡 Fetching device info from API...');
      _deviceInfo = await _apiService.getDevice(deviceId);
      debugPrint('✅ Device info loaded');
      
      // Load initial data if available from device info
      if (_deviceInfo?.currentData != null) {
        debugPrint('✅ Current data found in device info');
        _updateCurrentData(_deviceInfo!.currentData!);
      } else {
        // If no current data in device info, try to fetch latest reading
        debugPrint('⚠️ No current data in device info, fetching latest reading...');
        try {
          final readings = await _apiService.getReadings(deviceId, limit: 1);
          if (readings.isNotEmpty) {
            debugPrint('✅ Loaded latest reading from API');
            _updateCurrentData(readings.first);
          } else {
            debugPrint('⚠️ No readings found for device $deviceId');
            // Even if no readings, we should still show the UI
            // The user can see "waiting for data" message
          }
        } catch (e) {
          debugPrint('❌ Error fetching latest reading: $e');
          // Don't throw error here, just log it
          // The app can still work with WebSocket data
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error selecting device: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh device data
  Future<void> refreshDevice() async {
    if (_selectedDeviceId == null) return;

    debugPrint('🔄 Refreshing device data...');
    try {
      _deviceInfo = await _apiService.getDevice(_selectedDeviceId!);
      
      // Try to get current data from device info
      if (_deviceInfo?.currentData != null) {
        debugPrint('✅ Updated with current data from device info');
        _updateCurrentData(_deviceInfo!.currentData!);
      } else {
        // Fetch latest reading
        debugPrint('📡 Fetching latest reading...');
        final readings = await _apiService.getReadings(_selectedDeviceId!, limit: 1);
        if (readings.isNotEmpty) {
          debugPrint('✅ Updated with latest reading');
          _updateCurrentData(readings.first);
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing device: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    if (_selectedDeviceId == null) return;

    try {
      debugPrint('📊 Loading statistics...');
      _statistics = await _apiService.getStatistics(_selectedDeviceId);
      debugPrint('✅ Statistics loaded');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading statistics: $e');
    }
  }

  // Control relay
  Future<bool> controlRelay(int channel, bool turnOn) async {
    if (_selectedDeviceId == null) return false;

    try {
      debugPrint('🔌 Controlling relay - Channel $channel: ${turnOn ? "ON" : "OFF"}');
      final success = await _apiService.controlRelay(
        _selectedDeviceId!,
        turnOn,
        channel: channel,
      );
      
      if (success) {
        debugPrint('✅ Relay command successful');
        // Refresh device data after a short delay to see the change
        await Future.delayed(const Duration(milliseconds: 500));
        await refreshDevice();
      } else {
        debugPrint('❌ Relay command failed');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error controlling relay: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Control all relays
  Future<bool> controlAllRelays(bool turnOn) async {
    if (_selectedDeviceId == null) return false;

    try {
      debugPrint('🔌 Controlling all relays: ${turnOn ? "ON" : "OFF"}');
      final success = await _apiService.controlRelay(
        _selectedDeviceId!,
        turnOn,
      );
      
      if (success) {
        debugPrint('✅ All relays command successful');
        await Future.delayed(const Duration(milliseconds: 500));
        await refreshDevice();
      } else {
        debugPrint('❌ All relays command failed');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error controlling all relays: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Send command
  Future<bool> sendCommand(String command, {String? parameters}) async {
    if (_selectedDeviceId == null) return false;

    try {
      debugPrint('📤 Sending command: $command ${parameters ?? ""}');
      final success = await _apiService.sendCommand(
        _selectedDeviceId!,
        command,
        parameters: parameters,
      );
      
      if (success) {
        debugPrint('✅ Command sent successfully');
        // Also send via WebSocket for immediate response
        _webSocketService.sendCommand(_selectedDeviceId!, 
            parameters != null ? '$command $parameters' : command);
        
        // Refresh data if it's a command that might change state
        if (command == 'status' || command == 'test' || command == 'diagnostics') {
          await Future.delayed(const Duration(milliseconds: 500));
          await refreshDevice();
        }
      } else {
        debugPrint('❌ Command failed');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error sending command: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // System commands
  Future<bool> systemReset() async {
    if (_selectedDeviceId == null) return false;
    debugPrint('⚠️ Executing system reset...');
    final success = await _apiService.systemReset(_selectedDeviceId!);
    if (success) {
      debugPrint('✅ System reset successful');
      // Clear local data as device will restart
      _currentData = null;
      notifyListeners();
    }
    return success;
  }

  Future<bool> systemRestart() async {
    if (_selectedDeviceId == null) return false;
    debugPrint('⚠️ Executing system restart...');
    final success = await _apiService.systemRestart(_selectedDeviceId!);
    if (success) {
      debugPrint('✅ System restart successful');
      // Clear local data as device will restart
      _currentData = null;
      notifyListeners();
    }
    return success;
  }

  // Configuration
  Future<bool> setConfig(String parameter, dynamic value) async {
    if (_selectedDeviceId == null) return false;
    debugPrint('⚙️ Setting config: $parameter = $value');
    return await _apiService.setConfig(_selectedDeviceId!, parameter, value);
  }

  // Generate mock data for testing
  Future<bool> generateMockData({int count = 1}) async {
    if (_selectedDeviceId == null) return false;
    debugPrint('🎲 Generating $count mock data reading(s)...');
    final success = await _apiService.generateMockData(_selectedDeviceId!, count: count);
    if (success) {
      debugPrint('✅ Mock data generated');
      // Refresh to load the new data
      await Future.delayed(const Duration(milliseconds: 300));
      await refreshDevice();
    }
    return success;
  }

  // Connect WebSocket
  void connectWebSocket(String serverUrl) {
    debugPrint('🔌 Connecting to WebSocket: $serverUrl');
    _webSocketService.connect(serverUrl);
  }

  // Disconnect WebSocket
  void disconnectWebSocket() {
    debugPrint('🔌 Disconnecting WebSocket');
    _webSocketService.disconnect();
  }

  // Clear data
  void clearData() {
    debugPrint('🗑️ Clearing all device data');
    _currentData = null;
    _deviceInfo = null;
    _statistics = null;
    _selectedDeviceId = null;
    _voltageData.clear();
    _ch1CurrentData.clear();
    _ch2CurrentData.clear();
    _ch1PowerData.clear();
    _ch2PowerData.clear();
    _totalPowerData.clear();
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _webSocketService.removeListener(_onWebSocketUpdate);
    super.dispose();
  }
}