import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Authenticate Medicines',
      description: 'instantly verify the authenticity of your medicines using our advanced scan technology.',
      icon: Icons.qr_code_scanner,
      color: const Color(0xFF007AFF),
    ),
    OnboardingData(
      title: 'Track Your Health',
      description: 'Keep a digital log of your medication history and health metrics in one secure place.',
      icon: Icons.health_and_safety,
      color: const Color(0xFF34C759),
    ),
    OnboardingData(
      title: 'Never Miss a Dose',
      description: 'Receive personalized reminders for all your medications. Create an account to sync across devices.',
      icon: Icons.notifications_active,
      color: const Color(0xFFFF9500),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(bottom: 80),
        child: PageView.builder(
          controller: _controller,
          onPageChanged: (index) {
            setState(() {
              isLastPage = index == _pages.length - 1;
            });
          },
          itemCount: _pages.length,
          itemBuilder: (context, index) {
            return _buildPage(_pages[index]);
          },
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        height: 120,
        color: Colors.white,
        child: Column(
          children: [
            Center(
              child: SmoothPageIndicator(
                controller: _controller,
                count: _pages.length,
                effect: const WormEffect(
                  dotHeight: 10,
                  dotWidth: 10,
                  activeDotColor: Color(0xFF007AFF),
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _controller.jumpToPage(_pages.length - 1),
                  child: const Text('SKIP', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (isLastPage) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 50),
                    backgroundColor: const Color(0xFF007AFF),
                  ),
                  child: Text(isLastPage ? 'GET STARTED' : 'NEXT'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: data.color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(data.icon, size: 100, color: data.color),
        ),
        const SizedBox(height: 64),
        Text(
          data.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF030213),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            data.description,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF717182),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
