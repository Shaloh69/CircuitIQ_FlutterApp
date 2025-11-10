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
      _allDevices = await _apiService.getDevices();
      _allDevices = _allDevices
          .where((d) => d.deviceType == AppConstants.deviceType)
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Select a device
  Future<void> selectDevice(String deviceId) async {
    _selectedDeviceId = deviceId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _deviceInfo = await _apiService.getDevice(deviceId);
      
      // Load initial data if available
      if (_deviceInfo?.currentData != null) {
        _updateCurrentData(_deviceInfo!.currentData!);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh device data
  Future<void> refreshDevice() async {
    if (_selectedDeviceId == null) return;

    try {
      _deviceInfo = await _apiService.getDevice(_selectedDeviceId!);
      
      if (_deviceInfo?.currentData != null) {
        _updateCurrentData(_deviceInfo!.currentData!);
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    if (_selectedDeviceId == null) return;

    try {
      _statistics = await _apiService.getStatistics(_selectedDeviceId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  // Control relay
  Future<bool> controlRelay(int channel, bool turnOn) async {
    if (_selectedDeviceId == null) return false;

    try {
      final success = await _apiService.controlRelay(
        _selectedDeviceId!,
        turnOn,
        channel: channel,
      );
      
      if (success) {
        // Refresh device data
        await refreshDevice();
      }
      
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Control all relays
  Future<bool> controlAllRelays(bool turnOn) async {
    if (_selectedDeviceId == null) return false;

    try {
      final success = await _apiService.controlRelay(
        _selectedDeviceId!,
        turnOn,
      );
      
      if (success) {
        await refreshDevice();
      }
      
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Send command
  Future<bool> sendCommand(String command, {String? parameters}) async {
    if (_selectedDeviceId == null) return false;

    try {
      final success = await _apiService.sendCommand(
        _selectedDeviceId!,
        command,
        parameters: parameters,
      );
      
      if (success) {
        // Also send via WebSocket for immediate response
        _webSocketService.sendCommand(_selectedDeviceId!, 
            parameters != null ? '$command $parameters' : command);
      }
      
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // System commands
  Future<bool> systemReset() async {
    if (_selectedDeviceId == null) return false;
    return await _apiService.systemReset(_selectedDeviceId!);
  }

  Future<bool> systemRestart() async {
    if (_selectedDeviceId == null) return false;
    return await _apiService.systemRestart(_selectedDeviceId!);
  }

  // Configuration
  Future<bool> setConfig(String parameter, dynamic value) async {
    if (_selectedDeviceId == null) return false;
    return await _apiService.setConfig(_selectedDeviceId!, parameter, value);
  }

  // Generate mock data for testing
  Future<bool> generateMockData({int count = 1}) async {
    if (_selectedDeviceId == null) return false;
    return await _apiService.generateMockData(_selectedDeviceId!, count: count);
  }

  // Connect WebSocket
  void connectWebSocket(String serverUrl) {
    _webSocketService.connect(serverUrl);
  }

  // Disconnect WebSocket
  void disconnectWebSocket() {
    _webSocketService.disconnect();
  }

  // Clear data
  void clearData() {
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
