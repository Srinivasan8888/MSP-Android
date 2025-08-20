import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  bool isLoading = true;
  Map<String, dynamic>? analyticsData;
  String selectedTimeRange = '7d';
  String selectedMetric = 'All';

  final List<String> timeRanges = ['24h', '7d', '30d', '90d'];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      isLoading = true;
    });

    // Simulate loading analytics data
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      analyticsData = {
        'totalSensors': 12,
        'activeDevices': 8,
        'alertsToday': 3,
        'dataPoints': 1250,
        'chartData': _generateChartData(),
      };
      isLoading = false;
    });
  }

  final List<String> metrics = [
    'All',
    'Vibration',
    'Magnetic Flux',
    'RPM',
    'Acoustics',
    'Temp',
    'Humidity',
    'Pressure',
    'Altitude',
    'Air Quality',
  ];

  List<FlSpot> _generateChartData() {
    // Generate different data based on selected metric
    switch (selectedMetric) {
      case 'Vibration':
        return [
          const FlSpot(0, 2.5),
          const FlSpot(1, 3.2),
          const FlSpot(2, 2.8),
          const FlSpot(3, 4.1),
          const FlSpot(4, 3.7),
          const FlSpot(5, 2.9),
          const FlSpot(6, 3.5),
        ];
      case 'Magnetic Flux':
        return [
          const FlSpot(0, 1.8),
          const FlSpot(1, 2.1),
          const FlSpot(2, 1.5),
          const FlSpot(3, 2.7),
          const FlSpot(4, 2.3),
          const FlSpot(5, 1.9),
          const FlSpot(6, 2.4),
        ];
      case 'RPM':
        return [
          const FlSpot(0, 4.2),
          const FlSpot(1, 3.8),
          const FlSpot(2, 4.5),
          const FlSpot(3, 3.9),
          const FlSpot(4, 4.7),
          const FlSpot(5, 4.1),
          const FlSpot(6, 4.3),
        ];
      case 'Acoustics':
        return [
          const FlSpot(0, 2.1),
          const FlSpot(1, 2.8),
          const FlSpot(2, 2.4),
          const FlSpot(3, 3.2),
          const FlSpot(4, 2.9),
          const FlSpot(5, 2.6),
          const FlSpot(6, 3.1),
        ];
      case 'Temp':
        return [
          const FlSpot(0, 3.5),
          const FlSpot(1, 3.2),
          const FlSpot(2, 3.8),
          const FlSpot(3, 3.1),
          const FlSpot(4, 3.9),
          const FlSpot(5, 3.4),
          const FlSpot(6, 3.7),
        ];
      case 'Humidity':
        return [
          const FlSpot(0, 2.7),
          const FlSpot(1, 3.1),
          const FlSpot(2, 2.9),
          const FlSpot(3, 3.4),
          const FlSpot(4, 3.0),
          const FlSpot(5, 2.8),
          const FlSpot(6, 3.2),
        ];
      case 'Pressure':
        return [
          const FlSpot(0, 1.9),
          const FlSpot(1, 2.3),
          const FlSpot(2, 2.1),
          const FlSpot(3, 2.6),
          const FlSpot(4, 2.4),
          const FlSpot(5, 2.0),
          const FlSpot(6, 2.5),
        ];
      case 'Altitude':
        return [
          const FlSpot(0, 3.8),
          const FlSpot(1, 3.5),
          const FlSpot(2, 4.1),
          const FlSpot(3, 3.7),
          const FlSpot(4, 4.3),
          const FlSpot(5, 3.9),
          const FlSpot(6, 4.0),
        ];
      case 'Air Quality':
        return [
          const FlSpot(0, 2.3),
          const FlSpot(1, 2.7),
          const FlSpot(2, 2.5),
          const FlSpot(3, 3.0),
          const FlSpot(4, 2.8),
          const FlSpot(5, 2.4),
          const FlSpot(6, 2.9),
        ];
      default: // 'All'
        return [
          const FlSpot(0, 3),
          const FlSpot(1, 1),
          const FlSpot(2, 4),
          const FlSpot(3, 2),
          const FlSpot(4, 5),
          const FlSpot(5, 3),
          const FlSpot(6, 4),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        automaticallyImplyLeading: false,
        // actions: [
        //   PopupMenuButton<String>(
        //     onSelected: (value) {
        //       setState(() {
        //         selectedTimeRange = value;
        //       });
        //       _loadAnalytics();
        //     },
        //     itemBuilder: (context) => timeRanges.map((range) {
        //       return PopupMenuItem(value: range, child: Text(range));
        //     }).toList(),
        //     child: Padding(
        //       padding: const EdgeInsets.all(16.0),
        //       child: Row(
        //         mainAxisSize: MainAxisSize.min,
        //         children: [
        //           Text(selectedTimeRange),
        //           const Icon(Icons.arrow_drop_down),
        //         ],
        //       ),
        //     ),
        //   ),
        // ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'System Analytics',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  _buildChart(),
                  const SizedBox(height: 24),
                  _buildInsights(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {
        'title': 'Total Sensors',
        'value': '${analyticsData!['totalSensors']}',
        'icon': Icons.sensors,
        'color': Colors.blue,
      },
      {
        'title': 'Active Devices',
        'value': '${analyticsData!['activeDevices']}',
        'icon': Icons.devices,
        'color': Colors.green,
      },
      {
        'title': 'Alerts Today',
        'value': '${analyticsData!['alertsToday']}',
        'icon': Icons.warning,
        'color': Colors.orange,
      },
      {
        'title': 'Data Points',
        'value': '${analyticsData!['dataPoints']}',
        'icon': Icons.data_usage,
        'color': Colors.purple,
      },
    ];

    // Make grid responsive based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 4 : 2;
    final childAspectRatio = screenWidth > 600 ? 1.2 : 1.5;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  stat['icon'] as IconData,
                  size: 32,
                  color: stat['color'] as Color,
                ),
                const SizedBox(height: 8),
                Text(
                  stat['value'] as String,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  stat['title'] as String,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sensor Activity Trend',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: selectedMetric,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedMetric = newValue;
                        analyticsData!['chartData'] = _generateChartData();
                      });
                    }
                  },
                  items: metrics.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 450,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: analyticsData!['chartData'],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsights() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Key Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInsightItem(
              Icons.trending_up,
              'Sensor Activity',
              'Activity increased by 15% this week',
              Colors.green,
            ),
            _buildInsightItem(
              Icons.warning,
              'Alert Frequency',
              '3 alerts detected today, 2 resolved',
              Colors.orange,
            ),
            _buildInsightItem(
              Icons.battery_full,
              'Device Health',
              'All devices operating within normal parameters',
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
