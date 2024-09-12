import 'package:flutter/material.dart';
import '../utils/secure_storage.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = Color(0xFF1F2225);
    final Color accentColor = Color(0xFF2691A5);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/weberbrain_logo.png',
              width: 200,
            ),
            SizedBox(height: 40),
            Text(
              'Welcome to WeberBrain',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Enhance your cognitive performance with our advanced brain training app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              child: Text(
                'Get Started',
                style: TextStyle(
                  color: backgroundColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                // Set the flag that onboarding has been seen
                await SecureStorage()
                    .writeSecureData('has_seen_onboarding', 'true');
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
