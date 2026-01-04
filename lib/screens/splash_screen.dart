import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  _navigateToNext() async {
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
    final String? lastActiveStr = prefs.getString('last_active_timestamp');
    
    // Check Firebase Auth first (Permanent Login)
    final currentUser = FirebaseAuth.instance.currentUser;
    
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    if (currentUser != null) {
      // User is logged in, go to home
      _goToHome(isGuest: false);
      return;
    }

    // Check for Recent Guest Session (10 minute limit)
    if (lastActiveStr != null) {
      final lastActive = DateTime.parse(lastActiveStr);
      final difference = DateTime.now().difference(lastActive);
      
      if (difference.inMinutes < 10) {
        _goToHome(isGuest: true);
        return;
      }
    }

    // Default flow: Onboarding or Login
    if (onboardingSeen) {
      // If they've see onboarding but session expired, go to login
      // Actually, user just said "don't ask to login", so we can go to LoginScreen directly
      // but if we want to be nice, just skip onboarding.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()), 
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  void _goToHome({required bool isGuest}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MainScreen(isGuest: isGuest)),
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
            colors: [Color(0xFFEBF8FF), Colors.white],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(
              child: Container(
                width: 100,
                height: 100,
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
              ),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: Text(
                'Medsure',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: const Color(0xFF007AFF),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeInUp(
              delay: const Duration(milliseconds: 1000),
              child: Text(
                'Protecting Lives, One Scan at a Time',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 100),
            FadeIn(
              delay: const Duration(milliseconds: 1500),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
