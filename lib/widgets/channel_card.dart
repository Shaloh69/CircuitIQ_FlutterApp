import 'package:flutter/material.dart';
import '../models/device_models.dart';
import '../utils/constants.dart';

class ChannelCard extends StatelessWidget {
  final int channelNumber;
  final ChannelData channelData;
  final Color color;
  final CurrentStatus? currentStatus;

  const ChannelCard({
    super.key,
    required this.channelNumber,
    required this.channelData,
    required this.color,
    this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.electrical_services,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Channel $channelNumber',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: getRelayStatusColor(channelData.relayState).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: getRelayStatusColor(channelData.relayState),
                    ),
                  ),
                  child: Text(
                    getRelayStatusText(channelData.relayState),
                    style: TextStyle(
                      color: getRelayStatusColor(channelData.relayState),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            // Current status indicator (if abnormal)
            if (currentStatus != null && currentStatus != CurrentStatus.normal)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: getCurrentStatusColor(currentStatus!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: getCurrentStatusColor(currentStatus!),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      getCurrentStatusIcon(currentStatus!),
                      color: getCurrentStatusColor(currentStatus!),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      getCurrentStatusText(currentStatus!),
                      style: TextStyle(
                        color: getCurrentStatusColor(currentStatus!),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    context,
                    'Current',
                    formatNumber(channelData.current, decimals: 3),
                    AppStrings.unitCurrent,
                    currentStatus != null && currentStatus != CurrentStatus.normal
                        ? getCurrentStatusColor(currentStatus!)
                        : AppColors.currentColor,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    context,
                    'Power',
                    formatNumber(channelData.power, decimals: 1),
                    AppStrings.unitPower,
                    AppColors.powerColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    context,
                    'Energy',
                    formatNumber(channelData.energy, decimals: 3),
                    AppStrings.unitEnergy,
                    AppColors.energyColor,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    context,
                    'Cost',
                    formatNumber(channelData.cost, decimals: 2),
                    AppStrings.unitCost,
                    AppColors.info,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context,
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
}
