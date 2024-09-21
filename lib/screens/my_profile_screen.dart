import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'my_device_screen.dart';
import 'treatment_screen.dart';
import 'settings_screen.dart';
import '../utils/theme_manager.dart';
import '../widgets/profile_menu_item.dart';
import '../widgets/user_avatar.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class MyProfileScreen extends StatefulWidget {
  final BluetoothDevice device;

  const MyProfileScreen({super.key, required this.device});

  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final int _selectedIndex = 2; // Profile tab
  late Future<User> _userFuture;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.getCurrentUser();
  }

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
          // Already on Profile screen
          break;
        case 3:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => SettingsScreen(device: widget.device)),
          );
          break;
      }
    }
  }

  Widget _buildProfileHeader(User user) {
    return Column(
      children: [
        UserAvatar(user: user, radius: 60),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user.email,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMenu(User user) {
    return Column(
      children: [
        ProfileMenuItem(
          icon: Icons.person,
          title: 'Edit Profile',
          onTap: () {
            // TODO: Implement edit profile functionality
          },
        ),
        ProfileMenuItem(
          icon: Icons.lock,
          title: 'Change Password',
          onTap: () {
            // TODO: Implement change password functionality
          },
        ),
        ProfileMenuItem(
          icon: Icons.notifications,
          title: 'Notifications',
          onTap: () {
            // TODO: Implement notifications settings
          },
        ),
        ProfileMenuItem(
          icon: Icons.privacy_tip,
          title: 'Privacy',
          onTap: () {
            // TODO: Implement privacy settings
          },
        ),
        ProfileMenuItem(
          icon: Icons.help,
          title: 'Help & Support',
          onTap: () {
            // TODO: Implement help and support
          },
        ),
      ],
    );
  }

  void _showChangeAvatarDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Avatar'),
          content: const Text('This feature is not yet implemented.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData =
        ThemeManager.getThemeForDevice(widget.device.platformName);

    return Theme(
      data: themeData,
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Profile - ${widget.device.platformName}'),
          backgroundColor: themeData.primaryColor,
        ),
        body: FutureBuilder<User>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              final user = snapshot.data!;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileHeader(user),
                    const SizedBox(height: 24),
                    _buildProfileMenu(user),
                  ],
                ),
              );
            } else {
              return const Center(child: Text('No user data available'));
            }
          },
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
