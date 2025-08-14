import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? dashboardData;
  Map<String, dynamic>? chartData;
  bool isLoading = true;
  bool isChartLoading = false;
  String selectedParameter = 'vibration';

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
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadChartData();
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
        'name': 'Temperature',
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
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard'),
            Text(
              'User ID: ${ApiService.getScannedUserId() ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              _loadDashboardData();
              _loadChartData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/qrpage');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
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
                    SizedBox(height: screenSize.width < 350 ? 6 : 8),
                    SizedBox(
                      height: screenSize.width < 350 ? 140 : 240,
                      child: buildSection2(),
                    ),
                    SizedBox(height: screenSize.width < 350 ? 6 : 8),
                    SizedBox(
                      height: screenSize.width < 350 ? 280 : 320,
                      child: buildSection3(),
                    ),
                    SizedBox(height: screenSize.width < 350 ? 6 : 8),
                    SizedBox(
                      height: screenSize.width < 350 ? 280 : 320,
                      child: buildSection4(),
                    ),
                    SizedBox(
                      height: screenSize.width < 350 ? 12 : 16,
                    ), // Bottom padding
                  ],
                ),
              ),
      ),
    );
  }

  // Widget for metrics grid section
  Widget buildMetricsSection(List<Map<String, dynamic>> metrics) {
    // Responsive breakpoints
    final double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;

    // Dynamic grid configuration based on screen size - INCREASED FONT SIZES
    int crossAxisCount = 2;
    double childAspectRatio = 1.1;
    double iconSize = 24;
    double titleFontSize = 14;
    double valueFontSize = 16;
    EdgeInsets cardPadding = const EdgeInsets.all(8.0);

    if (screenWidth < 350) {
      // Very small mobile phones - INCREASED SIZES
      crossAxisCount = 2;
      childAspectRatio = 1.0;
      iconSize = 22;
      titleFontSize = 12;
      valueFontSize = 14;
      cardPadding = const EdgeInsets.all(6.0);
    } else if (screenWidth < 400) {
      // Small mobile phones - INCREASED SIZES
      crossAxisCount = 2;
      childAspectRatio = 1.1;
      iconSize = 26;
      titleFontSize = 14;
      valueFontSize = 16;
      cardPadding = const EdgeInsets.all(8.0);
    } else if (screenWidth < 600) {
      // Regular mobile phones - INCREASED SIZES
      crossAxisCount = 2;
      childAspectRatio = 1.2;
      iconSize = 30;
      titleFontSize = 16;
      valueFontSize = 18;
      cardPadding = const EdgeInsets.all(10.0);
    } else if (screenWidth < 900) {
      // Tablets portrait - INCREASED SIZES
      crossAxisCount = 3;
      childAspectRatio = 1.3;
      iconSize = 32;
      titleFontSize = 16;
      valueFontSize = 18;
      cardPadding = const EdgeInsets.all(12.0);
    } else {
      // Tablets landscape / Desktop - INCREASED SIZES
      crossAxisCount = 5;
      childAspectRatio = .9;
      iconSize = 32;
      titleFontSize = 16;
      valueFontSize = 18;
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
        (itemHeight * rows) +
        ((rows - 1) * (isMobile ? 8 : 12)) +
        40; // 40 for padding

    return Container(
      margin: EdgeInsets.all(isMobile ? 4.0 : 8.0),
      height: isMobile ? gridHeight : null, // Set height only for mobile
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: isMobile ? 8 : 12,
                  crossAxisSpacing: isMobile ? 8 : 12,
                  childAspectRatio: childAspectRatio,
                  children: metrics.map((metric) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade50,
                            Colors.blue.shade100,
                            Colors.blueAccent.withValues(alpha: 0.15),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blueAccent.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            blurRadius: 2,
                            offset: const Offset(0, -1),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 6.0 : 8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              metric['icon'],
                              size: iconSize,
                              color: Colors.blueAccent,
                            ),
                            SizedBox(height: isMobile ? 4 : 6),
                            Flexible(
                              child: Text(
                                metric['name'],
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: isMobile ? 2 : 4),
                            Flexible(
                              child: Text(
                                metric['value'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: valueFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueAccent[700],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
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
        color: Colors.white,
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
            Colors.blue.shade50,
            Colors.blue.shade100,
            Colors.blueAccent.withValues(alpha: 0.15),
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
                  color: Colors.blueGrey.shade800,
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
                  color: Colors.blueGrey.shade900,
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
                      color: statusColor.withValues(alpha: 0.9),
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
          }
        }
        return Colors.green; // Normal temperature

      case 'Box 2':
        // RPM color coding
        final rpm = dashboardData!['rpm'];
        if (rpm != null) {
          double rpmValue = double.tryParse(rpm.toString()) ?? 0.0;
          if (rpmValue > 2000) {
            return Colors.orange; // High RPM
          } else if (rpmValue < 500) {
            return Colors.blue; // Low RPM
          }
        }
        return Colors.green; // Normal RPM

      case 'Box 3':
        // Air Quality color coding
        final airQuality = dashboardData!['airquality'];
        if (airQuality != null) {
          double aqValue = double.tryParse(airQuality.toString()) ?? 0.0;
          if (aqValue > 500) {
            return Colors.red; // Poor air quality
          } else if (aqValue > 300) {
            return Colors.orange; // Moderate air quality
          }
        }
        return Colors.green; // Good air quality

      case 'Box 4':
        // Engine Status color coding
        final vibration = dashboardData!['vibration'];
        if (vibration != null) {
          double vibValue = double.tryParse(vibration.toString()) ?? 0.0;
          if (vibValue > 10) {
            return Colors.red; // Engine failure
          }
        }
        return Colors.green; // Engine stable

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
        String status = 'Normal';
        if (temp != null) {
          double tempValue = double.tryParse(temp.toString()) ?? 0.0;
          if (tempValue > 40) {
            status = 'High';
          } else if (tempValue < 10) {
            status = 'Low';
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
        String status = 'Normal';
        if (rpm != null) {
          double rpmValue = double.tryParse(rpm.toString()) ?? 0.0;
          if (rpmValue > 2000) {
            status = 'High Speed';
          } else if (rpmValue < 500) {
            status = 'Low Speed';
          }
        }
        return {'title': 'RPM', 'value': '${rpm ?? 'N/A'}', 'subtitle': status};

      case 'Box 3':
        // Air Quality Analysis
        final airQuality = dashboardData!['airquality'];
        String status = 'Good';
        if (airQuality != null) {
          double aqValue = double.tryParse(airQuality.toString()) ?? 0.0;
          if (aqValue > 500) {
            status = 'Poor';
          } else if (aqValue > 300) {
            status = 'Moderate';
          }
        }
        return {
          'title': 'Air Quality',
          'value': '${airQuality ?? 'N/A'} ppm',
          'subtitle': status,
        };

      case 'Box 4':
        // Engine Status based on vibration
        final vibration = dashboardData!['vibration'];
        String status = 'Stable';
        String statusText = 'Engine Running Stable';

        if (vibration != null) {
          double vibValue = double.tryParse(vibration.toString()) ?? 0.0;
          if (vibValue > 10) {
            status = 'FAILURE';
            statusText = 'Engine Failure';
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
          color: Colors.white,
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
                                style: TextStyle(fontSize: isMobile ? 13 : 15),
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
        color: Colors.white,
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
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButton<String>(
                      value: selectedParameter,
                      underline: const SizedBox(),
                      isDense: true,
                      items: chartParameters.map((String parameter) {
                        return DropdownMenuItem<String>(
                          value: parameter,
                          child: Text(
                            parameter,
                            style: TextStyle(fontSize: isMobile ? 10 : 12),
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
                    ? const Center(child: CircularProgressIndicator())
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
      return const Center(child: Text('No chart data available'));
    }

    final List<dynamic> chartPoints = chartData!['chartPoints'];
    if (chartPoints.isEmpty) {
      return const Center(child: Text('No data points available'));
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
      return const Center(child: Text('No valid data for selected parameter'));
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
            return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
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
                  style: const TextStyle(fontSize: 10),
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
                    style: const TextStyle(fontSize: 10),
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
          border: Border.all(color: Colors.grey.shade300),
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
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
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
                    style: const TextStyle(fontSize: 10),
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
          border: Border.all(color: Colors.grey.shade300),
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
}
