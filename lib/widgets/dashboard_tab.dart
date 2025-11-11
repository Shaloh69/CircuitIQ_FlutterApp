import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/device_provider.dart';
import '../utils/constants.dart';
import '../widgets/metric_card.dart';
import '../widgets/channel_card.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, child) {
        final data = deviceProvider.currentData;
        
        if (data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Waiting for data...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  deviceProvider.isConnected 
                      ? 'Connected • Listening for sensor data'
                      : 'Connecting to server...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => deviceProvider.refreshDevice(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Fetch Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _generateMockData(deviceProvider),
                      icon: const Icon(Icons.science_outlined),
                      label: const Text('Test Data'),
                    ),
                  ],
                ),
                if (deviceProvider.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.danger),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.danger),
                        const SizedBox(height: 8),
                        const Text(
                          'Error loading data',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deviceProvider.error!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: deviceProvider.refreshDevice,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Connection Status Banner
              if (!deviceProvider.isConnected)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, color: AppColors.warning, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'WebSocket Disconnected',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Showing last received data',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Last Update Info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Last Update: ${formatDateTime(data.timestamp)}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () => deviceProvider.refreshDevice(),
                      tooltip: 'Refresh data',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              // Voltage Card
              MetricCard(
                title: 'System Voltage',
                value: formatNumber(data.voltage, decimals: 1),
                unit: AppStrings.unitVoltage,
                icon: Icons.bolt,
                color: AppColors.voltageColor,
              ),
              const SizedBox(height: 16),
              
              // Channel 1
              ChannelCard(
                channelNumber: 1,
                channelData: data.channel1,
                color: AppColors.channel1,
              ),
              const SizedBox(height: 16),
              
              // Channel 2
              ChannelCard(
                channelNumber: 2,
                channelData: data.channel2,
                color: AppColors.channel2,
              ),
              const SizedBox(height: 16),
              
              // Total Power & Energy
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.power,
                            color: AppColors.powerColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total System',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricItem(
                              context,
                              'Total Power',
                              formatNumber(data.totalPower, decimals: 1),
                              AppStrings.unitPower,
                              AppColors.powerColor,
                            ),
                          ),
                          Expanded(
                            child: _buildMetricItem(
                              context,
                              'Total Energy',
                              formatNumber(data.totalEnergy, decimals: 3),
                              AppStrings.unitEnergy,
                              AppColors.energyColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: _buildMetricItem(
                          context,
                          'Total Cost',
                          formatNumber(data.totalCost, decimals: 2),
                          AppStrings.unitCost,
                          AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // System Status
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(),
                      _buildStatusRow('State', data.state, AppColors.info),
                      _buildStatusRow('Sensors', data.sensors, 
                          data.sensors == 'valid' ? AppColors.success : AppColors.warning),
                      _buildStatusRow('Device ID', data.deviceId, AppColors.info),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Real-time Charts
              _buildChartsSection(deviceProvider),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateMockData(DeviceProvider provider) async {
    final success = await provider.generateMockData(count: 1);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Mock data generated successfully' 
                : 'Failed to generate mock data',
          ),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  Widget _buildMetricItem(
    BuildContext context,
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color),
            ),
            child: Text(
              value.toUpperCase(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(DeviceProvider deviceProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-time Charts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Voltage Chart
            _buildChart(
              'Voltage',
              deviceProvider.voltageData,
              AppColors.voltageColor,
              'V',
            ),
            const SizedBox(height: 24),
            
            // Current Chart (Both Channels)
            _buildDualChart(
              'Current',
              deviceProvider.ch1CurrentData,
              deviceProvider.ch2CurrentData,
              AppColors.channel1,
              AppColors.channel2,
              'A',
            ),
            const SizedBox(height: 24),
            
            // Power Chart (Both Channels)
            _buildDualChart(
              'Power',
              deviceProvider.ch1PowerData,
              deviceProvider.ch2PowerData,
              AppColors.channel1,
              AppColors.channel2,
              'W',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(
    String title,
    List<dynamic> data,
    Color color,
    String unit,
  ) {
    if (data.isEmpty) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'Collecting data...',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: const FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: data
                      .asMap()
                      .entries
                      .map((e) => FlSpot(
                            e.key.toDouble(),
                            e.value.value,
                          ))
                      .toList(),
                  isCurved: true,
                  color: color,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDualChart(
    String title,
    List<dynamic> data1,
    List<dynamic> data2,
    Color color1,
    Color color2,
    String unit,
  ) {
    if (data1.isEmpty && data2.isEmpty) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'Collecting data...',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: [
                _buildLegendItem('CH1', color1),
                const SizedBox(width: 16),
                _buildLegendItem('CH2', color2),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: const FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                if (data1.isNotEmpty)
                  LineChartBarData(
                    spots: data1
                        .asMap()
                        .entries
                        .map((e) => FlSpot(
                              e.key.toDouble(),
                              e.value.value,
                            ))
                        .toList(),
                    isCurved: true,
                    color: color1,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                if (data2.isNotEmpty)
                  LineChartBarData(
                    spots: data2
                        .asMap()
                        .entries
                        .map((e) => FlSpot(
                              e.key.toDouble(),
                              e.value.value,
                            ))
                        .toList(),
                    isCurved: true,
                    color: color2,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}