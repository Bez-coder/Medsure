import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_card.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.signUp(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen(isGuest: false)),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup failed. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFF6FF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: CustomCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Color(0xFF007AFF),
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/medsure_logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                          // child: const Icon(Icons.medication, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Create Account',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Protecting Lives, One Scan At A Time',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF717182),
                          ),
                        ),
                        const SizedBox(height: 32),
                        CustomInput(
                          label: 'Name',
                          placeholder: 'Enter Your Name',
                          controller: _nameController,
                          validator: (val) => val == null || val.isEmpty ? 'Field required' : null,
                        ),
                        const SizedBox(height: 20),
                        CustomInput(
                          label: 'Email',
                          placeholder: 'Enter Your Email',
                          controller: _emailController,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Field required';
                            if (!val.contains('@') || !val.contains('.')) return 'Invalid email format';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        CustomInput(
                          label: 'Password',
                          placeholder: 'Enter Your Password',
                          isPassword: true,
                          controller: _passwordController,
                          validator: (val) {
                             if (val == null || val.isEmpty) return 'Field required';
                             if (val.length < 6) return 'Password must be at least 6 characters';
                             return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        CustomInput(
                          label: 'Confirm Password',
                          placeholder: 'Confirm Password',
                          isPassword: true,
                          controller: _confirmPasswordController,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Field required';
                            if (val != _passwordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        Consumer<UserProvider>(
                          builder: (context, userProvider, _) {
                            return userProvider.isLoading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _handleSignUp,
                                    child: const Text('Sign Up'),
                                  ),
                                );
                          },
                        ),
                        // Removed "Continue with Google" section
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account?', style: TextStyle(color: Color(0xFF64748B))),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Login', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
