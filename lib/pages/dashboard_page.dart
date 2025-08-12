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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Metrics list with name, icon, and live values (latest = first element in arrays)
    final List<Map<String, dynamic>> metrics = [
      {'name': 'Vibration', 'icon': Icons.vibration, 'value': _getLatestValue('vibration', 'm/s²')},
      {'name': 'Magnetic Flux', 'icon': Icons.explore, 'value': _getLatestValue('magneticflux', 'µT')},
      {'name': 'RPM', 'icon': Icons.rotate_right, 'value': _getLatestValue('rpm', 'RPM')},
      {'name': 'Acoustics', 'icon': Icons.speaker, 'value': _getLatestValue('acoustics', 'dB')},
      {'name': 'Temperature', 'icon': Icons.thermostat, 'value': _getLatestValue('temperature', '°C')},
      {'name': 'Humidity', 'icon': Icons.water_drop, 'value': _getLatestValue('humidity', '%')},
      {'name': 'Pressure', 'icon': Icons.compress, 'value': _getLatestValue('pressure', 'hPa')},
      {'name': 'Altitude', 'icon': Icons.terrain, 'value': _getLatestValue('altitude', 'm')},
      {'name': 'Air Quality', 'icon': Icons.air, 'value': _getLatestValue('airquality', 'ppm')},
    ];

    // Widget for metrics grid section
    Widget buildMetricsSection() {
      // Responsive breakpoints
      final double screenWidth = MediaQuery.of(context).size.width;
      bool isMobile = screenWidth < 600;

      // Dynamic grid configuration based on screen size
      int crossAxisCount = 2;
      double childAspectRatio = 1.1;
      double iconSize = 20;
      double titleFontSize = 10;
      double valueFontSize = 12;
      EdgeInsets cardPadding = const EdgeInsets.all(4.0);

      if (screenWidth < 400) {
        // Small mobile phones
        crossAxisCount = 2;
        childAspectRatio = 1.1;
        iconSize = 20;
        titleFontSize = 10;
        valueFontSize = 12;
        cardPadding = const EdgeInsets.all(4.0);
      } else if (screenWidth < 600) {
        // Regular mobile phones
        crossAxisCount = 2;
        childAspectRatio = 1.2;
        iconSize = 24;
        titleFontSize = 11;
        valueFontSize = 13;
        cardPadding = const EdgeInsets.all(6.0);
      } else if (screenWidth < 900) {
        // Tablets portrait
        crossAxisCount = 3;
        childAspectRatio = 1.3;
        iconSize = 28;
        titleFontSize = 13;
        valueFontSize = 15;
        cardPadding = const EdgeInsets.all(8.0);
      } else {
        // Tablets landscape / Desktop
        crossAxisCount = 5;
        childAspectRatio = 1;
        iconSize = 32;
        titleFontSize = 14;
        valueFontSize = 16;
        cardPadding = const EdgeInsets.all(10.0);
      }

      return Container(
        margin: EdgeInsets.all(isMobile ? 4.0 : 8.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                            Colors.blueAccent.withValues(alpha: 0.1),
                            Colors.blueAccent.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blueAccent.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
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
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard'),
            Text(
              'User ID: ${ApiService.getScannedUserId() ?? 'N/A'}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
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
                  Expanded(child: buildMetricsSection()),
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
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Mobile layout - single column with fixed heights
              SizedBox(
                height: 400,
                child: buildMetricsSection(),
              ),
              SizedBox(
                height: 150,
                child: buildSection2(),
              ),
              SizedBox(
                height: 300,
                child: buildSection3(),
              ),
              SizedBox(
                height: 250,
                child: buildSection4(),
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
        color: Colors.yellow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Section 2',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 6.0 : 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(isMobile ? 6.0 : 8.0),
                child: Text(
                  'All Data Records',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
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
                              fontSize: isMobile ? 10 : 12,
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
                                style: TextStyle(fontSize: isMobile ? 9 : 11),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chart Data',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
                            style: const TextStyle(fontSize: 12),
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
              const SizedBox(height: 16),
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
      return const Center(
        child: Text('No chart data available'),
      );
    }

    final List<dynamic> chartPoints = chartData!['chartPoints'];
    if (chartPoints.isEmpty) {
      return const Center(
        child: Text('No data points available'),
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
        child: Text('No valid data for selected parameter'),
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
          horizontalInterval: (adjustedMaxY - adjustedMinY) > 0 ? (adjustedMaxY - adjustedMinY) / 5 : 1,
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