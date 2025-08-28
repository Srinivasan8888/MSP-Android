import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> reports = [];
  List<Map<String, dynamic>> reportHistory = [];

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
    'Battery',
  ];

  String? selectedMetric;

  @override
  void initState() {
    super.initState();
    _loadReports();
    _loadReportHistory();
  }

  Future<void> _loadReports() async {
    try {
      final reportsData = await ApiService.getReports(
        userId: ApiService.getScannedUserId(),
        metric: selectedMetric,
      );

      if (mounted) {
        setState(() {
          if (reportsData != null) {
            reports = reportsData;
          } else {
            // Fallback to empty list if API fails
            reports = [];
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          reports = [];
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reports: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadReportHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('report_history');
    if (historyJson != null) {
      setState(() {
        reportHistory = List<Map<String, dynamic>>.from(
          json.decode(historyJson),
        );
      });
    }
  }

  Future<void> _saveReportHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('report_history', json.encode(reportHistory));
  }

  Future<void> _updateReportStatus(String reportId, String newStatus) async {
    final reportIndex = reports.indexWhere((r) => r['id'] == reportId);
    if (reportIndex != -1) {
      final report = reports[reportIndex];
      final oldStatus = report['status'];

      try {
        // Update status via API
        final success = await ApiService.updateReportStatus(
          reportId: reportId,
          status: newStatus,
          userId: ApiService.getScannedUserId(),
        );

        if (success && mounted) {
          // Add to history
          final historyEntry = {
            'reportId': reportId,
            'reportTitle': report['title'],
            'oldStatus': oldStatus,
            'newStatus': newStatus,
            'timestamp': DateTime.now().toIso8601String(),
            'metric': report['metric'],
          };

          setState(() {
            reports[reportIndex]['status'] = newStatus;
            reportHistory.insert(0, historyEntry);
          });

          _saveReportHistory();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status updated: $oldStatus → $newStatus')),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update report status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating status: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: const Color(0xFF121212),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Generated Reports',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metrics Dropdown
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMetric,
                        hint: const Text(
                          'Select Metric',
                          style: TextStyle(color: Colors.white),
                        ),
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2A2A2A),
                        style: const TextStyle(color: Colors.white),
                        items: metrics.map((String metric) {
                          return DropdownMenuItem<String>(
                            value: metric,
                            child: Text(
                              metric,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedMetric = newValue;
                            isLoading = true;
                          });
                          _loadReports();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Download Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadReport(),
                      icon: const Icon(Icons.download, color: Colors.white),
                      label: const Text(
                        'Download The Excel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: ListView.builder(
                      itemCount: reports.length,
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: const Color(0xFF1E1E1E),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(
                                report['status'],
                              ),
                              child: Icon(
                                _getStatusIcon(report['status']),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              report['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date: ${report['date']}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  'Metric: ${report['metric']}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(
                                report['status'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: _getStatusColor(
                                report['status'],
                              ),
                            ),
                            onTap: () => _showStatusUpdateDialog(report),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check;
      case 'in progress':
        return Icons.hourglass_empty;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  void _showStatusUpdateDialog(Map<String, dynamic> report) {
    final statuses = ['In Progress', 'Completed', 'Failed', 'Pending'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Status: ${report['title']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Status: ${report['status']}'),
              const SizedBox(height: 16),
              const Text('Select new status:'),
              const SizedBox(height: 8),
              ...statuses.map(
                (status) => ListTile(
                  title: Text(status),
                  leading: Icon(_getStatusIcon(status)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _updateReportStatus(report['id'], status);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Report Status History'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: reportHistory.isEmpty
                ? const Center(child: Text('No history available'))
                : ListView.builder(
                    itemCount: reportHistory.length,
                    itemBuilder: (context, index) {
                      final entry = reportHistory[index];
                      final timestamp = DateTime.parse(entry['timestamp']);
                      return Card(
                        child: ListTile(
                          title: Text(entry['reportTitle']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry['oldStatus']} → ${entry['newStatus']}',
                              ),
                              Text('Metric: ${entry['metric']}'),
                              Text(
                                '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                              ),
                            ],
                          ),
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(
                              entry['newStatus'],
                            ),
                            child: Icon(
                              _getStatusIcon(entry['newStatus']),
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('report_history');
                if (mounted) {
                  setState(() {
                    reportHistory.clear();
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('History cleared')),
                  );
                }
              },
              child: const Text('Clear History'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _downloadReport() {
    // Show download progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating Excel report...'),
            ],
          ),
        );
      },
    );

    // Simulate download process
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.of(context).pop(); // Close progress dialog

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedMetric != null
                        ? 'Excel report for $selectedMetric downloaded successfully!'
                        : 'Excel report for all metrics downloaded successfully!',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }
}
