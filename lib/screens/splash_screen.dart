import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _getBuildNumber();
    _navigateToNextScreen();
  }

  Future<void> _getBuildNumber() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _buildNumber = packageInfo.buildNumber;
    });
  }

  void _navigateToNextScreen() {
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacementNamed(context, '/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Center logo and app name
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', width: 200, height: 200),
                const SizedBox(height: 20),
                const Text(
                  'Weber Brain App',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Bottom information
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Column(
              children: [
                Text('Build: $_buildNumber'),
                const Text('© 2024 Weber Medical GmbH'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
