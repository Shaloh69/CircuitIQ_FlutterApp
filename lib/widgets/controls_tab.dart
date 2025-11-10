import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../utils/constants.dart';

class ControlsTab extends StatefulWidget {
  const ControlsTab({super.key});

  @override
  State<ControlsTab> createState() => _ControlsTabState();
}

class _ControlsTabState extends State<ControlsTab> {
  final _commandController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  Future<void> _controlRelay(DeviceProvider provider, int channel, bool turnOn) async {
    setState(() => _isProcessing = true);
    
    final success = await provider.controlRelay(channel, turnOn);
    
    setState(() => _isProcessing = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Channel $channel turned ${turnOn ? "ON" : "OFF"}' 
                : 'Failed to control relay',
          ),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  Future<void> _controlAllRelays(DeviceProvider provider, bool turnOn) async {
    setState(() => _isProcessing = true);
    
    final success = await provider.controlAllRelays(turnOn);
    
    setState(() => _isProcessing = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'All relays turned ${turnOn ? "ON" : "OFF"}' 
                : 'Failed to control relays',
          ),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  Future<void> _sendCommand(DeviceProvider provider, String command) async {
    if (command.isEmpty) return;

    setState(() => _isProcessing = true);
    
    final success = await provider.sendCommand(command);
    
    setState(() => _isProcessing = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Command sent: $command' 
                : 'Failed to send command',
          ),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }

    _commandController.clear();
  }

  Future<void> _systemAction(DeviceProvider provider, String action) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm ${action.toUpperCase()}'),
        content: Text('Are you sure you want to $action the device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    
    bool success = false;
    if (action == 'reset') {
      success = await provider.systemReset();
    } else if (action == 'restart') {
      success = await provider.systemRestart();
    }
    
    setState(() => _isProcessing = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'System ${action}ed successfully' 
                : 'Failed to $action system',
          ),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, child) {
        final data = deviceProvider.currentData;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Quick Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Controls',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing 
                                ? null 
                                : () => _controlAllRelays(deviceProvider, true),
                            icon: const Icon(Icons.power_settings_new),
                            label: const Text('All ON'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing 
                                ? null 
                                : () => _controlAllRelays(deviceProvider, false),
                            icon: const Icon(Icons.power_off),
                            label: const Text('All OFF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Channel 1 Control
            _buildChannelControl(
              context,
              deviceProvider,
              1,
              data?.channel1.relayState ?? false,
              AppColors.channel1,
            ),
            const SizedBox(height: 16),

            // Channel 2 Control
            _buildChannelControl(
              context,
              deviceProvider,
              2,
              data?.channel2.relayState ?? false,
              AppColors.channel2,
            ),
            const SizedBox(height: 16),

            // Custom Command
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custom Command',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    TextField(
                      controller: _commandController,
                      decoration: InputDecoration(
                        hintText: 'Enter command (e.g., status, test, calibrate)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _isProcessing
                              ? null
                              : () => _sendCommand(
                                    deviceProvider,
                                    _commandController.text.trim(),
                                  ),
                        ),
                      ),
                      enabled: !_isProcessing,
                      onSubmitted: _isProcessing
                          ? null
                          : (value) => _sendCommand(deviceProvider, value.trim()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Common Commands
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Common Commands',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildCommandChip('status', Icons.info_outline),
                        _buildCommandChip('test', Icons.science_outlined),
                        _buildCommandChip('calibrate', Icons.tune),
                        _buildCommandChip('stats', Icons.analytics_outlined),
                        _buildCommandChip('manual', Icons.pan_tool_outlined),
                        _buildCommandChip('safety', Icons.shield_outlined),
                        _buildCommandChip('buzzer', Icons.volume_up_outlined),
                        _buildCommandChip('clear', Icons.clear_all),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // System Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Controls',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.restart_alt, color: AppColors.warning),
                      title: const Text('Restart Device'),
                      subtitle: const Text('Restart the ESP32 microcontroller'),
                      trailing: ElevatedButton(
                        onPressed: _isProcessing
                            ? null
                            : () => _systemAction(deviceProvider, 'restart'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                        ),
                        child: const Text('Restart'),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.settings_backup_restore, color: AppColors.danger),
                      title: const Text('Reset System'),
                      subtitle: const Text('Emergency system reset'),
                      trailing: ElevatedButton(
                        onPressed: _isProcessing
                            ? null
                            : () => _systemAction(deviceProvider, 'reset'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChannelControl(
    BuildContext context,
    DeviceProvider provider,
    int channel,
    bool relayState,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Channel $channel',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: getRelayStatusColor(relayState).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: getRelayStatusColor(relayState)),
                  ),
                  child: Text(
                    getRelayStatusText(relayState),
                    style: TextStyle(
                      color: getRelayStatusColor(relayState),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _controlRelay(provider, channel, true),
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text('Turn ON'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _controlRelay(provider, channel, false),
                    icon: const Icon(Icons.power_off),
                    label: const Text('Turn OFF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandChip(String command, IconData icon) {
    return ActionChip(
      label: Text(command),
      avatar: Icon(icon, size: 16),
      onPressed: _isProcessing
          ? null
          : () {
              final provider = Provider.of<DeviceProvider>(context, listen: false);
              _sendCommand(provider, command);
            },
    );
  }
}
