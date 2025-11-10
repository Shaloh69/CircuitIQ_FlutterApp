import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../utils/constants.dart';

class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DeviceProvider>(context, listen: false).loadStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, child) {
        final stats = deviceProvider.statistics;

        if (stats == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Loading statistics...'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => deviceProvider.loadStatistics(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => deviceProvider.loadStatistics(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statistics Summary',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(),
                      _buildSummaryRow('Total Readings', stats.totalReadings.toString()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Voltage Statistics
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt, color: AppColors.voltageColor),
                          const SizedBox(width: 8),
                          Text(
                            'Voltage Statistics',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildStatRow('Minimum', formatNumber(stats.voltage.min, decimals: 1), 'V'),
                      _buildStatRow('Maximum', formatNumber(stats.voltage.max, decimals: 1), 'V'),
                      _buildStatRow('Average', formatNumber(stats.voltage.avg, decimals: 1), 'V'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Channel 1 Statistics
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics, color: AppColors.channel1),
                          const SizedBox(width: 8),
                          Text(
                            'Channel 1 Statistics',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildStatRow(
                        'Avg Current',
                        formatNumber(stats.channel1.avgCurrent, decimals: 3),
                        'A',
                      ),
                      _buildStatRow(
                        'Avg Power',
                        formatNumber(stats.channel1.avgPower, decimals: 1),
                        'W',
                      ),
                      _buildStatRow(
                        'Total Energy',
                        formatNumber(stats.channel1.totalEnergy, decimals: 3),
                        'kWh',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Channel 2 Statistics
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics, color: AppColors.channel2),
                          const SizedBox(width: 8),
                          Text(
                            'Channel 2 Statistics',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildStatRow(
                        'Avg Current',
                        formatNumber(stats.channel2.avgCurrent, decimals: 3),
                        'A',
                      ),
                      _buildStatRow(
                        'Avg Power',
                        formatNumber(stats.channel2.avgPower, decimals: 1),
                        'W',
                      ),
                      _buildStatRow(
                        'Total Energy',
                        formatNumber(stats.channel2.totalEnergy, decimals: 3),
                        'kWh',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(width: 4),
              Text(unit, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}
