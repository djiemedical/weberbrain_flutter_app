import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/verification_code_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/my_device_screen.dart';
import 'utils/secure_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weber Brain App',
      debugShowCheckedModeBanner: false,
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
      home: const SplashScreen(), // Always start with the SplashScreen
      routes: {
        '/onboarding': (context) =>
            const BackButtonHandler(child: OnboardingScreen()),
        '/login': (context) => const BackButtonHandler(child: LoginScreen()),
        '/signup': (context) => const BackButtonHandler(child: SignUpScreen()),
        '/verification': (context) => BackButtonHandler(
              child: VerificationScreen(
                email: ModalRoute.of(context)!.settings.arguments as String,
              ),
            ),
        '/reset-password': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>?;
          return BackButtonHandler(
            child: ResetPasswordScreen(
              email: args?['email'] as String?,
            ),
          );
        },
        '/my-devices': (context) =>
            const BackButtonHandler(child: MyDeviceScreen()),
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
