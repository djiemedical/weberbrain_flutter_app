import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/secure_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String _buildNumber = '';
  late AnimationController _controller;
  late Animation<double> _animation;
  final Color accentColor = Color(0xFF2691A5);

  @override
  void initState() {
    super.initState();
    _getBuildNumber();
    _setupAnimation();
    _navigateToNextScreen();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _getBuildNumber() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _buildNumber = packageInfo.buildNumber;
    });
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 5));
    final SecureStorage secureStorage = SecureStorage();
    final bool hasSeenOnboarding =
        await secureStorage.readSecureData('has_seen_onboarding') == 'true';
    final bool isLoggedIn =
        await secureStorage.readSecureData('is_logged_in') == 'true';

    if (mounted) {
      if (!hasSeenOnboarding) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/my-devices');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1F2225),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/weberbrain_logo.png',
                    width: 270, height: 270),
                const SizedBox(height: 20),
                const Text(
                  'Weber Brain App',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: LinearProgressIndicator(
                    value: _animation.value,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
                Text('Build: $_buildNumber',
                    style: TextStyle(color: Colors.white70)),
                const Text('© 2024 Weber Medical GmbH',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
