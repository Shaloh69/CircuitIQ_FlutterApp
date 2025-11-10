import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/device_provider.dart';
import '../utils/constants.dart';
import '../widgets/dashboard_tab.dart';
import '../widgets/controls_tab.dart';
import '../widgets/statistics_tab.dart';
import '../widgets/device_selector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

    // Connect WebSocket
    if (authProvider.serverUrl != null) {
      deviceProvider.connectWebSocket(authProvider.serverUrl!);
    }

    // Load devices
    await deviceProvider.loadDevices();

    // Auto-select device if deviceId is set
    if (authProvider.deviceId != null) {
      await deviceProvider.selectDevice(authProvider.deviceId!);
    } else if (deviceProvider.allDevices.isNotEmpty) {
      // Select first device
      await deviceProvider.selectDevice(deviceProvider.allDevices.first.deviceId);
      await authProvider.setDeviceId(deviceProvider.allDevices.first.deviceId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    deviceProvider.disconnectWebSocket();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      
      deviceProvider.disconnectWebSocket();
      deviceProvider.clearData();
      await authProvider.logout();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  void _showDeviceSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const DeviceSelector(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DeviceProvider, AuthProvider>(
      builder: (context, deviceProvider, authProvider, child) {
        final isConnected = deviceProvider.isConnected;
        final selectedDevice = deviceProvider.deviceInfo;
        
        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                const Text('CircuitIQ'),
                if (selectedDevice != null)
                  Text(
                    selectedDevice.deviceId,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            actions: [
              // Connection status
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isConnected ? AppColors.success : AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected ? 'Online' : 'Offline',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Device selector
              if (deviceProvider.allDevices.length > 1)
                IconButton(
                  icon: const Icon(Icons.devices_outlined),
                  onPressed: _showDeviceSelector,
                  tooltip: 'Select Device',
                ),
              // Menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'refresh':
                      deviceProvider.refreshDevice();
                      break;
                    case 'reconnect':
                      if (authProvider.serverUrl != null) {
                        deviceProvider.connectWebSocket(authProvider.serverUrl!);
                      }
                      break;
                    case 'logout':
                      _handleLogout();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: 8),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reconnect',
                    child: Row(
                      children: [
                        Icon(Icons.sync),
                        SizedBox(width: 8),
                        Text('Reconnect'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_outlined), text: 'Dashboard'),
                Tab(icon: Icon(Icons.settings_remote_outlined), text: 'Controls'),
                Tab(icon: Icon(Icons.analytics_outlined), text: 'Stats'),
              ],
            ),
          ),
          body: deviceProvider.selectedDeviceId == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.electrical_services_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Device Selected',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please select a device to monitor',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (deviceProvider.allDevices.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: _showDeviceSelector,
                          icon: const Icon(Icons.devices_outlined),
                          label: const Text('Select Device'),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => deviceProvider.loadDevices(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Devices'),
                        ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: const [
                    DashboardTab(),
                    ControlsTab(),
                    StatisticsTab(),
                  ],
                ),
        );
      },
    );
  }
}
