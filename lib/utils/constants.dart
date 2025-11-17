import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFF44336);
  static const Color info = Color(0xFF00BCD4);
  
  static const Color channel1 = Color(0xFF2196F3);
  static const Color channel2 = Color(0xFFFF9800);
  
  static const Color voltageColor = Color(0xFF9C27B0);
  static const Color currentColor = Color(0xFF2196F3);
  static const Color powerColor = Color(0xFF4CAF50);
  static const Color energyColor = Color(0xFFFF9800);
}

class AppConstants {
  // Default server configuration
  static const String defaultServerUrl = 'http://192.168.1.100:3000';
  static const String deviceType = 'CIRQUITIQ';

  // API Endpoints
  static const String apiHealth = '/api/health';
  static const String apiDevices = '/api/devices';
  static const String apiReadings = '/api/readings';
  static const String apiStats = '/api/stats';
  static const String apiCommand = '/api/admin/command';
  static const String apiRelay = '/api/admin/relay';
  static const String apiSystem = '/api/admin/system';
  static const String apiConfig = '/api/admin/config';

  // Storage Keys
  static const String keyServerUrl = 'server_url';
  static const String keyDeviceId = 'device_id';
  static const String keyUsername = 'username';
  static const String keyPassword = 'password';
  static const String keyRememberMe = 'remember_me';

  // Update intervals (milliseconds)
  static const int dataUpdateInterval = 1000;
  static const int chartUpdateInterval = 2000;
  static const int statsUpdateInterval = 5000;

  // Chart settings
  static const int maxDataPoints = 50;
  static const double chartHeight = 200.0;

  // Voltage thresholds (in Volts)
  static const double minNormalVoltage = 210.0;   // Below this = undervoltage warning
  static const double maxNormalVoltage = 235.0;   // Above this = overvoltage warning
  static const double criticalLowVoltage = 200.0;  // Below this = critical undervoltage
  static const double criticalHighVoltage = 245.0; // Above this = critical overvoltage

  // Current thresholds (in Amperes)
  static const double maxNormalCurrent = 12.0;     // Above this = overload warning
  static const double maxWarningCurrent = 15.0;    // Above this = critical overload
  static const double maxCriticalCurrent = 20.0;   // Above this = potential short circuit
}

class DeviceCommands {
  // Relay commands
  static const String relayOn1 = 'on 1';
  static const String relayOn2 = 'on 2';
  static const String relayOnAll = 'on all';
  static const String relayOff1 = 'off 1';
  static const String relayOff2 = 'off 2';
  static const String relayOffAll = 'off all';
  
  // System commands
  static const String reset = 'reset';
  static const String restart = 'restart';
  static const String status = 'status';
  static const String diagnostics = 'diag';
  static const String test = 'test';
  static const String stats = 'stats';
  
  // Settings commands
  static const String calibrate = 'calibrate';
  static const String manual = 'manual';
  static const String safety = 'safety';
  static const String buzzer = 'buzzer';
  static const String clear = 'clear';
}

class AppStrings {
  static const String appName = 'CircuitIQ';
  static const String appTagline = 'Dual Channel Power Monitor';
  
  static const String channel1Label = 'Channel 1';
  static const String channel2Label = 'Channel 2';
  
  static const String voltage = 'Voltage';
  static const String current = 'Current';
  static const String power = 'Power';
  static const String energy = 'Energy';
  static const String cost = 'Cost';
  
  static const String unitVoltage = 'V';
  static const String unitCurrent = 'A';
  static const String unitPower = 'W';
  static const String unitEnergy = 'kWh';
  static const String unitCost = '₱';
  
  static const String relayOn = 'ON';
  static const String relayOff = 'OFF';
  
  static const String connecting = 'Connecting...';
  static const String connected = 'Connected';
  static const String disconnected = 'Disconnected';
  static const String error = 'Error';
  
  static const String login = 'Login';
  static const String logout = 'Logout';
  static const String settings = 'Settings';
  static const String dashboard = 'Dashboard';
  static const String controls = 'Controls';
  static const String statistics = 'Statistics';
  static const String history = 'History';
}

