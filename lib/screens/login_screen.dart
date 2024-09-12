import 'package:flutter/material.dart';
import 'package:weberbrain_flutter_app/screens/reset_password_screen.dart';
import '../services/auth_service.dart';
import '../utils/secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final SecureStorage _secureStorage = SecureStorage();
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  // Define the accent color
  final Color accentColor = Color(0xFF2691A5);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await _authService.signIn(
          _emailController.text,
          _passwordController.text,
        );

        if (result.success && result.session != null) {
          // Store user session securely
          await _secureStorage.writeSecureData(
              'idToken', result.session!.idToken.jwtToken ?? '');
          await _secureStorage.writeSecureData(
              'accessToken', result.session!.accessToken.jwtToken ?? '');
          await _secureStorage.writeSecureData(
              'refreshToken', result.session!.refreshToken?.token ?? '');
          await _secureStorage.writeSecureData('is_logged_in', 'true');

          if (_rememberMe) {
            await _secureStorage.writeSecureData('remember_me', 'true');
            await _secureStorage.writeSecureData(
                'email', _emailController.text);
          } else {
            await _secureStorage.deleteSecureData('remember_me');
            await _secureStorage.deleteSecureData('email');
          }

          // Navigate to MyDeviceScreen using named route
          Navigator.pushReplacementNamed(context, '/my-devices');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message)),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred. Please try again later.')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1F2225),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                      height: MediaQuery.of(context).size.height *
                          0.15), // Adjust this value to move the logo further down
                  // Logo image
                  Image.asset(
                    'assets/weberbrain_logo.png',
                    height: 50,
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height *
                          0.1), // Increased space between logo and input fields
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Username@email.com',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: accentColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: accentColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value!;
                              });
                            },
                            fillColor: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) {
                                  return accentColor;
                                }
                                return Colors.white70;
                              },
                            ),
                          ),
                          Text(
                            'Remember me',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResetPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(color: accentColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: Text(
                      'Create an account',
                      style: TextStyle(color: accentColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
