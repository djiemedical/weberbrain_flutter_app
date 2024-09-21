import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import 'verification_code_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? email;

  const ResetPasswordScreen({super.key, this.email});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final List<TextEditingController> _codeControllers =
      List.generate(6, (index) => TextEditingController());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isEmailSent = false;
  bool _isCodeComplete = false;
  int _resendCodeTimer = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email ?? '');
    for (var controller in _codeControllers) {
      controller.addListener(_onCodeChanged);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (var controller in _codeControllers) {
      controller.removeListener(_onCodeChanged);
      controller.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onCodeChanged() {
    final isComplete =
        _codeControllers.every((controller) => controller.text.isNotEmpty);
    if (isComplete != _isCodeComplete) {
      setState(() {
        _isCodeComplete = isComplete;
      });
    }
  }

  String get _verificationCode {
    return _codeControllers.map((controller) => controller.text).join();
  }

  void _startResendTimer() {
    _resendCodeTimer = 180; // 3 minutes
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCodeTimer > 0) {
          _resendCodeTimer--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  String get _timerText {
    int minutes = _resendCodeTimer ~/ 60;
    int seconds = _resendCodeTimer % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _sendResetCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await _authService.forgotPassword(_emailController.text);
        if (result.success) {
          setState(() {
            _isEmailSent = true;
          });
          _startResendTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reset code sent to your email')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message)),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await _authService.confirmNewPassword(
          _emailController.text,
          _verificationCode,
          _newPasswordController.text,
        );

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset successfully')),
          );
          // Navigate to MyDeviceScreen using named route
          Navigator.pushReplacementNamed(context, '/my-devices');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message)),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
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
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isEmailSent
                      ? 'Enter the verification code sent to your email'
                      : 'Enter your email to receive a password reset code',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (!_isEmailSent) ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendResetCode,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Send Reset Code'),
                  ),
                ] else ...[
                  VerificationCodeInput(
                    controllers: _codeControllers,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _resendCodeTimer > 0 ? null : _sendResetCode,
                        child: const Text('Resend Code'),
                      ),
                      Text(_resendCodeTimer > 0 ? 'Resend in $_timerText' : ''),
                    ],
                  ),
                  if (_isCodeComplete) ...[
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: const InputDecoration(labelText: 'New Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a new password';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters long';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration:
                          const InputDecoration(labelText: 'Confirm New Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Reset Password'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