// Voltage status enum
enum VoltageStatus {
  criticalLow,
  low,
  normal,
  high,
  criticalHigh,
}

// Current status enum
enum CurrentStatus {
  normal,
  warning,      // Overload warning
  critical,     // Critical overload
  short,        // Potential short circuit
}

// Helper functions
String formatNumber(double? value, {int decimals = 2}) {
  if (value == null) return '---';
  return value.toStringAsFixed(decimals);
}

String formatDateTime(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}:'
      '${dateTime.second.toString().padLeft(2, '0')}';
}

String getRelayStatusText(bool state) {
  return state ? AppStrings.relayOn : AppStrings.relayOff;
}

Color getRelayStatusColor(bool state) {
  return state ? AppColors.success : AppColors.danger;
}

// Voltage status helpers
VoltageStatus getVoltageStatus(double voltage) {
  if (voltage < AppConstants.criticalLowVoltage) {
    return VoltageStatus.criticalLow;
  } else if (voltage < AppConstants.minNormalVoltage) {
    return VoltageStatus.low;
  } else if (voltage > AppConstants.criticalHighVoltage) {
    return VoltageStatus.criticalHigh;
  } else if (voltage > AppConstants.maxNormalVoltage) {
    return VoltageStatus.high;
  } else {
    return VoltageStatus.normal;
  }
}

Color getVoltageStatusColor(VoltageStatus status) {
  switch (status) {
    case VoltageStatus.criticalLow:
    case VoltageStatus.criticalHigh:
      return AppColors.danger;
    case VoltageStatus.low:
    case VoltageStatus.high:
      return AppColors.warning;
    case VoltageStatus.normal:
      return AppColors.success;
  }
}

String getVoltageStatusText(VoltageStatus status) {
  switch (status) {
    case VoltageStatus.criticalLow:
      return 'CRITICAL UNDERVOLTAGE';
    case VoltageStatus.low:
      return 'UNDERVOLTAGE';
    case VoltageStatus.normal:
      return 'NORMAL';
    case VoltageStatus.high:
      return 'OVERVOLTAGE';
    case VoltageStatus.criticalHigh:
      return 'CRITICAL OVERVOLTAGE';
  }
}

IconData getVoltageStatusIcon(VoltageStatus status) {
  switch (status) {
    case VoltageStatus.criticalLow:
    case VoltageStatus.criticalHigh:
      return Icons.error;
    case VoltageStatus.low:
    case VoltageStatus.high:
      return Icons.warning;
    case VoltageStatus.normal:
      return Icons.check_circle;
  }
}

// Current status helpers
CurrentStatus getCurrentStatus(double current) {
  if (current > AppConstants.maxCriticalCurrent) {
    return CurrentStatus.short;
  } else if (current > AppConstants.maxWarningCurrent) {
    return CurrentStatus.critical;
  } else if (current > AppConstants.maxNormalCurrent) {
    return CurrentStatus.warning;
  } else {
    return CurrentStatus.normal;
  }
}

Color getCurrentStatusColor(CurrentStatus status) {
  switch (status) {
    case CurrentStatus.short:
    case CurrentStatus.critical:
      return AppColors.danger;
    case CurrentStatus.warning:
      return AppColors.warning;
    case CurrentStatus.normal:
      return AppColors.success;
  }
}

String getCurrentStatusText(CurrentStatus status) {
  switch (status) {
    case CurrentStatus.short:
      return 'SHORT CIRCUIT';
    case CurrentStatus.critical:
      return 'CRITICAL OVERLOAD';
    case CurrentStatus.warning:
      return 'OVERLOAD WARNING';
    case CurrentStatus.normal:
      return 'NORMAL';
  }
}

IconData getCurrentStatusIcon(CurrentStatus status) {
  switch (status) {
    case CurrentStatus.short:
      return Icons.flash_on;
    case CurrentStatus.critical:
      return Icons.error;
    case CurrentStatus.warning:
      return Icons.warning;
    case CurrentStatus.normal:
      return Icons.check_circle;
  }
}
