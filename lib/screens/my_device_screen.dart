import 'package:flutter/material.dart';
import 'dart:math';
import '../services/auth_service.dart';

class MyDeviceScreen extends StatefulWidget {
  const MyDeviceScreen({Key? key}) : super(key: key);

  @override
  _MyDeviceScreenState createState() => _MyDeviceScreenState();
}

class _MyDeviceScreenState extends State<MyDeviceScreen> {
  List<String> unpairedDevices = [];
  List<String> pairedDevices = [];
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _generateDummyDevices();
  }

  void _generateDummyDevices() {
    List<String> newUnpairedDevices = [];
    List<String> newPairedDevices = [];
    for (int i = 0; i < 3; i++) {
      newUnpairedDevices.add('WEH-678-${_generateRandomDigits()}');
    }
    for (int i = 0; i < 2; i++) {
      newPairedDevices.add('WEH-678-${_generateRandomDigits()}');
    }
    setState(() {
      unpairedDevices = newUnpairedDevices;
      pairedDevices = newPairedDevices;
    });
  }

  String _generateRandomDigits() {
    Random random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  void _pairDevice(String deviceName) {
    setState(() {
      unpairedDevices.remove(deviceName);
      pairedDevices.add(deviceName);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Paired with $deviceName')),
    );
  }

  void _unpairDevice(String deviceName) {
    setState(() {
      pairedDevices.remove(deviceName);
      unpairedDevices.add(deviceName);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unpaired from $deviceName')),
    );
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      // Navigate to login screen after signing out
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }

  Widget _buildDeviceList(List<String> devices, bool isPaired) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(Icons.bluetooth,
              color: isPaired ? Colors.blue : Colors.grey),
          title: Text(devices[index]),
          subtitle: Text(isPaired ? 'Paired' : 'Tap to pair'),
          trailing: ElevatedButton(
            child: Text(isPaired ? 'Unpair' : 'Pair'),
            onPressed: () {
              if (isPaired) {
                _unpairDevice(devices[index]);
              } else {
                _pairDevice(devices[index]);
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      _generateDummyDevices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                const Text('Unpaired Devices',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDeviceList(unpairedDevices, false),
                const SizedBox(height: 24),
                const Text('Paired Devices',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDeviceList(pairedDevices, true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
