import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic>? dashboardData;
  Map<String, dynamic>? chartData;
  bool isLoading = true;
  bool isChartLoading = false;
  String selectedParameter = 'vibration';

  // Notification state
  List<NotificationItem> notifications = [];
  int unreadNotificationCount = 0;

  // Bluetooth scanning state
  bool isScanning = false;
  List<ScanResult> availableDevices = <ScanResult>[];
  List<BluetoothDevice> connectedDevices = <BluetoothDevice>[];
  StreamSubscription<List<ScanResult>>? scanSubscription;
  BluetoothAdapterState bluetoothState = BluetoothAdapterState.unknown;

  final List<String> chartParameters = [
    'vibration',
    'magneticflux',
    'rpm',
    'acoustics',
    'temperature',
    'humidity',
    'pressure',
    'altitude',
    'airquality',
    'battery',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadChartData();
    _loadNotifications();
    _requestInitialPermissions();
    _initBluetooth();
  }

  Future<void> _requestInitialPermissions() async {
    // Request permissions on app start
    await _requestAllPermissions();
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initBluetooth() async {
    // Check if Bluetooth is supported
    if (await FlutterBluePlus.isSupported == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bluetooth not supported by this device'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Listen to Bluetooth state changes
    FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        bluetoothState = state;
      });
      if (state == BluetoothAdapterState.off) {
        // Try to turn on Bluetooth which may trigger permission requests
        _requestBluetoothEnable();
      }
    });

    // Get connected devices
    _getConnectedDevices();
  }

  Future<void> _requestBluetoothEnable() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enable Bluetooth manually'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _getConnectedDevices() async {
    try {
      final List<BluetoothDevice> devices =
          await FlutterBluePlus.connectedDevices;
      setState(() {
        connectedDevices = devices;
      });
    } catch (e) {
      print('Error getting connected devices: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    // Get the scanned user ID from memory
    final scannedUserId = ApiService.getScannedUserId();
    final data = await ApiService.getDashboardAndChartData(
      userId: scannedUserId,
      parameter: selectedParameter,
    );
    setState(() {
      dashboardData = data;
      chartData = data; // Same data contains both dashboard and chart info
      isLoading = false;
    });

    // Check for sensor alerts after loading data
    await _checkSensorAlerts();
  }

  Future<void> _loadChartData() async {
    setState(() {
      isChartLoading = true;
    });

    final scannedUserId = ApiService.getScannedUserId();
    final data = await ApiService.getDashboardAndChartData(
      userId: scannedUserId,
      parameter: selectedParameter,
    );

    setState(() {
      chartData = data;
      isChartLoading = false;
    });
  }

  Future<void> _loadNotifications() async {
    final allNotifications = await NotificationService.getAllNotifications();
    final unreadCount = await NotificationService.getUnreadCount();

    setState(() {
      notifications = allNotifications;
      unreadNotificationCount = unreadCount;
    });
  }

  Future<void> _checkSensorAlerts() async {
    if (dashboardData != null) {
      // Check current sensor values against thresholds
      await NotificationService.checkSensorValues(dashboardData!);

      // Reload notifications to get any new alerts
      await _loadNotifications();
    }
  }

  String _getLatestValue(String key, String unit) {
    if (dashboardData == null) {
      return 'N/A';
    }
    if (dashboardData![key] == null) {
      return 'N/A';
    }
    final value = dashboardData![key];
    return '$value $unit';
  }

  Future<void> _scanForDevices() async {
    // Check if Bluetooth is enabled
    if (bluetoothState != BluetoothAdapterState.on) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enable Bluetooth to scan for devices'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Request permissions before scanning
    if (!await _requestBluetoothPermissions()) {
      return;
    }

    setState(() {
      isScanning = true;
      availableDevices.clear();
    });

    try {
      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 10),
        androidUsesFineLocation: true,
      );

      // Listen to scan results
      scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          availableDevices = results;
        });
      });

      // Wait for scan to complete
      await Future.delayed(Duration(seconds: 10));

      setState(() {
        isScanning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found ${availableDevices.length} devices'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        isScanning = false;
      });

      String errorMessage = 'Error scanning: $e';
      if (e.toString().contains('permission') ||
          e.toString().contains('BLUETOOTH_SCAN')) {
        errorMessage =
            'Bluetooth scan permission required.\n\nPlease go to:\nSettings > Apps > MSP > Permissions\nand enable "Nearby devices" or "Location"';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 8),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Future<bool> _requestAllPermissions() async {
    try {
      // Start with basic permissions that work on all Android versions
      List<Permission> permissions = [Permission.location, Permission.storage];

      // Add Bluetooth permissions (available on Android 12+)
      try {
        permissions.addAll([
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ]);
      } catch (e) {
        print('Bluetooth permissions not available on this Android version');
      }

      // Add granular media permissions for Android 13+ if available
      if (await _isAndroid13OrHigher()) {
        try {
          permissions.addAll([
            Permission.photos,
            Permission.videos,
            Permission.audio,
          ]);
        } catch (e) {
          print('Granular media permissions not available');
        }
      }

      // Request permissions
      Map<Permission, PermissionStatus> statuses = await permissions.request();

      // Check critical permissions
      bool locationGranted =
          statuses[Permission.location] == PermissionStatus.granted ||
          statuses[Permission.location] == PermissionStatus.limited;

      // Check Bluetooth permissions if they were requested
      bool bluetoothGranted = true;
      if (statuses.containsKey(Permission.bluetoothScan)) {
        bluetoothGranted =
            (statuses[Permission.bluetoothScan] == PermissionStatus.granted ||
                statuses[Permission.bluetoothScan] ==
                    PermissionStatus.limited) &&
            (statuses[Permission.bluetoothConnect] ==
                    PermissionStatus.granted ||
                statuses[Permission.bluetoothConnect] ==
                    PermissionStatus.limited);
      }

      if (!locationGranted || !bluetoothGranted) {
        _showPermissionDialog();
        return false;
      }

      return true;
    } catch (e) {
      print('Permission request error: $e');
      _showPermissionDialog();
      return false;
    }
  }

  Future<bool> _requestBluetoothPermissions() async {
    return await _requestAllPermissions();
  }

  Future<bool> _isAndroid13OrHigher() async {
    try {
      // Try to check if granular media permissions are available
      await Permission.photos.status;
      return true;
    } catch (e) {
      // If Permission.photos throws an error, we're on older Android
      return false;
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permissions Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This app needs the following permissions to work properly:',
              ),
              SizedBox(height: 12),
              _buildPermissionItem(
                Icons.bluetooth,
                'Bluetooth',
                'To scan and connect to devices',
              ),
              _buildPermissionItem(
                Icons.location_on,
                'Location',
                'Required for Bluetooth scanning',
              ),
              _buildPermissionItem(
                Icons.storage,
                'Storage',
                'To save and access files',
              ),
              SizedBox(height: 12),
              Text(
                'Please grant these permissions in the next dialogs or go to Settings > Apps > MSP > Permissions',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text('Open Settings'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestAllPermissions();
              },
              child: Text('Grant Permissions'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connectToDevice(ScanResult scanResult) async {
    try {
      // Stop scanning before connecting
      await FlutterBluePlus.stopScan();

      // Connect to device
      await scanResult.device.connect();

      // Update connected devices list
      await _getConnectedDevices();

      // Remove from available devices
      setState(() {
        availableDevices.removeWhere(
          (device) => device.device.remoteId == scanResult.device.remoteId,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connected to ${scanResult.device.platformName.isNotEmpty ? scanResult.device.platformName : 'Unknown Device'}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      await _getConnectedDevices();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Disconnected from ${device.platformName.isNotEmpty ? device.platformName : 'Unknown Device'}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to disconnect: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNotificationPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sensor Alerts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      if (notifications.isNotEmpty)
                        TextButton(
                          onPressed: () async {
                            await NotificationService.clearAllNotifications();
                            await _loadNotifications();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Clear All',
                            style: TextStyle(color: Colors.red.shade300),
                          ),
                        ),
                      if (unreadNotificationCount > 0)
                        TextButton(
                          onPressed: () async {
                            await NotificationService.markAllAsRead();
                            await _loadNotifications();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Mark All Read',
                            style: TextStyle(color: Colors.blue.shade300),
                          ),
                        ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Notifications list
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No alerts yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationItem(notification);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    final sensorName = _getSensorDisplayName(notification.sensorType);
    final alertColor = _getAlertColor(notification.alertLevel);
    final timeAgo = _getTimeAgo(notification.timestamp);

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: notification.isRead ? Colors.grey.shade800 : Colors.grey.shade700,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: alertColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _getSensorIcon(notification.sensorType),
            color: alertColor,
            size: 20,
          ),
        ),
        title: Text(
          '$sensorName Alert',
          style: TextStyle(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Value: ${notification.value.toStringAsFixed(1)} ${notification.unit}',
              style: TextStyle(color: Colors.grey.shade300),
            ),
            Text(
              'Threshold: ${notification.threshold.toStringAsFixed(1)} ${notification.unit}',
              style: TextStyle(color: Colors.grey.shade300),
            ),
            Text(
              timeAgo,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.blue.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
        onTap: () async {
          if (!notification.isRead) {
            await NotificationService.markAsRead(notification.id);
            await _loadNotifications();
          }
        },
      ),
    );
  }

  String _getSensorDisplayName(String sensorType) {
    switch (sensorType) {
      case 'vibration':
        return 'Vibration';
      case 'magneticflux':
        return 'Magnetic Flux';
      case 'rpm':
        return 'RPM';
      case 'acoustics':
        return 'Acoustics';
      case 'temperature':
        return 'Temperature';
      case 'humidity':
        return 'Humidity';
      case 'pressure':
        return 'Pressure';
      case 'altitude':
        return 'Altitude';
      case 'airquality':
        return 'Air Quality';
      case 'battery':
        return 'Battery';
      default:
        return sensorType;
    }
  }

  IconData _getSensorIcon(String sensorType) {
    switch (sensorType) {
      case 'vibration':
        return Icons.vibration;
      case 'magneticflux':
        return Icons.explore;
      case 'rpm':
        return Icons.rotate_right;
      case 'acoustics':
        return Icons.speaker;
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'pressure':
        return Icons.compress;
      case 'altitude':
        return Icons.terrain;
      case 'airquality':
        return Icons.air;
      case 'battery':
        return Icons.battery_alert;
      default:
        return Icons.sensors;
    }
  }

  Color _getAlertColor(String alertLevel) {
    switch (alertLevel) {
      case 'veryLow':
        return Colors.green;
      case 'low':
        return Colors.lightGreen;
      case 'medium':
        return Colors.yellow.shade700;
      case 'high':
        return Colors.orange;
      case 'veryHigh':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width >= 600;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Metrics list with name, icon, and live values (latest = first element in arrays)
    final List<Map<String, dynamic>> metrics = [
      {
        'name': 'Vibration',
        'icon': Icons.vibration,
        'value': _getLatestValue('vibration', 'm/s²'),
      },
      {
        'name': 'Magnetic Flux',
        'icon': Icons.explore,
        'value': _getLatestValue('magneticflux', 'µT'),
      },
      {
        'name': 'RPM',
        'icon': Icons.rotate_right,
        'value': _getLatestValue('rpm', 'RPM'),
      },
      {
        'name': 'Acoustics',
        'icon': Icons.speaker,
        'value': _getLatestValue('acoustics', 'dB'),
      },
      {
        'name': 'Temp',
        'icon': Icons.thermostat,
        'value': _getLatestValue('temperature', '°C'),
      },
      {
        'name': 'Humidity',
        'icon': Icons.water_drop,
        'value': _getLatestValue('humidity', '%'),
      },
      {
        'name': 'Pressure',
        'icon': Icons.compress,
        'value': _getLatestValue('pressure', 'hPa'),
      },
      {
        'name': 'Altitude',
        'icon': Icons.terrain,
        'value': _getLatestValue('altitude', 'm'),
      },
      {
        'name': 'Air Quality',
        'icon': Icons.air,
        'value': _getLatestValue('airquality', 'ppm'),
      },
      {
        'name': 'Battery',
        'icon': Icons.battery_full,
        'value': _getLatestValue('battery', '%'),
      },
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard', style: TextStyle(color: Colors.white)),
            Text(
              'Device ID: ${ApiService.getScannedUserId() ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              _loadDashboardData();
              _loadChartData();
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                ),
                onPressed: () {
                  _showNotificationPanel();
                },
              ),
              if (unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$unreadNotificationCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.bluetooth_searching_sharp,
              color: Colors.white,
            ),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: isTablet
            ? Column(
                children: [
                  // Tablet layout - 2x2 grid
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Expanded(child: buildMetricsSection(metrics)),
                        Expanded(child: buildSection2()),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Expanded(child: buildSection3()),
                        Expanded(child: buildSection4()),
                      ],
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(screenSize.width < 350 ? 2.0 : 4.0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Mobile layout - single column with dynamic heights
                    buildMetricsSection(metrics),
                    SizedBox(height: screenSize.width < 350 ? 4 : 6),
                    SizedBox(
                      height: screenSize.width < 350 ? 140 : 240,
                      child: buildSection2(),
                    ),
                    SizedBox(height: screenSize.width < 350 ? 4 : 6),
                    SizedBox(
                      height: screenSize.width < 350 ? 240 : 280,
                      child: buildSection3(),
                    ),
                    SizedBox(height: screenSize.width < 350 ? 4 : 6),
                    SizedBox(
                      height: screenSize.width < 350 ? 240 : 280,
                      child: buildSection4(),
                    ),
                    SizedBox(
                      height: screenSize.width < 350 ? 8 : 12,
                    ), // Bottom padding
                  ],
                ),
              ),
      ),
      endDrawer: _buildBluetoothSidebar(),
    );
  }

  // Widget for metrics grid section
  Widget buildMetricsSection(List<Map<String, dynamic>> metrics) {
    // Responsive breakpoints
    final double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;

    // Dynamic grid configuration - much smaller cards for mobile
    int crossAxisCount = 2;
    double childAspectRatio = 1.5;
    double iconSize = 32;
    double titleFontSize = 16;
    double valueFontSize = 20;
    EdgeInsets cardPadding = const EdgeInsets.all(8.0);

    if (screenWidth < 350) {
      // Very small mobile phones - very small cards
      crossAxisCount = 3;
      childAspectRatio = 2.5;
      iconSize = 20;
      titleFontSize = 10;
      valueFontSize = 14;
      cardPadding = const EdgeInsets.all(2.0);
    } else if (screenWidth < 400) {
      // Small mobile phones - small cards
      crossAxisCount = 3;
      childAspectRatio = 2.2;
      iconSize = 22;
      titleFontSize = 12;
      valueFontSize = 16;
      cardPadding = const EdgeInsets.all(4.0);
    } else if (screenWidth < 600) {
      // Regular mobile phones - compact cards
      crossAxisCount = 2;
      childAspectRatio = 1.8;
      iconSize = 26;
      titleFontSize = 14;
      valueFontSize = 18;
      cardPadding = const EdgeInsets.all(6.0);
    } else if (screenWidth < 900) {
      // Tablets portrait
      crossAxisCount = 3;
      childAspectRatio = 1.0;
      iconSize = 40;
      titleFontSize = 18;
      valueFontSize = 22;
      cardPadding = const EdgeInsets.all(12.0);
    } else {
      // Tablets landscape / Desktop
      crossAxisCount = 3;
      childAspectRatio = 1.0;
      iconSize = 44;
      titleFontSize = 20;
      valueFontSize = 24;
      cardPadding = const EdgeInsets.all(16.0);
    }

    // Calculate grid height for mobile layout
    final rows = (metrics.length / crossAxisCount).ceil();
    final itemWidth =
        (screenWidth -
            (isMobile ? 16.0 : 32.0) -
            ((crossAxisCount - 1) * (isMobile ? 8 : 12))) /
        crossAxisCount;
    final itemHeight = itemWidth / childAspectRatio;
    final gridHeight =
        (itemHeight * rows) + ((rows - 1) * (isMobile ? 4 : 12)) + 40;

    return Container(
      margin: EdgeInsets.all(isMobile ? 4.0 : 8.0),
      child: Card(
        elevation: 4,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: isMobile ? 6 : 8,
                crossAxisSpacing: isMobile ? 6 : 8,
                childAspectRatio: childAspectRatio,
                children: metrics.map((metric) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0x33262626), // 20% opacity
                          const Color(0x33ababab),
                          const Color(0x33272727),
                        ],
                      ),

                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFFFFF),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 4.0 : 12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            metric['icon'],
                            size: iconSize,
                            color: Colors.blueAccent,
                          ),
                          SizedBox(height: isMobile ? 2 : 8),
                          Text(
                            metric['name'],
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isMobile ? 1 : 6),
                          Text(
                            metric['value'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: valueFontSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueAccent[300],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for section 2
  Widget buildSection2() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Container(
      margin: EdgeInsets.all(isMobile ? 4.0 : 8.0),

      child: Card(
        elevation: 4,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
          child: isMobile
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildBox('Box 1', _getBoxColor('Box 1')),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildBox('Box 2', _getBoxColor('Box 2')),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildBox('Box 3', _getBoxColor('Box 3')),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildBox('Box 4', _getBoxColor('Box 4')),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildBox('Box 1', _getBoxColor('Box 1')),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildBox('Box 2', _getBoxColor('Box 2')),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildBox('Box 3', _getBoxColor('Box 3')),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildBox('Box 4', _getBoxColor('Box 4')),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBox(String title, Color statusColor) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 900;

    // Get analytics data based on box title
    Map<String, dynamic> boxData = _getBoxAnalytics(title);

    // Responsive font sizes - OPTIMIZED FOR MOBILE
    double titleFontSize = isMobile ? 14 : (isTablet ? 16 : 18);
    double valueFontSize = isMobile ? 18 : (isTablet ? 20 : 24);
    double subtitleFontSize = isMobile ? 11 : (isTablet ? 12 : 14);
    double dotSize = isMobile ? 8 : (isTablet ? 8 : 10);
    double padding = isMobile ? 12.0 : (isTablet ? 12.0 : 16.0);

    return Container(
      height: isMobile
          ? 100
          : null, // Set specific height for each box on mobile
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2A2A2A),
            const Color(0xFF3A3A3A),
            Colors.blueAccent.withValues(alpha: 0.3),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status indicator dot
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.5),
                    blurRadius: 2,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 4 : 6),
            // Title
            Flexible(
              child: Text(
                boxData['title'] ?? title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: isMobile ? 2 : 4),
            // Value
            Flexible(
              child: Text(
                boxData['value'] ?? 'N/A',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Subtitle
            if (boxData['subtitle'] != null) ...[
              SizedBox(height: isMobile ? 2 : 4),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 4 : 6,
                    vertical: isMobile ? 2 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    boxData['subtitle'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBoxColor(String boxTitle) {
    if (dashboardData == null) {
      return Colors.grey;
    }

    switch (boxTitle) {
      case 'Box 1':
        // Temperature color coding
        final temp = dashboardData!['temperature'];
        if (temp != null) {
          double tempValue = double.tryParse(temp.toString()) ?? 0.0;
          if (tempValue > 40) {
            return Colors.red; // High temperature
          } else if (tempValue < 10) {
            return Colors.blue; // Low temperature
          } else {
            return Colors.green; // Normal temperature
          }
        }
        return Colors.grey; // No data

      case 'Box 2':
        // RPM color coding
        final rpm = dashboardData!['rpm'];
        if (rpm != null) {
          double rpmValue = double.tryParse(rpm.toString()) ?? 0.0;
          if (rpmValue > 2000) {
            return Colors.orange; // High RPM
          } else if (rpmValue < 500) {
            return Colors.blue; // Low RPM
          } else {
            return Colors.green; // Normal RPM
          }
        }
        return Colors.grey; // No data

      case 'Box 3':
        // Air Quality color coding
        final airQuality = dashboardData!['airquality'];
        if (airQuality != null) {
          double aqValue = double.tryParse(airQuality.toString()) ?? 0.0;
          if (aqValue > 500) {
            return Colors.red; // Poor air quality
          } else if (aqValue > 300) {
            return Colors.orange; // Moderate air quality
          } else {
            return Colors.green; // Good air quality
          }
        }
        return Colors.grey; // No data

      case 'Box 4':
        // Engine Status color coding
        final vibration = dashboardData!['vibration'];
        if (vibration != null) {
          double vibValue = double.tryParse(vibration.toString()) ?? 0.0;
          if (vibValue > 10) {
            return Colors.red; // Engine failure
          } else {
            return Colors.green; // Engine stable
          }
        }
        return Colors.grey; // No data

      default:
        return Colors.grey;
    }
  }

  Map<String, dynamic> _getBoxAnalytics(String boxTitle) {
    if (dashboardData == null) {
      return {'title': boxTitle, 'value': 'Loading...'};
    }

    switch (boxTitle) {
      case 'Box 1':
        // Temperature Analysis
        final temp = dashboardData!['temperature'];
        String status = 'No Data';
        if (temp != null) {
          double tempValue = double.tryParse(temp.toString()) ?? 0.0;
          if (tempValue > 40) {
            status = 'High';
          } else if (tempValue < 10) {
            status = 'Low';
          } else {
            status = 'Normal';
          }
        }
        return {
          'title': 'Temperature',
          'value': '${temp ?? 'N/A'}°C',
          'subtitle': status,
        };

      case 'Box 2':
        // RPM Analysis
        final rpm = dashboardData!['rpm'];
        String status = 'No Data';
        if (rpm != null) {
          double rpmValue = double.tryParse(rpm.toString()) ?? 0.0;
          if (rpmValue > 2000) {
            status = 'High Speed';
          } else if (rpmValue < 500) {
            status = 'Low Speed';
          } else {
            status = 'Normal';
          }
        }
        return {'title': 'RPM', 'value': '${rpm ?? 'N/A'}', 'subtitle': status};

      case 'Box 3':
        final airQuality = dashboardData!['airquality'];
        String status = 'No Data';

        if (airQuality != null) {
          double aqValue = double.tryParse(airQuality.toString()) ?? 0.0;
          if (aqValue > 500) {
            status = 'Poor';
          } else if (aqValue > 300) {
            status = 'Moderate';
          } else {
            status = 'Good';
          }
        }

        return {
          'title': 'Air Quality',
          'value': airQuality != null ? '${airQuality} ppm' : 'N/A',
          'subtitle': status,
        };

      case 'Box 4':
        // Engine Status based on vibration
        final vibration = dashboardData?['vibration'];
        String status = 'N/A';
        String statusText = 'No Data';

        if (vibration != null) {
          double vibValue = double.tryParse(vibration.toString()) ?? 0.0;
          if (vibValue > 10) {
            status = 'FAILURE';
            statusText = 'Engine Failure';
          } else if (vibValue >= 0) {
            status = 'Stable';
            statusText = 'Engine Running Stable';
          }
        }

        return {
          'title': 'Engine Status',
          'value': status,
          'subtitle': statusText,
        };

      default:
        return {'title': boxTitle, 'value': 'N/A'};
    }
  }

  // Helper method for section 3 - Data Table
  Widget buildSection3() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final allData = dashboardData?['allData'] as List<dynamic>? ?? [];

    if (allData.isEmpty) {
      return Container(
        margin: EdgeInsets.all(isMobile ? 4.0 : 8.0),
        child: Card(
          color: const Color(0xFF1E1E1E),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
            child: Center(
              child: Text(
                'No data available',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Get column headers from the first data item
    final firstItem = allData.first as Map<String, dynamic>;
    final columns = firstItem.keys.toList();

    return Container(
      margin: EdgeInsets.all(isMobile ? 4.0 : 8.0),
      child: Card(
        elevation: 4,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 6.0 : 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
                child: Text(
                  'All Data Records',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: isMobile ? 8 : 12,
                      horizontalMargin: isMobile ? 4 : 8,
                      columns: columns.map((column) {
                        return DataColumn(
                          label: Text(
                            column.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                      rows: allData.map((item) {
                        final dataItem = item as Map<String, dynamic>;
                        return DataRow(
                          cells: columns.map((column) {
                            return DataCell(
                              Text(
                                dataItem[column]?.toString() ?? 'N/A',
                                style: TextStyle(
                                  fontSize: isMobile ? 13 : 15,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for section 4
  Widget buildSection4() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Container(
      margin: EdgeInsets.all(isMobile ? 4.0 : 8.0),
      child: Card(
        elevation: 4,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Chart Data',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade600),
                      borderRadius: BorderRadius.circular(6),
                      color: const Color(0xFF2A2A2A),
                    ),
                    child: DropdownButton<String>(
                      value: selectedParameter,
                      underline: const SizedBox(),
                      isDense: true,
                      dropdownColor: const Color(0xFF2A2A2A),
                      items: chartParameters.map((String parameter) {
                        return DropdownMenuItem<String>(
                          value: parameter,
                          child: Text(
                            parameter,
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 12,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedParameter = newValue;
                          });
                          _loadChartData();
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 8 : 16),
              Expanded(
                child: isChartLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _buildChart(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (chartData == null || chartData!['chartPoints'] == null) {
      return const Center(
        child: Text(
          'No chart data available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final List<dynamic> chartPoints = chartData!['chartPoints'];
    if (chartPoints.isEmpty) {
      return const Center(
        child: Text(
          'No data points available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    List<FlSpot> spots = [];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < chartPoints.length; i++) {
      final point = chartPoints[i] as Map<String, dynamic>;
      final x = point['x'] as double? ?? i.toDouble();
      final y = point['y'] as double? ?? 0.0;
      spots.add(FlSpot(x, y));

      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    if (spots.isEmpty) {
      return const Center(
        child: Text(
          'No valid data for selected parameter',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Add some padding to the Y axis range
    final yRange = maxY - minY;
    final yPadding = yRange > 0 ? yRange * 0.1 : 1.0;
    final adjustedMinY = minY - yPadding;
    final adjustedMaxY = maxY + yPadding;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: (maxY - minY) / 5,
          verticalInterval: spots.length > 10 ? spots.length / 5 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade600, strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: Colors.grey.shade600, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < chartPoints.length) {
                  return Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade600),
        ),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: adjustedMinY,
        maxY: adjustedMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.blueAccent,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blueAccent.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < chartPoints.length) {
                  final point = chartPoints[index] as Map<String, dynamic>;
                  return LineTooltipItem(
                    '${selectedParameter.toUpperCase()}\nValue: ${spot.y.toStringAsFixed(2)}\nPoint: ${index + 1}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: (adjustedMaxY - adjustedMinY) > 0
              ? (adjustedMaxY - adjustedMinY) / 5
              : 1,
          verticalInterval: spots.length > 1 ? (spots.length - 1) / 5 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade600, strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: Colors.grey.shade600, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < chartPoints.length) {
                  return Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade600),
        ),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: adjustedMinY,
        maxY: adjustedMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.blueAccent,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blueAccent.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < chartPoints.length) {
                  final point = chartPoints[index] as Map<String, dynamic>;
                  return LineTooltipItem(
                    '${selectedParameter.toUpperCase()}\nValue: ${spot.y.toStringAsFixed(2)}\nPoint: ${index + 1}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBluetoothSidebar() {
    return Drawer(
      width: 300,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade900, Colors.grey.shade800],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.grey.shade800, Colors.grey.shade900],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bluetooth, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bluetooth Devices',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage connected sensors',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content - Made scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12.0), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Added to prevent overflow
                  children: [
                    // Scan button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isScanning ? null : _scanForDevices,
                        icon: Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 18,
                        ), // Reduced icon size
                        label: Text(
                          isScanning ? 'Scanning...' : 'Scan for Devices',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: EdgeInsets.symmetric(
                            vertical: 10,
                          ), // Reduced padding
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16), // Reduced spacing
                    // Connected devices section
                    Text(
                      'Connected Devices',
                      style: TextStyle(
                        fontSize: 16, // Reduced font size
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 12),
                    // Connected devices list
                    ...connectedDevices
                        .map((device) => _buildConnectedDeviceItem(device))
                        .toList(),

                    // Available devices section
                    if (availableDevices.isNotEmpty) ...[
                      SizedBox(height: 24),
                      Text(
                        'Available Devices',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12),
                      ...availableDevices
                          .map(
                            (scanResult) =>
                                _buildAvailableDeviceItem(scanResult),
                          )
                          .toList(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceItem(
    String name,
    String status,
    IconData icon,
    Color statusColor,
    bool isConnected,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 6), // Reduced margin
      elevation: 2,
      color: Colors.grey.shade800,
      child: ListTile(
        dense: true, // Make ListTile more compact
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ), // Reduced padding
        leading: CircleAvatar(
          radius: 18, // Smaller avatar
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(icon, color: statusColor, size: 18), // Smaller icon
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white,
          ), // Reduced font size
          overflow: TextOverflow.ellipsis, // Handle long text
        ),
        subtitle: Row(
          children: [
            Container(
              width: 6, // Smaller dot
              height: 6,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6), // Reduced spacing
            Expanded(
              // Added Expanded to prevent overflow
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11, // Reduced font size
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis, // Handle long text
              ),
            ),
          ],
        ),
        trailing: isConnected
            ? IconButton(
                icon: Icon(
                  Icons.settings,
                  size: 18,
                  color: Colors.white70,
                ), // Smaller icon
                padding: EdgeInsets.all(4), // Reduced padding
                constraints: BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ), // Smaller button
                onPressed: () {
                  // Device settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening $name settings...')),
                  );
                },
              )
            : IconButton(
                icon: Icon(
                  Icons.refresh,
                  size: 18,
                  color: Colors.white70,
                ), // Smaller icon
                padding: EdgeInsets.all(4), // Reduced padding
                constraints: BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ), // Smaller button
                onPressed: () {
                  // Reconnect device
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reconnecting to $name...')),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildConnectedDeviceItem(BluetoothDevice device) {
    final deviceName = device.platformName.isNotEmpty
        ? device.platformName
        : 'Unknown Device';

    return Card(
      margin: EdgeInsets.only(bottom: 6),
      elevation: 2,
      color: Colors.grey.shade800,
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          child: Icon(Icons.bluetooth_connected, color: Colors.green, size: 18),
        ),
        title: Text(
          deviceName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Connected • ${device.remoteId}',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.settings, size: 18, color: Colors.white70),
          padding: EdgeInsets.all(4),
          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening $deviceName settings...')),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvailableDeviceItem(ScanResult scanResult) {
    final device = scanResult.device;
    final deviceName = device.platformName.isNotEmpty
        ? device.platformName
        : 'Unknown Device';
    final rssi = scanResult.rssi;

    return Card(
      margin: EdgeInsets.only(bottom: 6),
      elevation: 2,
      color: Colors.grey.shade800,
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: Icon(Icons.bluetooth, color: Colors.blue, size: 18),
        ),
        title: Text(
          deviceName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Available • Signal: ${rssi} dBm',
                style: TextStyle(color: Colors.grey.shade300, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _connectToDevice(scanResult),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size(60, 28),
          ),
          child: Text(
            'Connect',
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
      ),
    );
  }
}
