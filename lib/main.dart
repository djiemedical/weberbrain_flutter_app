import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/verification_code_screen.dart';
import 'screens/reset_password_screen.dart';
import 'utils/secure_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weber Brain App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: FutureBuilder<bool>(
        future: SecureStorage()
            .readSecureData('is_logged_in')
            .then((value) => value == 'true'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data == true) {
              return const BackButtonHandler(child: LoginScreen());
            } else {
              return const BackButtonHandler(child: SplashScreen());
            }
          }
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        },
      ),
      routes: {
        '/onboarding': (context) =>
            const BackButtonHandler(child: OnboardingScreen()),
        '/login': (context) => const BackButtonHandler(child: LoginScreen()),
        '/signup': (context) => const BackButtonHandler(child: SignUpScreen()),
        '/verification': (context) => BackButtonHandler(
              child: VerificationScreen(
                // Make sure this matches your class name
                email: ModalRoute.of(context)!.settings.arguments as String,
              ),
            ),
        '/reset-password': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return ResetPasswordScreen(
            email: args['email'] as String,
            verificationCode: args['verificationCode'] as String,
          );
        },
      },
    );
  }
}

class BackButtonHandler extends StatelessWidget {
  final Widget child;
  static const platform =
      MethodChannel('com.example.weberbrain_flutter_app/back_button');

  const BackButtonHandler({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final canPop =
            await platform.invokeMethod<bool>('canPopNavigator') ?? false;
        return canPop;
      },
      child: child,
    );
  }
}
