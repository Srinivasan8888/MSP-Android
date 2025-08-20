import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: info@xyma.in'),
            SizedBox(height: 8),
            Text('Subject: Support Request'),
            SizedBox(height: 8),
            Text('Please copy the email address and contact us directly.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
          // _buildSettingsSection('Data & Sync', [
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
        title: const Text('About MSP'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Machine Sensor Platform'),
            SizedBox(height: 8),
            Text('Monitor and analyze sensor data in real-time.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
