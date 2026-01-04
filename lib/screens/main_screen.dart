import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'scan_auth_screen.dart';
import 'health_screen.dart';
import 'profile_screen.dart';
import 'medication_tracker_screen.dart';
import 'add_medication_screen.dart';

class MainScreen extends StatefulWidget {
  final bool isGuest;
  const MainScreen({super.key, this.isGuest = false});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  int _scanAuthInitialTab = 0;

  @override
  void initState() {
    super.initState();
    _updateLastActive();
  }

  Future<void> _updateLastActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_active_timestamp', DateTime.now().toIso8601String());
    // Also mark onboarding as seen once they reach main screen
    await prefs.setBool('onboarding_seen', true);
  }

  void _onItemTapped(int index, {int? subTab}) {
    _updateLastActive(); // Update on every major interaction
    setState(() {
      _selectedIndex = index;
      if (index == 1 && subTab != null) {
        _scanAuthInitialTab = subTab;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        isGuest: widget.isGuest,
        onTabChange: (index, {subTab}) => _onItemTapped(index, subTab: subTab),
      ),
      ScanAuthScreen(
        key: ValueKey('scan_auth_$_scanAuthInitialTab'),
        isGuest: widget.isGuest,
        initialTab: _scanAuthInitialTab,
      ),
      MedicationTrackerScreen(isGuest: widget.isGuest),
      const HealthScreen(),
      ProfileScreen(isGuest: widget.isGuest),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: GestureDetector(
          onTap: () => _onItemTapped(0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medication, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Medsure',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _onItemTapped(4),
            icon: Container(
              padding: const EdgeInsets.all(4), // Keep profile icon as requested
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.user, color: Color(0xFF2563EB), size: 18),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => _onItemTapped(index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: const Color(0xFF94A3B8),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.home, size: 20),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.shield, size: 20),
              label: 'Authenticate',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.pill, size: 20),
              label: 'Medication',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.fileText, size: 20),
              label: 'Health',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.user, size: 20),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
                );
              },
              backgroundColor: const Color(0xFF2563EB),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add Medication'),
            )
          : null,
    );
  }
}
