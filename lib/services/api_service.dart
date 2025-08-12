import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://34.100.168.176:4000/api/v2';
  static String? _scannedUserId;

  static void setScannedUserId(String userId) {
    _scannedUserId = userId;
  }

  static String? getScannedUserId() {
    return _scannedUserId;
  }

  static Future<Map<String, dynamic>?> getDashboardAndChartData({
    String? userId,
    String? parameter,
  }) async {
    try {
      final selectedParam = parameter ?? 'vibration';

      final response = await http.get(
        Uri.parse('$baseUrl/getDashboard?parameter=$selectedParam'),
        headers: {
          'Content-Type': 'application/json',
          'x-user-id': userId ?? _scannedUserId ?? 'N/A',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ------------------------------
        // Extract latest values (Dashboard)
        // ------------------------------
        Map<String, dynamic> latestValues = {};
        if (data['cardData'] is Map<String, dynamic>) {
          final cardData = data['cardData'] as Map<String, dynamic>;
          cardData.forEach((key, value) {
            if (value is List &&
                value.isNotEmpty &&
                key != 'signal' &&
                key != 'battery') {
              latestValues[key] = value[0];
            }
          });
        }

        // ------------------------------
        // Filter allData (remove signal & battery)
        // ------------------------------
        List<Map<String, dynamic>> filteredAllData = [];
        if (data['allData'] is List) {
          filteredAllData = (data['allData'] as List)
              .map<Map<String, dynamic>>((item) {
            if (item is Map) {
              final filteredItem = Map<String, dynamic>.from(
                  item.map((key, value) => MapEntry(key.toString(), value)));
              filteredItem.remove('signal');
              filteredItem.remove('battery');
              return filteredItem;
            }
            return <String, dynamic>{};
          }).toList();
        }

        // ------------------------------
        // Extract chart data
        // ------------------------------
        List<Map<String, dynamic>> chartPoints = [];
        if (data['chartData'] != null) {
          final chartData = data['chartData'] as Map<String, dynamic>;
          final paramValues = chartData[selectedParam] as List<dynamic>?;
          final timeValues = chartData['time'] as List<dynamic>?;

          if (paramValues != null &&
              timeValues != null &&
              paramValues.length == timeValues.length) {
            for (int i = 0; i < paramValues.length; i++) {
              chartPoints.add({
                'x': i.toDouble(),
                'y': (paramValues[i] is num)
                    ? (paramValues[i] as num).toDouble()
                    : 0.0,
                'time': timeValues[i].toString(),
              });
            }
          }
        }

        // ------------------------------
        // Final combined result
        // ------------------------------
        return {
          ...latestValues,
          'allData': filteredAllData,
          'chartPoints': chartPoints,
          'parameter': selectedParam,
          'rawChartData': data['chartData'] ?? {},
          'parameters': data['cardData']
              ?.keys
              .where((key) =>
          key != 'signal' &&
              key != 'battery' &&
              key != 'time')
              .toList() ??
              [],
        };
      }
    } catch (e) {
      print('Error in getDashboardAndChartData: $e');
    }
    return null;
  }

}
