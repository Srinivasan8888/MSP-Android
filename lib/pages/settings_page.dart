import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

Widget _buildActionTile(
  String title,
  String subtitle,
  IconData icon,
  VoidCallback onTap,
) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    onTap: onTap,
  );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  bool autoRefreshEnabled = true;
  double refreshInterval = 30.0;
  String selectedLanguage = 'English';

  final List<String> languages = ['English', 'Spanish', 'French', 'German'];

  // Sensor alert configurations
  Map<String, Map<String, dynamic>> sensorAlerts = {
    'vibration': {
      'enabled': true,
      'veryLow': {'min': 0.0, 'max': 2.0},
      'low': {'min': 2.0, 'max': 5.0},
      'medium': {'min': 5.0, 'max': 10.0},
      'high': {'min': 10.0, 'max': 20.0},
      'veryHigh': {'min': 20.0, 'max': 50.0},
      'unit': 'mm/s',
      'icon': Icons.vibration,
    },
    'magneticflux': {
      'enabled': true,
      'veryLow': {'min': 0.0, 'max': 100.0},
      'low': {'min': 100.0, 'max': 500.0},
      'medium': {'min': 500.0, 'max': 1000.0},
      'high': {'min': 1000.0, 'max': 2000.0},
      'veryHigh': {'min': 2000.0, 'max': 5000.0},
      'unit': 'μT',
      'icon': Icons.electric_bolt,
    },
    'rpm': {
      'enabled': true,
      'veryLow': {'min': 0.0, 'max': 500.0},
      'low': {'min': 500.0, 'max': 1500.0},
      'medium': {'min': 1500.0, 'max': 3000.0},
      'high': {'min': 3000.0, 'max': 5000.0},
      'veryHigh': {'min': 5000.0, 'max': 10000.0},
      'unit': 'RPM',
      'icon': Icons.rotate_right,
    },
    'acoustics': {
      'enabled': true,
      'veryLow': {'min': 0.0, 'max': 40.0},
      'low': {'min': 40.0, 'max': 60.0},
      'medium': {'min': 60.0, 'max': 80.0},
      'high': {'min': 80.0, 'max': 100.0},
      'veryHigh': {'min': 100.0, 'max': 120.0},
      'unit': 'dB',
      'icon': Icons.volume_up,
    },
    'temperature': {
      'enabled': true,
      'veryLow': {'min': -20.0, 'max': 10.0},
      'low': {'min': 10.0, 'max': 25.0},
      'medium': {'min': 25.0, 'max': 40.0},
      'high': {'min': 40.0, 'max': 60.0},
      'veryHigh': {'min': 60.0, 'max': 100.0},
      'unit': '°C',
      'icon': Icons.thermostat,
    },
    'humidity': {
      'enabled': true,
      'veryLow': {'min': 0.0, 'max': 20.0},
      'low': {'min': 20.0, 'max': 40.0},
      'medium': {'min': 40.0, 'max': 60.0},
      'high': {'min': 60.0, 'max': 80.0},
      'veryHigh': {'min': 80.0, 'max': 100.0},
      'unit': '%',
      'icon': Icons.water_drop,
    },
    'pressure': {
      'enabled': true,
      'veryLow': {'min': 900.0, 'max': 980.0},
      'low': {'min': 980.0, 'max': 1013.0},
      'medium': {'min': 1013.0, 'max': 1030.0},
      'high': {'min': 1030.0, 'max': 1050.0},
      'veryHigh': {'min': 1050.0, 'max': 1100.0},
      'unit': 'hPa',
      'icon': Icons.compress,
    },
    'altitude': {
      'enabled': true,
      'veryLow': {'min': -500.0, 'max': 0.0},
      'low': {'min': 0.0, 'max': 500.0},
      'medium': {'min': 500.0, 'max': 1500.0},
      'high': {'min': 1500.0, 'max': 3000.0},
      'veryHigh': {'min': 3000.0, 'max': 8000.0},
      'unit': 'm',
      'icon': Icons.landscape,
    },
    'airquality': {
      'enabled': true,
      'veryLow': {'min': 0.0, 'max': 50.0},
      'low': {'min': 50.0, 'max': 100.0},
      'medium': {'min': 100.0, 'max': 150.0},
      'high': {'min': 150.0, 'max': 200.0},
      'veryHigh': {'min': 200.0, 'max': 300.0},
      'unit': 'AQI',
      'icon': Icons.air,
    },
    'battery': {
      'enabled': true,
      'veryLow': {'min': 0.0, 'max': 20.0},
      'low': {'min': 20.0, 'max': 40.0},
      'medium': {'min': 40.0, 'max': 60.0},
      'high': {'min': 60.0, 'max': 80.0},
      'veryHigh': {'min': 80.0, 'max': 100.0},
      'unit': '%',
      'icon': Icons.battery_std,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSensorAlerts();
  }

  // Load sensor alerts from SharedPreferences
  Future<void> _loadSensorAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedAlerts = prefs.getString('sensor_alerts');

      if (savedAlerts != null) {
        final Map<String, dynamic> decoded = json.decode(savedAlerts);
        setState(() {
          // Merge saved values with default structure
          for (String sensorKey in sensorAlerts.keys) {
            if (decoded.containsKey(sensorKey)) {
              final savedSensor = decoded[sensorKey] as Map<String, dynamic>;
              sensorAlerts[sensorKey]!.addAll(savedSensor);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading sensor alerts: $e');
    }
  }

  // Save sensor alerts to SharedPreferences
  Future<void> _saveSensorAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Create a copy without the icon data for JSON serialization
      Map<String, Map<String, dynamic>> savableAlerts = {};
      for (String sensorKey in sensorAlerts.keys) {
        savableAlerts[sensorKey] = Map<String, dynamic>.from(
          sensorAlerts[sensorKey]!,
        );
        // Remove the icon field as it can't be serialized
        savableAlerts[sensorKey]!.remove('icon');
      }

      final String encoded = json.encode(savableAlerts);
      await prefs.setString('sensor_alerts', encoded);
    } catch (e) {
      debugPrint('Error saving sensor alerts: $e');
    }
  }

  void _contactSupport() async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'info@xyma.in',
        query: Uri.encodeFull('subject=Support Request&body=Hello Team,'),
      );

      // Try to launch the email client
      bool canLaunch = false;
      try {
        canLaunch = await canLaunchUrl(emailUri);
      } catch (e) {
        // If canLaunchUrl fails, try to launch anyway
        debugPrint("canLaunchUrl failed: $e");
        canLaunch = false;
      }

      if (canLaunch) {
        await launchUrl(emailUri);
      } else {
        // Fallback: show contact information in a dialog
        _showContactDialog();
      }
    } catch (e) {
      debugPrint("Error launching email: $e");
      _showContactDialog();
    }
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Contact Support',
          style: TextStyle(color: Colors.white),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: info@xyma.in', style: TextStyle(color: Colors.white)),
            SizedBox(height: 8),
            Text(
              'Subject: Support Request',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Please copy the email address and contact us directly.',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'App Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // _buildSettingsSection('Notifications', [
          //   _buildSwitchTile(
          //     'Enable Notifications',
          //     'Receive alerts and updates',
          //     notificationsEnabled,
          //     (value) {
          //       setState(() {
          //         notificationsEnabled = value;
          //       });
          //     },
          //     Icons.notifications,
          //   ),
          // ]),
          // _buildSettingsSection('Appearance', [
          //   _buildSwitchTile('Dark Mode', 'Use dark theme', darkModeEnabled, (
          //     value,
          //   ) {
          //     setState(() {
          //       darkModeEnabled = value;
          //     });
          //   }, Icons.dark_mode),
          //   _buildDropdownTile(
          //     'Language',
          //     'Select app language',
          //     selectedLanguage,
          //     languages,
          //     (value) {
          //       setState(() {
          //         selectedLanguage = value!;
          //       });
          //     },
          //     Icons.language,
          //   ),
          // ]),
          // _buildSettingsSection('Auto Refresh', [
          //   _buildSwitchTile(
          //     'Auto Refresh',
          //     'Automatically refresh data',
          //     autoRefreshEnabled,
          //     (value) {
          //       setState(() {
          //         autoRefreshEnabled = value;
          //       });
          //     },
          //     Icons.refresh,
          //   ),
          //   _buildSliderTile(
          //     'Refresh Interval',
          //     'Data refresh frequency (seconds)',
          //     refreshInterval,
          //     10.0,
          //     120.0,
          //     (value) {
          //       setState(() {
          //         refreshInterval = value;
          //       });
          //     },
          //     Icons.timer,
          //   ),
          // ]),
          _buildSettingsSection('Sensor Alerts', [
            ...sensorAlerts.entries.map(
              (entry) => _buildSensorAlertTile(entry.key, entry.value),
            ),
          ]),
          // _buildSettingsSection('Account', [
          //   _buildActionTile(
          //     'Profile Settings',
          //     'Manage your profile',
          //     Icons.person,
          //     () {
          //       _showComingSoon('Profile Settings');
          //     },
          //   ),
          //   _buildActionTile(
          //     'Change Password',
          //     'Update your password',
          //     Icons.lock,
          //     () {
          //       _showComingSoon('Change Password');
          //     },
          //   ),
          // ]),
          _buildSettingsSection('Support', [
            // _buildActionTile(
            //   'Help & FAQ',
            //   'Get help and support',
            //   Icons.help,
            //   () {
            //     _showComingSoon('Help & FAQ');
            //   },
            // ),
            _buildActionTile(
              'Contact Support',
              'Reach out to our team',
              Icons.support_agent,
              _contactSupport,
            ),
            _buildActionTile('About', 'App version and info', Icons.info, () {
              _showAboutDialog();
            }),
          ]),
          const SizedBox(height: 20),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        Card(elevation: 2, child: Column(children: children)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String value,
    List<String> options,
    Function(String?) onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: options.map((option) {
          return DropdownMenuItem(value: option, child: Text(option));
        }).toList(),
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: ((max - min) / 10).round(),
                  label: '${value.round()}s',
                  onChanged: onChanged,
                ),
              ),
              Text('${value.round()}s'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  Widget _buildSensorAlertTile(String sensorKey, Map<String, dynamic> config) {
    String displayName = sensorKey.replaceAll(
      RegExp(r'([a-z])([A-Z])'),
      r'$1 $2',
    );
    displayName = displayName[0].toUpperCase() + displayName.substring(1);

    return ListTile(
      leading: Icon(config['icon'], color: Colors.blue),
      title: Text(displayName),
      subtitle: Text('Configure alert thresholds (${config['unit']})'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: config['enabled'],
            onChanged: (value) {
              setState(() {
                sensorAlerts[sensorKey]!['enabled'] = value;
              });
              _saveSensorAlerts();
            },
          ),
          const Icon(Icons.arrow_forward_ios),
        ],
      ),
      onTap: () => _showSensorAlertDialog(sensorKey, config),
    );
  }

  void _showSensorAlertDialog(String sensorKey, Map<String, dynamic> config) {
    String displayName = sensorKey.replaceAll(
      RegExp(r'([a-z])([A-Z])'),
      r'$1 $2',
    );
    displayName = displayName[0].toUpperCase() + displayName.substring(1);

    showDialog(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF1E2139),
          ),
          textTheme: Theme.of(context).textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E2139),
          title: Text(
            '$displayName Alert Settings',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAlertLevelCard(
                    'Very Low',
                    Colors.green[300]!,
                    config['veryLow'],
                    sensorKey,
                    config['unit'],
                  ),
                  const SizedBox(height: 8),
                  _buildAlertLevelCard(
                    'Low',
                    Colors.green!,
                    config['low'],
                    sensorKey,
                    config['unit'],
                  ),
                  const SizedBox(height: 8),
                  _buildAlertLevelCard(
                    'Medium',
                    Colors.yellow!,
                    config['medium'],
                    sensorKey,
                    config['unit'],
                  ),
                  const SizedBox(height: 8),
                  _buildAlertLevelCard(
                    'High',
                    Colors.orange!,
                    config['high'],
                    sensorKey,
                    config['unit'],
                  ),
                  const SizedBox(height: 8),
                  _buildAlertLevelCard(
                    'Very High',
                    Colors.red!,
                    config['veryHigh'],
                    sensorKey,
                    config['unit'],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                _saveSensorAlerts();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alert settings saved'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Save', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertLevelCard(
    String level,
    Color color,
    Map<String, dynamic> values,
    String sensorKey,
    String unit,
  ) {
    return Card(
      color: const Color(0xFF2A2D47),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    level,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildValueControl('Min value', values['min'], unit, (
                    newValue,
                  ) {
                    setState(() {
                      String levelKey = _getLevelKey(level);
                      debugPrint(
                        'Updating $sensorKey.$levelKey.min to $newValue',
                      );

                      // Ensure the structure exists
                      if (sensorAlerts[sensorKey] == null) {
                        debugPrint('Error: sensorAlerts[$sensorKey] is null');
                        return;
                      }
                      if (sensorAlerts[sensorKey]![levelKey] == null) {
                        debugPrint(
                          'Error: sensorAlerts[$sensorKey][$levelKey] is null',
                        );
                        return;
                      }

                      sensorAlerts[sensorKey]![levelKey]['min'] = newValue;
                    });
                    _saveSensorAlerts();
                  }),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildValueControl('Max value', values['max'], unit, (
                    newValue,
                  ) {
                    setState(() {
                      String levelKey = _getLevelKey(level);
                      debugPrint(
                        'Updating $sensorKey.$levelKey.max to $newValue',
                      );

                      // Ensure the structure exists
                      if (sensorAlerts[sensorKey] == null) {
                        debugPrint('Error: sensorAlerts[$sensorKey] is null');
                        return;
                      }
                      if (sensorAlerts[sensorKey]![levelKey] == null) {
                        debugPrint(
                          'Error: sensorAlerts[$sensorKey][$levelKey] is null',
                        );
                        return;
                      }

                      sensorAlerts[sensorKey]![levelKey]['max'] = newValue;
                    });
                    _saveSensorAlerts();
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueControl(
    String label,
    double value,
    String unit,
    Function(double) onChanged,
  ) {
    final TextEditingController controller = TextEditingController(
      text: value.toString(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2D47),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Decrease button
              _buildControlButton(Icons.keyboard_arrow_down, () {
                double newValue = value - _getStepValue(unit);
                if (newValue >= 0) {
                  onChanged(newValue);
                  controller.text = newValue.toString();
                }
              }),
              // Value input field
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: _formatValue(value, unit),
                      hintStyle: const TextStyle(color: Colors.white54),
                      suffixText: unit,
                      suffixStyle: const TextStyle(color: Colors.white70),
                    ),
                    onSubmitted: (text) {
                      double? newValue = double.tryParse(text);
                      if (newValue != null && newValue >= 0) {
                        onChanged(newValue);
                      } else {
                        controller.text = value.toString();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter a valid positive number',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    onTapOutside: (event) {
                      double? newValue = double.tryParse(controller.text);
                      if (newValue != null && newValue >= 0) {
                        onChanged(newValue);
                      } else {
                        controller.text = value.toString();
                      }
                    },
                  ),
                ),
              ),
              // Increase button
              _buildControlButton(Icons.keyboard_arrow_up, () {
                double newValue = value + _getStepValue(unit);
                onChanged(newValue);
                controller.text = newValue.toString();
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 40,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2139),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
      ),
    );
  }

  double _getStepValue(String unit) {
    switch (unit) {
      case 'mm/s':
        return 0.1;
      case 'μT':
        return 10.0;
      case 'RPM':
        return 50.0;
      case 'dB':
        return 1.0;
      case '°C':
        return 1.0;
      case '%':
        return 1.0;
      case 'hPa':
        return 1.0;
      case 'm':
        return 10.0;
      case 'AQI':
        return 5.0;
      default:
        return 1.0;
    }
  }

  String _formatValue(double value, String unit) {
    if (value == value.roundToDouble()) {
      return '${value.round()} $unit';
    } else {
      return '${value.toStringAsFixed(1)} $unit';
    }
  }

  String _getLevelKey(String level) {
    switch (level) {
      case 'Very Low':
        return 'veryLow';
      case 'Very High':
        return 'veryHigh';
      default:
        return level.toLowerCase();
    }
  }

  Widget _buildLogoutButton() {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text('Logout', style: TextStyle(color: Colors.red)),
        subtitle: const Text('Sign out of your account'),
        onTap: () {
          _showLogoutDialog();
        },
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('About MSP', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0', style: TextStyle(color: Colors.white)),
            SizedBox(height: 8),
            Text(
              'Machine Sensor Platform',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Monitor and analyze sensor data in real-time.',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
