import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';
import 'treatment_screen.dart';
import 'my_profile_screen.dart';
import 'settings_screen.dart';

class MyDeviceScreen extends StatefulWidget {
  const MyDeviceScreen({super.key});

  @override
  _MyDeviceScreenState createState() => _MyDeviceScreenState();
}

class _MyDeviceScreenState extends State<MyDeviceScreen> {
  List<BluetoothDevice> _discoveredDevices = [];
  final AuthService _authService = AuthService();
  final int _selectedIndex = 0; // My Devices tab
  BluetoothDevice? selectedDevice;
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  @override
  void dispose() {
    _scanResultsSubscription?.cancel();
    _adapterStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initBluetooth() async {
    await _requestPermissions();

    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        _startScan();
      } else if (state == BluetoothAdapterState.off) {
        setState(() {
          _discoveredDevices.clear();
          selectedDevice = null;
        });
      }
    });

    if (await FlutterBluePlus.isAvailable) {
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState == BluetoothAdapterState.on) {
        _startScan();
      }
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.location,
        Permission.storage,
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
    } else if (Platform.isIOS) {
      await [
        Permission.bluetooth,
      ].request();
    }
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

      _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          _discoveredDevices = results
              .where((r) => r.device.platformName.startsWith('WEH'))
              .map((r) => r.device)
              .toList();
        });
      }, onError: (e) {
        print('Error during scan: $e');
      });

      await Future.delayed(const Duration(seconds: 15));
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print('Error starting scan: $e');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  // Helper function to mask device name
  String _maskDeviceName(String name) {
    return name.replaceAll('_', '-');
  }

  Widget _buildDeviceList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _discoveredDevices.length,
      itemBuilder: (context, index) {
        final device = _discoveredDevices[index];
        final isSelected = device == selectedDevice;
        final deviceType = device.platformName.substring(4, 7);
        final iconColor = deviceType == '678' ? Colors.blue : Colors.green;

        return ListTile(
          leading: Icon(Icons.bluetooth, color: iconColor),
          title: Text(_maskDeviceName(device.platformName)),
          subtitle: Text(device.remoteId.toString()),
          trailing: ElevatedButton(
            child: const Text('Connect'),
            onPressed: () => _connectToDevice(device),
          ),
          onTap: () => _selectDevice(device),
          tileColor: isSelected ? Colors.grey.withOpacity(0.3) : null,
        );
      },
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        selectedDevice = device;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Connected to ${_maskDeviceName(device.platformName)}')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TreatmentScreen(device: device),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: $e')),
      );
    }
  }

  void _selectDevice(BluetoothDevice device) {
    setState(() {
      selectedDevice = device;
    });
  }

  Future<void> _handleRefresh() async {
    await _startScan();
    return Future.delayed(const Duration(seconds: 1));
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      switch (index) {
        case 0:
          // Already on My Devices screen
          break;
        case 1:
          _navigateToScreen(TreatmentScreen(device: selectedDevice!));
          break;
        case 2:
          _navigateToScreen(MyProfileScreen(device: selectedDevice!));
          break;
        case 3:
          _navigateToScreen(SettingsScreen(device: selectedDevice!));
          break;
      }
    }
  }

  void _navigateToScreen(Widget screen) {
    if (selectedDevice != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a device first')),
      );
    }
  }

  ThemeData _getThemeData() {
    if (selectedDevice == null) {
      return ThemeData.light();
    }

    final deviceType = selectedDevice!.platformName.substring(4, 7);
    final isDarkTheme = deviceType == '678';

    return isDarkTheme
        ? ThemeData.dark().copyWith(
            primaryColor: Colors.blueGrey[800],
            scaffoldBackgroundColor: Colors.grey[900],
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[600],
                foregroundColor: Colors.white,
              ),
            ),
          )
        : ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            scaffoldBackgroundColor: Colors.white,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = _getThemeData();
    return Theme(
      data: themeData,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Devices'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('WEH Devices',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildDeviceList(),
                  if (_isScanning)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Scanning for devices...'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
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

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }
}
