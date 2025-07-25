// lib/features/auth/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/text_fields/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'daviddasilva@gmail.com');
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Header
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lorem Ipsum is simply dummy text of the printing\nand typesetting industry',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 40),

              // Email Field
              Text(
                'Email or Phone Number',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _emailController,
                hintText: 'Enter your email',
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 24),

              // Password Field
              Text(
                'Password',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _passwordController,
                hintText: 'Enter your password',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Add navigation to forgot password screen
                  },
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 32),

              // Login Button
              PrimaryButton(
                text: 'Login',
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogin() {
    // Implement your login logic here
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    // Call your authentication provider
    // context.read<AuthProvider>().login(email, password);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}