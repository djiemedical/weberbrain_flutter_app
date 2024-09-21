import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'my_device_screen.dart';
import 'treatment_screen.dart';
import 'my_profile_screen.dart';
import '../utils/theme_manager.dart';

class SettingsScreen extends StatefulWidget {
  final BluetoothDevice device;

  const SettingsScreen({super.key, required this.device});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final int _selectedIndex = 3; // Settings tab

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyDeviceScreen()),
          );
          break;
        case 1:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => TreatmentScreen(device: widget.device)),
          );
          break;
        case 2:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => MyProfileScreen(device: widget.device)),
          );
          break;
        case 3:
          // Already on Settings screen
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData =
        ThemeManager.getThemeForDevice(widget.device.platformName);

    return Theme(
      data: themeData,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Settings - ${widget.device.platformName}'),
          backgroundColor: themeData.primaryColor,
        ),
        body: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle: const Text('English'),
              onTap: () {
                // TODO: Implement language selection
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              trailing: Switch(
                value: true, // TODO: Get actual value from settings
                onChanged: (bool value) {
                  // TODO: Implement notification toggle
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Security'),
              onTap: () {
                // TODO: Implement security settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              onTap: () {
                // TODO: Implement help and support
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                // TODO: Implement about page
              },
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.devices),
              label: 'My Devices',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.healing),
              label: 'Treatments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: themeData.primaryColor,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
