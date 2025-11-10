import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/device_models.dart';

class WebSocketService extends ChangeNotifier {
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _serverUrl;
  
  final List<DeviceData> _realtimeData = [];
  final List<String> _activeDevices = [];

  bool get isConnected => _isConnected;
  List<DeviceData> get realtimeData => _realtimeData;
  List<String> get activeDevices => _activeDevices;

  void connect(String serverUrl) {
    if (_socket != null && _isConnected) {
      debugPrint('Already connected to WebSocket');
      return;
    }

    _serverUrl = serverUrl;
    
    try {
      _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _socket!.connect();

      _socket!.onConnect((_) {
        debugPrint('✅ WebSocket connected');
        _isConnected = true;
        notifyListeners();
      });

      _socket!.onDisconnect((_) {
        debugPrint('❌ WebSocket disconnected');
        _isConnected = false;
        notifyListeners();
      });

      _socket!.onConnectError((data) {
        debugPrint('⚠️ WebSocket connection error: $data');
        _isConnected = false;
        notifyListeners();
      });

      _socket!.onError((data) {
        debugPrint('⚠️ WebSocket error: $data');
      });

      // Listen for sensor data
      _socket!.on('sensorData', (data) {
        try {
          final deviceData = DeviceData.fromJson(data);
          
          // Update or add to realtime data
          final index = _realtimeData.indexWhere(
            (d) => d.deviceId == deviceData.deviceId,
          );
          
          if (index >= 0) {
            _realtimeData[index] = deviceData;
          } else {
            _realtimeData.add(deviceData);
          }
          
          notifyListeners();
        } catch (e) {
          debugPrint('Error parsing sensor data: $e');
        }
      });

      // Listen for active devices
      _socket!.on('activeDevices', (data) {
        try {
          if (data is List) {
            _activeDevices.clear();
            for (var device in data) {
              if (device['deviceType'] == 'CIRQUITIQ') {
                _activeDevices.add(device['deviceId']);
              }
            }
            notifyListeners();
          }
        } catch (e) {
          debugPrint('Error parsing active devices: $e');
        }
      });

      // Listen for device disconnected
      _socket!.on('deviceDisconnected', (data) {
        try {
          final deviceId = data['deviceId'];
          _activeDevices.remove(deviceId);
          _realtimeData.removeWhere((d) => d.deviceId == deviceId);
          notifyListeners();
        } catch (e) {
          debugPrint('Error handling device disconnect: $e');
        }
      });

      // Listen for commands
      _socket!.on('command', (data) {
        debugPrint('📡 Command received: $data');
      });

    } catch (e) {
      debugPrint('Error connecting to WebSocket: $e');
      _isConnected = false;
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _realtimeData.clear();
      _activeDevices.clear();
      notifyListeners();
    }
  }

  void sendCommand(String deviceId, String command) {
    if (_socket != null && _isConnected) {
      _socket!.emit('sendCommand', {
        'deviceId': deviceId,
        'command': command,
      });
      debugPrint('📤 Sent command: $command to $deviceId');
    } else {
      debugPrint('⚠️ Cannot send command: Not connected');
    }
  }

  DeviceData? getLatestData(String deviceId) {
    try {
      return _realtimeData.firstWhere((d) => d.deviceId == deviceId);
    } catch (e) {
      return null;
    }
  }

  void reconnect() {
    disconnect();
    if (_serverUrl != null) {
      Future.delayed(const Duration(seconds: 2), () {
        connect(_serverUrl!);
      });
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
