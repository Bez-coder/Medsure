import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/custom_card.dart';

class HomeScreen extends StatelessWidget {
  final bool isGuest;
  final Function(int, {int? subTab})? onTabChange;
  const HomeScreen({super.key, this.isGuest = false, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(context),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Our Services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                _buildServiceGrid(context),
                const SizedBox(height: 32),
                const Text(
                  'Why Medsure?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                _buildWhyMedsureSection(),
                const SizedBox(height: 32),
                const Text(
                  'Trusted by Thousands',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTrustSection(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB),
        image: DecorationImage(
          image: AssetImage('assets/images/hero_bg.jpg'),
          fit: BoxFit.cover,
          opacity: 0.6,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.4),
              Colors.transparent,
              Colors.black.withOpacity(0.4),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                if (userProvider.isFetchingProfile) {
                  return const SizedBox(
                    height: 34,
                    width: 150,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }
                
                final name = userProvider.user?['name'] ?? 'User';
                return Text(
                  'Welcome, $name',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 2)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30),
              ),
              child: const Text(
                'Verify Medicines. Protect Lives.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildServiceCard(
          context,
          'Authenticate Medicine',
          'Verify medicine authenticity',
          LucideIcons.shield,
          const Color(0xFF2563EB),
          const BoxDecoration(
            color: Color(0xFF2563EB),
            shape: BoxShape.circle,
          ),
          () => onTabChange?.call(1, subTab: 0),
        ),
        _buildServiceCard(
          context,
          'Scan Medicine',
          'Quick barcode scanning',
          LucideIcons.scan,
          const Color(0xFF22C55E),
          const BoxDecoration(
            color: Color(0xFF22C55E),
            shape: BoxShape.circle,
          ),
          () => onTabChange?.call(1, subTab: 1),
        ),
        _buildServiceCard(
          context,
          'Health Articles',
          'Read health tips & guides',
          LucideIcons.fileText,
          const Color(0xFF9333EA),
          const BoxDecoration(
            color: Color(0xFF9333EA),
            shape: BoxShape.circle,
          ),
          () => onTabChange?.call(3),
        ),
        _buildServiceCard(
          context,
          'Medication Tracker',
          'Track your medications',
          LucideIcons.calendar,
          const Color(0xFFF97316),
          const BoxDecoration(
            color: Color(0xFFF97316),
            shape: BoxShape.circle,
          ),
          () => onTabChange?.call(2),
        ),
      ],
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    BoxDecoration decoration,
    VoidCallback onTap,
  ) {
    return _HoverServiceCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      iconDecoration: decoration,
      onTap: onTap,
    );
  }
}

class _HoverServiceCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final BoxDecoration iconDecoration;
  final VoidCallback onTap;

  const _HoverServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.iconDecoration,
    required this.onTap,
  });

  @override
  State<_HoverServiceCard> createState() => _HoverServiceCardState();
}

class _HoverServiceCardState extends State<_HoverServiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _isHovered ? widget.color.withOpacity(0.5) : const Color(0xFFE2E8F0)),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: widget.color.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: widget.iconDecoration,
                child: Icon(widget.icon, color: Colors.white, size: 20),
              ),
              const Spacer(),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
  Widget _buildWhyMedsureSection() {
    return Column(
      children: [
        _buildInfoItem(
          'Trusted Verification',
          'Advanced authentication technology to verify medicine authenticity and prevent counterfeit drugs',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          'Safety First',
          'Comprehensive database of medicines to ensure you’re taking safe and approved medications',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          'Always Reliable',
          '24/7 access to medicine verification and health information whenever you need it',
        ),
      ],
    );
  }

  Widget _buildInfoItem(String title, String desc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Soft Blue
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFBFDBFE),
                child: const Text('SJ', style: TextStyle(color: Color(0xFF1D4ED8))),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '“Medsure has given me peace of mind. I can now easily verify my medications and never miss a dose thanks to the reminder feature.”',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '- Sarah Johnson',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
            ),
          ),
          const Divider(color: Color(0xFFBFDBFE)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('50K+', 'Users'),
              _buildStatItem('1M+', 'Medicines Verified'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
