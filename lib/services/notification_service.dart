import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationItem {
  final String id;
  final String sensorType;
  final String alertLevel;
  final double value;
  final double threshold;
  final String unit;
  final DateTime timestamp;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.sensorType,
    required this.alertLevel,
    required this.value,
    required this.threshold,
    required this.unit,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sensorType': sensorType,
      'alertLevel': alertLevel,
      'value': value,
      'threshold': threshold,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      sensorType: json['sensorType'],
      alertLevel: json['alertLevel'],
      value: json['value'],
      threshold: json['threshold'],
      unit: json['unit'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      sensorType: sensorType,
      alertLevel: alertLevel,
      value: value,
      threshold: threshold,
      unit: unit,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationService {
  static const String _notificationsKey = 'sensor_notifications';
  static const String _alertsKey = 'sensor_alerts';

  // Check sensor values against thresholds and create notifications
  static Future<List<NotificationItem>> checkSensorValues(
    Map<String, dynamic> sensorData,
  ) async {
    final alerts = await _loadSensorAlerts();
    final List<NotificationItem> newNotifications = [];

    for (String sensorKey in sensorData.keys) {
      if (alerts.containsKey(sensorKey) &&
          alerts[sensorKey]?['enabled'] == true) {
        final sensorConfig = alerts[sensorKey];
        if (sensorConfig == null) continue;

        final double currentValue = (sensorData[sensorKey] ?? 0.0).toDouble();

        // Check each alert level
        for (String level in ['veryLow', 'low', 'medium', 'high', 'veryHigh']) {
          if (sensorConfig.containsKey(level)) {
            final levelConfig = sensorConfig[level];
            if (levelConfig == null) continue;

            final double min = levelConfig['min'].toDouble();
            final double max = levelConfig['max'].toDouble();

            // Check if current value is outside the acceptable range
            if (currentValue < min || currentValue > max) {
              final notification = NotificationItem(
                id: '${sensorKey}_${level}_${DateTime.now().millisecondsSinceEpoch}',
                sensorType: sensorKey,
                alertLevel: level,
                value: currentValue,
                threshold: currentValue < min ? min : max,
                unit: sensorConfig['unit'] ?? '',
                timestamp: DateTime.now(),
              );

              newNotifications.add(notification);
              break; // Only create one notification per sensor
            }
          }
        }
      }
    }

    // Save new notifications
    if (newNotifications.isNotEmpty) {
      await _saveNotifications(newNotifications);
    }

    return newNotifications;
  }

  // Get all notifications
  static Future<List<NotificationItem>> getAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notificationsJson = prefs.getString(_notificationsKey);

      if (notificationsJson != null) {
        final List<dynamic> notificationsList = json.decode(notificationsJson);
        return notificationsList
            .map((json) => NotificationItem.fromJson(json))
            .toList()
          ..sort(
            (a, b) => b.timestamp.compareTo(a.timestamp),
          ); // Sort by newest first
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }

    return [];
  }

  // Get unread notifications count
  static Future<int> getUnreadCount() async {
    final notifications = await getAllNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    final notifications = await getAllNotifications();
    final updatedNotifications = notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    await _saveAllNotifications(updatedNotifications);
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    final notifications = await getAllNotifications();
    final updatedNotifications = notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();

    await _saveAllNotifications(updatedNotifications);
  }

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    await _saveAllNotifications([]);
  }

  // Clear old notifications (older than 7 days)
  static Future<void> clearOldNotifications() async {
    final notifications = await getAllNotifications();
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

    final recentNotifications = notifications
        .where((n) => n.timestamp.isAfter(cutoffDate))
        .toList();

    await _saveAllNotifications(recentNotifications);
  }

  // Private helper methods
  static Future<void> _saveNotifications(
    List<NotificationItem> newNotifications,
  ) async {
    final existingNotifications = await getAllNotifications();
    final allNotifications = [...existingNotifications, ...newNotifications];
    await _saveAllNotifications(allNotifications);
  }

  static Future<void> _saveAllNotifications(
    List<NotificationItem> notifications,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, json.encode(notificationsJson));
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  static Future<Map<String, Map<String, dynamic>>> _loadSensorAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedAlerts = prefs.getString(_alertsKey);

      if (savedAlerts != null) {
        final Map<String, dynamic> decoded = json.decode(savedAlerts);
        return decoded.cast<String, Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error loading sensor alerts: $e');
    }

    // Return default configuration if no saved alerts
    return _getDefaultSensorAlerts();
  }

  static Map<String, Map<String, dynamic>> _getDefaultSensorAlerts() {
    return {
      'vibration': {
        'enabled': true,
        'veryLow': {'min': 0.0, 'max': 2.0},
        'low': {'min': 2.0, 'max': 5.0},
        'medium': {'min': 5.0, 'max': 10.0},
        'high': {'min': 10.0, 'max': 20.0},
        'veryHigh': {'min': 20.0, 'max': 50.0},
        'unit': 'mm/s',
      },
      'magneticflux': {
        'enabled': true,
        'veryLow': {'min': 0.0, 'max': 100.0},
        'low': {'min': 100.0, 'max': 500.0},
        'medium': {'min': 500.0, 'max': 1000.0},
        'high': {'min': 1000.0, 'max': 2000.0},
        'veryHigh': {'min': 2000.0, 'max': 5000.0},
        'unit': 'μT',
      },
      'rpm': {
        'enabled': true,
        'veryLow': {'min': 0.0, 'max': 500.0},
        'low': {'min': 500.0, 'max': 1500.0},
        'medium': {'min': 1500.0, 'max': 3000.0},
        'high': {'min': 3000.0, 'max': 5000.0},
        'veryHigh': {'min': 5000.0, 'max': 10000.0},
        'unit': 'RPM',
      },
      'acoustics': {
        'enabled': true,
        'veryLow': {'min': 0.0, 'max': 40.0},
        'low': {'min': 40.0, 'max': 60.0},
        'medium': {'min': 60.0, 'max': 80.0},
        'high': {'min': 80.0, 'max': 100.0},
        'veryHigh': {'min': 100.0, 'max': 120.0},
        'unit': 'dB',
      },
      'temperature': {
        'enabled': true,
        'veryLow': {'min': -20.0, 'max': 10.0},
        'low': {'min': 10.0, 'max': 25.0},
        'medium': {'min': 25.0, 'max': 40.0},
        'high': {'min': 40.0, 'max': 60.0},
        'veryHigh': {'min': 60.0, 'max': 100.0},
        'unit': '°C',
      },
      'humidity': {
        'enabled': true,
        'veryLow': {'min': 0.0, 'max': 20.0},
        'low': {'min': 20.0, 'max': 40.0},
        'medium': {'min': 40.0, 'max': 60.0},
        'high': {'min': 60.0, 'max': 80.0},
        'veryHigh': {'min': 80.0, 'max': 100.0},
        'unit': '%',
      },
      'pressure': {
        'enabled': true,
        'veryLow': {'min': 900.0, 'max': 980.0},
        'low': {'min': 980.0, 'max': 1013.0},
        'medium': {'min': 1013.0, 'max': 1030.0},
        'high': {'min': 1030.0, 'max': 1050.0},
        'veryHigh': {'min': 1050.0, 'max': 1100.0},
        'unit': 'hPa',
      },
      'altitude': {
        'enabled': true,
        'veryLow': {'min': -500.0, 'max': 0.0},
        'low': {'min': 0.0, 'max': 500.0},
        'medium': {'min': 500.0, 'max': 1500.0},
        'high': {'min': 1500.0, 'max': 3000.0},
        'veryHigh': {'min': 3000.0, 'max': 8000.0},
        'unit': 'm',
      },
      'airquality': {
        'enabled': true,
        'veryLow': {'min': 0.0, 'max': 50.0},
        'low': {'min': 50.0, 'max': 100.0},
        'medium': {'min': 100.0, 'max': 150.0},
        'high': {'min': 150.0, 'max': 200.0},
        'veryHigh': {'min': 200.0, 'max': 300.0},
        'unit': 'AQI',
      },
      'battery': {
        'enabled': true,
        'veryLow': {'min': 0.0, 'max': 20.0},
        'low': {'min': 20.0, 'max': 40.0},
        'medium': {'min': 40.0, 'max': 60.0},
        'high': {'min': 60.0, 'max': 80.0},
        'veryHigh': {'min': 80.0, 'max': 100.0},
        'unit': '%',
      },
    };
  }
}
