import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'login_screen.dart';
import '../providers/user_provider.dart';
import '../providers/medication_provider.dart';

class ProfileScreen extends StatefulWidget {
  final bool isGuest;
  const ProfileScreen({super.key, this.isGuest = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final medProvider = Provider.of<MedicationProvider>(context); // Listen to changes
    final user = userProvider.user;

    if (user != null && !_isEditing) {
      _nameController.text = user['name'] ?? '';
    }

    return Container(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _buildAccountCard(userProvider),
            const SizedBox(height: 20),
            _buildPremiumCard(),
            const SizedBox(height: 20),
            _buildStatsCard(userProvider, medProvider),
            const SizedBox(height: 20),
            _buildSettingsCard(),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                userProvider.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFECACA)),
                foregroundColor: const Color(0xFFEF4444),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(LucideIcons.logOut, size: 16),
                   SizedBox(width: 8),
                   Text('Logout'),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(UserProvider userProvider) {
    final user = userProvider.user;
    if (user == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.user, size: 32, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isEditing)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.check, size: 20, color: Color(0xFF22C55E)),
                            onPressed: () {
                              userProvider.updateName(_nameController.text);
                              setState(() => _isEditing = false);
                            },
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user['name'] ?? 'User',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.edit2, size: 16, color: Color(0xFF64748B)),
                            onPressed: () => setState(() => _isEditing = true),
                          ),
                        ],
                      ),
                    Text(user['email'] ?? '', style: const TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildInfoRow('Member Since', _formatDate(user['memberSince'])),
          const SizedBox(height: 12),
          _buildInfoRow('Account Type', 'Standard Free'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildPremiumCard() {
    // If used in context where user is logged in, show Activated.
    // However, the class uses `userProvider.user` to determine login status for display.
    // If userProvider.isAuthenticated is true, they are Premium (per user request).
    // If isGuest (isAuthenticated is false), show Get Premium -> Login.

    final isGuest = Provider.of<UserProvider>(context).user == null;

    if (!isGuest) {
       return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF166534)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(LucideIcons.crown, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Premium Active', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('You have full access', style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Upgrade to Premium', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(LucideIcons.crown, color: Colors.amber),
            ],
          ),
          const SizedBox(height: 16),
          _buildPremiumFeature(LucideIcons.check, 'Unlimited Medicine Scans'),
          const SizedBox(height: 8),
          _buildPremiumFeature(LucideIcons.check, 'Detailed Health Reports'),
          const SizedBox(height: 8),
          _buildPremiumFeature(LucideIcons.check, 'Priority Support'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
               // Redirect to Login
               Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
                );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2563EB),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Get Premium', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  Widget _buildStatsCard(UserProvider userProvider, MedicationProvider medProvider) {
    // Mock scan count or get from user profile if available
    final scanCount = userProvider.user != null ? (userProvider.user!['scanHistory'] as List?)?.length ?? 0 : 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Statistics', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('$scanCount', 'Scans Completed'), // Shows real history count if available (or 0)
              _buildStat('${medProvider.medications.length}', 'Medications Tracked'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSettingsActionItem('Notification Preferences', onTap: _showNotificationSettings),
          _buildSettingsActionItem('Change Password', onTap: _showChangePasswordDialog),
          const Divider(),
          _buildExpandableInfoItem('Privacy & Security', 'Your data is encrypted and secure. We do not share your personal health information with third parties without your explicit consent.\n\nRead our full Privacy Policy on our website.'),
          _buildExpandableInfoItem('Help & Support', 'Need help? Contact our support team at support@medsure.com or call our helpline 1-800-MEDSURE.\n\nFAQs:\n- How to scan?\n- How to add meds?'),
          _buildExpandableInfoItem('About Medsure', 'Medsure v1.0.0\n\nEmpowering you to take control of your medication safety. Verified and trusted by health professionals.'),
        ],
      ),
    );
  }

  Widget _buildSettingsActionItem(String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
            const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableInfoItem(String title, String content) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
      tilePadding: const EdgeInsets.symmetric(horizontal: 0),
      childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      shape: const Border(), // Remove borders
      children: [
        Text(content, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5)),
      ],
    );
  }

  void _showNotificationSettings() {
    bool pushEnabled = true;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Notification Preferences'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Push Notifications'),
                value: pushEnabled,
                onChanged: (val) => setState(() => pushEnabled = val),
              ),
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Email notifications are disabled.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Old Password'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: newPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
                validator: (val) => val!.length < 6 ? 'Min 6 chars' : null,
              ),
              TextFormField(
                controller: confirmPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
                validator: (val) => val != newPassController.text ? 'Mismatch' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Call provider to change password
                // For demo, just show success
                try {
                  await Provider.of<UserProvider>(context, listen: false)
                      .changePassword(oldPassController.text, newPassController.text);
                   if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
                   }
                } catch (e) {
                   // Handle error (requires re-auth usually)
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
