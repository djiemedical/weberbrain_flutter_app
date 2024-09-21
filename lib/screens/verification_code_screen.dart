import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/auth_service.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  final bool isPasswordReset;

  const VerificationScreen({
    super.key,
    required this.email,
    this.isPasswordReset = false,
  });

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _codeControllers =
      List.generate(6, (index) => TextEditingController());
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _canResend = true;
  int _remainingTime = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _remainingTime = 180; // 3 minutes in seconds
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String get _timerText {
    int minutes = _remainingTime ~/ 60;
    int seconds = _remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _verificationCode {
    return _codeControllers.map((controller) => controller.text).join();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await _authService.confirmSignUp(
          widget.email,
          _verificationCode,
        );

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account verified successfully')),
          );
          // Navigate directly to MyDeviceScreen
          Navigator.pushReplacementNamed(context, '/my-devices');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message)),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
    });

    try {
      AuthResult result;
      if (widget.isPasswordReset) {
        result = await _authService.forgotPassword(widget.email);
      } else {
        result = await _authService.resendConfirmationCode(widget.email);
      }

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
        _startResendTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.isPasswordReset ? 'Verify Reset Code' : 'Verify Email'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enter the verification code sent to ${widget.email}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  VerificationCodeInput(
                    controllers: _codeControllers,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.isPasswordReset ? 'Verify Code' : 'Verify'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed:
                            _canResend && !_isLoading ? _resendCode : null,
                        child: const Text('Resend Code'),
                      ),
                      Text(_canResend ? '' : 'Resend in $_timerText'),
                    ],
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

class VerificationCodeInput extends StatelessWidget {
  final List<TextEditingController> controllers;

  const VerificationCodeInput({super.key, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) => _buildDigitInput(context, index)),
    );
  }

  Widget _buildDigitInput(BuildContext context, int index) {
    return SizedBox(
      width: 40,
      child: TextFormField(
        controller: controllers[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).nextFocus();
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '';
          }
          return null;
        },
      ),
    );
  }
}
