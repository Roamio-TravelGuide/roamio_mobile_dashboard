import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/widgets/text_fields/custom_text_field.dart';
import '../../api/auth_api.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final AuthApi authApi;
  
  const ForgotPasswordScreen({
    super.key,
    required this.authApi,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _storedEmail;
  String? _storedOtp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Forgot Password',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your email to receive a verification code',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 40),

              // Email Field
              const Text(
                'Email',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _emailController,
                hintText: 'Enter your email',
                prefixIcon: Icons.email_outlined,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  filled: true,
                  fillColor: Color(0xFF1A1A23),
                  hintText: 'Enter your email',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.white),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 32),

              // Send OTP Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: MaterialButton(
                  onPressed: _isLoading ? null : _handleSendOTP,
                  color: Colors.white,
                  textColor: Colors.black,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Send OTP',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSendOTP() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError('Please enter your email');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final result = await widget.authApi.forgotPassword(email);
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        if (result['success']) {
          _storedEmail = email;
          _showSuccessMessage(result['message'] ?? 'OTP sent successfully');
          _showOTPDialog(email);
        } else {
          _showError(result['message'] ?? 'Failed to send OTP');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Network error: ${e.toString()}');
      }
    }
  }

  void _showOTPDialog(String email) {
    final List<TextEditingController> otpControllers = 
        List.generate(6, (index) => TextEditingController());
    final List<FocusNode> otpFocusNodes = 
        List.generate(6, (index) => FocusNode());
    bool isLoading = false;
    Timer? timer;
    int remainingTime = 60; // 1 minute in seconds

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Start timer on first build
            if (timer == null) {
              timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
                if (remainingTime > 0) {
                  setState(() {
                    remainingTime--;
                  });
                } else {
                  t.cancel();
                }
              });
            }

            String formatTime(int seconds) {
              int minutes = seconds ~/ 60;
              int remainingSeconds = seconds % 60;
              return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
            }

            void handleOTPInput(int index, String value) {
              if (value.isNotEmpty && index < 5) {
                otpFocusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                otpFocusNodes[index - 1].requestFocus();
              }
            }

            String getOTPCode() {
              return otpControllers.map((controller) => controller.text).join();
            }

            Future<void> _resendCode() async {
              timer?.cancel();
              Navigator.of(context).pop();
              
              // Wait for the dialog to be fully dismissed before showing a new one
              await Future.delayed(const Duration(milliseconds: 300));
              
              _handleSendOTP(); // Resend code
            }

            return WillPopScope(
              
              onWillPop: () async {
                timer?.cancel();
                return true;
              },
              child: AlertDialog(
                backgroundColor: const Color(0xFF1A1A23),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Enter Verification Code',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'We sent a 6-digit code to $email',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    
                    // OTP Input Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 40,
                          height: 50,
                          child: TextField(
                            controller: otpControllers[index],
                            focusNode: otpFocusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            cursorColor: Colors.lightBlue,
                            decoration: InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF2D2E3A)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.lightBlue, width: 1),
                              ),
                              filled: true,
                              fillColor:const Color(0xFF1A1B25),
                            ),
                            onChanged: (value) => handleOTPInput(index, value),
                          ),
                        );
                      }),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Timer Display
                    if (remainingTime > 0)
                      Text(
                        'Time remaining: ${formatTime(remainingTime)}',
                        style: const TextStyle(color: Colors.orange, fontSize: 14),
                      )
                    else
                      const Text(
                        'OTP Expired',
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: remainingTime > 0 ? null : _resendCode,
                    child: Text(
                      'Resend Code',
                      style: TextStyle(
                        color: remainingTime > 0 ? Colors.grey : Colors.blue,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: (isLoading || remainingTime == 0)
                        ? null
                        : () async {
                            final code = getOTPCode();
                            if (code.length != 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid 6-digit code'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            setState(() => isLoading = true);
                            
                            try {
                              final result = await widget.authApi.verifyOTP(email, code);
                              
                              if (mounted) {
                                if (result['success']) {
                                  timer?.cancel();
                                  _storedOtp = code;
                                  Navigator.of(context).pop();
                                  _showResetPasswordDialog();
                                } else {
                                  setState(() => isLoading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result['message'] ?? 'OTP verification failed'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(() => isLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Network error: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Verify',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // Clean up timer and controllers when dialog is dismissed
      timer?.cancel();
      for (var controller in otpControllers) {
        controller.dispose();
      }
      for (var focusNode in otpFocusNodes) {
        focusNode.dispose();
      }
    });
  }

  void _showResetPasswordDialog() {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A23),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Reset Password',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0D0D12),
                      hintText: 'New password',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0D0D12),
                      hintText: 'Confirm password',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final newPassword = newPasswordController.text.trim();
                          final confirmPassword = confirmPasswordController.text.trim();

                          if (newPassword.isEmpty || confirmPassword.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in all fields'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (newPassword.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password must be at least 6 characters'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (newPassword != confirmPassword) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Passwords do not match'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (_storedEmail == null || _storedOtp == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Session expired. Please start over.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            Navigator.of(context).pop();
                            return;
                          }

                          setState(() => isLoading = true);
                          
                          try {
                            final result = await widget.authApi.resetPasswordWithOTP(
                              _storedEmail!,
                              _storedOtp!,
                              newPassword,
                            );
                            
                            if (mounted) {
                              if (result['success']) {
                                Navigator.of(context).pop();
                                _showSuccessDialog();
                              } else {
                                setState(() => isLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ?? 'Password reset failed'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() => isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Network error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Reset Password',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A23),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 48,
          ),
          content: Text(
            'Password Reset Successfully',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close success dialog
                  Navigator.of(context).pop(); // Go back to login
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Continue to Login',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}