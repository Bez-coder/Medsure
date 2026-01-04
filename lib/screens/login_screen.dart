import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_card.dart';
import 'main_screen.dart';
import 'signup_screen.dart';
import 'admin/admin_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.login(
      _emailController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen(isGuest: false)),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Please check your credentials.')),
      );
    }
  }

  void _handleGoogleLogin() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      final success = await userProvider.signInWithGoogle();
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen(isGuest: false)),
        );
      }
    } catch (e) {
      if (mounted) {
        String message = 'Google sign in failed.';
        final errorStr = e.toString().toLowerCase();
        bool isConfigError = false;

        if (errorStr.contains('popup_closed')) {
          message = 'Google sign in was cancelled or requires configuration.';
          isConfigError = true;
        } else if (errorStr.contains('invalid_client') || errorStr.contains('401')) {
          message = 'Developer Error: Invalid Google Client ID. Check auth_service.dart';
          isConfigError = true;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isConfigError ? Colors.orange[800] : Colors.red,
            duration: const Duration(seconds: 8),
            action: isConfigError ? SnackBarAction(
              label: 'USE DEMO',
              textColor: Colors.white,
              onPressed: () async {
                final demoSuccess = await userProvider.signInWithDemoGoogle();
                if (demoSuccess && mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const MainScreen(isGuest: false)),
                  );
                }
              },
            ) : null,
          ),
        );
      }
    }
  }

  void _handleGuestLogin() {
    Provider.of<UserProvider>(context, listen: false).logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen(isGuest: true)),
    );
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                        'Medsure',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Verify Medicines. Protect Lives.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF717182),
                        ),
                      ),
                      const SizedBox(height: 32),
                      CustomInput(
                        label: 'Email',
                        placeholder: 'Enter your email',
                        controller: _emailController,
                      ),
                      const SizedBox(height: 20),
                      CustomInput(
                        label: 'Password',
                        placeholder: 'Enter your password',
                        isPassword: true,
                        controller: _passwordController,
                      ),
                      const SizedBox(height: 24),
                      Consumer<UserProvider>(
                        builder: (context, userProvider, _) {
                          return userProvider.isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _handleLogin,
                                  child: const Text('Sign In'),
                                ),
                              );
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 40, child: const Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR CONTINUE WITH',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(width: 40, child: const Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _handleGoogleLogin,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            foregroundColor: const Color(0xFF1E293B),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Using colored icon to mimic Google logo slightly better than plain grey
                              Icon(LucideIcons.chrome, size: 20, color: Colors.blue[600]), 
                              const SizedBox(width: 12),
                              const Text(
                                'Continue with google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?", style: TextStyle(color: Color(0xFF64748B))),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const SignUpScreen()),
                              );
                            },
                            child: const Text('Create one', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _handleGuestLogin,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            foregroundColor: const Color(0xFF007AFF),
                          ),
                          child: const Text('Continue without login'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                          );
                        },
                        icon: const Icon(LucideIcons.shieldAlert, size: 16, color: Colors.grey),
                        label: const Text(
                          'Admin Portal',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Guest users can scan and authenticate medicines (limit 6/month). Logged-in users get full history, tracking, and reminders.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
