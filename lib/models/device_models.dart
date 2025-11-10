class ChannelData {
  final double current;
  final double power;
  final double energy;
  final double cost;
  final bool relayState;

  ChannelData({
    required this.current,
    required this.power,
    required this.energy,
    required this.cost,
    required this.relayState,
  });

  factory ChannelData.fromJson(Map<String, dynamic> json) {
    return ChannelData(
      current: (json['current'] ?? 0.0).toDouble(),
      power: (json['power'] ?? 0.0).toDouble(),
      energy: (json['energy'] ?? 0.0).toDouble(),
      cost: (json['cost'] ?? 0.0).toDouble(),
      relayState: json['relayState'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'power': power,
      'energy': energy,
      'cost': cost,
      'relayState': relayState,
    };
  }

  ChannelData copyWith({
    double? current,
    double? power,
    double? energy,
    double? cost,
    bool? relayState,
  }) {
    return ChannelData(
      current: current ?? this.current,
      power: power ?? this.power,
      energy: energy ?? this.energy,
      cost: cost ?? this.cost,
      relayState: relayState ?? this.relayState,
    );
  }
}

class DeviceData {
  final String deviceId;
  final String deviceType;
  final double voltage;
  final String state;
  final String sensors;
  final ChannelData channel1;
  final ChannelData channel2;
  final double totalPower;
  final double totalEnergy;
  final double totalCost;
  final DateTime timestamp;

  DeviceData({
    required this.deviceId,
    required this.deviceType,
    required this.voltage,
    required this.state,
    required this.sensors,
    required this.channel1,
    required this.channel2,
    required this.totalPower,
    required this.totalEnergy,
    required this.totalCost,
    required this.timestamp,
  });

  factory DeviceData.fromJson(Map<String, dynamic> json) {
    return DeviceData(
      deviceId: json['deviceId'] ?? '',
      deviceType: json['deviceType'] ?? 'CIRQUITIQ',
      voltage: (json['voltage'] ?? 0.0).toDouble(),
      state: json['state'] ?? 'unknown',
      sensors: json['sensors'] ?? 'unknown',
      channel1: ChannelData.fromJson(json['channel1'] ?? {}),
      channel2: ChannelData.fromJson(json['channel2'] ?? {}),
      totalPower: (json['totalPower'] ?? 0.0).toDouble(),
      totalEnergy: (json['totalEnergy'] ?? 0.0).toDouble(),
      totalCost: (json['totalCost'] ?? 0.0).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceType': deviceType,
      'voltage': voltage,
      'state': state,
      'sensors': sensors,
      'channel1': channel1.toJson(),
      'channel2': channel2.toJson(),
      'totalPower': totalPower,
      'totalEnergy': totalEnergy,
      'totalCost': totalCost,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class DeviceInfo {
  final String deviceId;
  final String deviceType;
  final String ip;
  final DateTime connectedAt;
  final DateTime lastSeen;
  final bool isMock;
  final DeviceData? currentData;

  DeviceInfo({
    required this.deviceId,
    required this.deviceType,
    required this.ip,
    required this.connectedAt,
    required this.lastSeen,
    this.isMock = false,
    this.currentData,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['deviceId'] ?? '',
      deviceType: json['deviceType'] ?? 'CIRQUITIQ',
      ip: json['ip'] ?? '',
      connectedAt: json['connectedAt'] != null
          ? DateTime.parse(json['connectedAt'])
          : DateTime.now(),
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : DateTime.now(),
      isMock: json['isMock'] ?? false,
      currentData: json['currentData'] != null
          ? DeviceData.fromJson(json['currentData'])
          : null,
    );
  }
}

class CommandHistory {
  final String deviceId;
  final String command;
  final String source;
  final bool success;
  final DateTime timestamp;

  CommandHistory({
    required this.deviceId,
    required this.command,
    required this.source,
    required this.success,
    required this.timestamp,
  });

  factory CommandHistory.fromJson(Map<String, dynamic> json) {
    return CommandHistory(
      deviceId: json['deviceId'] ?? '',
      command: json['command'] ?? '',
      source: json['source'] ?? '',
      success: json['success'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

class Statistics {
  final int totalReadings;
  final VoltageStats voltage;
  final ChannelStats channel1;
  final ChannelStats channel2;

  Statistics({
    required this.totalReadings,
    required this.voltage,
    required this.channel1,
    required this.channel2,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      totalReadings: json['totalReadings'] ?? 0,
      voltage: VoltageStats.fromJson(json['voltage'] ?? {}),
      channel1: ChannelStats.fromJson(json['channel1'] ?? {}),
      channel2: ChannelStats.fromJson(json['channel2'] ?? {}),
    );
  }
}

class VoltageStats {
  final double min;
  final double max;
  final double avg;

  VoltageStats({
    required this.min,
    required this.max,
    required this.avg,
  });

  factory VoltageStats.fromJson(Map<String, dynamic> json) {
    return VoltageStats(
      min: (json['min'] ?? 0.0).toDouble(),
      max: (json['max'] ?? 0.0).toDouble(),
      avg: (json['avg'] ?? 0.0).toDouble(),
    );
  }
}

class ChannelStats {
  final double avgCurrent;
  final double avgPower;
  final double totalEnergy;

  ChannelStats({
    required this.avgCurrent,
    required this.avgPower,
    required this.totalEnergy,
  });

  factory ChannelStats.fromJson(Map<String, dynamic> json) {
    return ChannelStats(
      avgCurrent: (json['avgCurrent'] ?? 0.0).toDouble(),
      avgPower: (json['avgPower'] ?? 0.0).toDouble(),
      totalEnergy: (json['totalEnergy'] ?? 0.0).toDouble(),
    );
  }
}

class ChartDataPoint {
  final DateTime time;
  final double value;

  ChartDataPoint(this.time, this.value);
}
