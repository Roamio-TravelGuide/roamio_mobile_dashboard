import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../../../../core/widgets/text_fields/custom_text_field.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;

  const NewPasswordScreen({super.key, required this.email});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  final Color _inputColor = const Color(0xFF818898);
  final Color _buttonColor = Colors.white;
  final Color _loginButtonColor = const Color(0xFF0F77EE);
  
  final FocusNode _newPasswordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _newPasswordFocusNode.addListener(() => setState(() {}));
    _confirmPasswordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordReset() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showError('Please fill all fields');
      return;
    }
    if (newPassword != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }
    if (newPassword.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate to login after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _navigateToLogin();
        }
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToLogin() {
    // Use Navigator.pushReplacement instead of pushAndRemoveUntil
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                'New Password',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a strong new password',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 40),

              // New Password Field
              Text(
                'New Password',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                focusNode: _newPasswordFocusNode,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.lightBlue,
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: _newPasswordFocusNode.hasFocus
                      ? const Color(0XFF063264).withOpacity(0.55)
                      : const Color(0xFF1A1B25),
                  hintText: 'Enter new password',
                  hintStyle: TextStyle(color: _inputColor),
                  prefixIcon: Icon(Icons.lock_outline, color: _inputColor),
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
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                      color: _inputColor,
                    ),
                    onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
              const SizedBox(height: 24),

              // Confirm Password Field
              Text(
                'Confirm Password',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                focusNode: _confirmPasswordFocusNode,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.lightBlue,
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: _confirmPasswordFocusNode.hasFocus
                      ? const Color(0XFF063264).withOpacity(0.55)
                      : const Color(0xFF1A1B25),
                  hintText: 'Confirm new password',
                  hintStyle: TextStyle(color: _inputColor),
                  prefixIcon: Icon(Icons.lock_outline, color: _inputColor),
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
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: _inputColor,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
              const SizedBox(height: 32),

              // Create Password Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handlePasswordReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    disabledBackgroundColor: _buttonColor.withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'Create New Password',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}