import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Featured Articles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            _buildArticleCard(
              context,
              'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=800&q=80',
              'Medication Safety',
              '5 min read',
              'Understanding Your Medications',
              'Learn about different types of medications, how they work, and important safety information.',
              'Medications work in different ways to treat health problems. Some replace missing substances, others block chemical messages. It is vital to understand what you are taking, why you are taking it, and how to take it safely. \n\nAlways ask you doctor or pharmacist about:\n- Potential side effects\n- Interactions with food or other drugs\n- Proper storage',
            ),
            const SizedBox(height: 16),
            _buildArticleCard(
              context,
              'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?auto=format&fit=crop&w=800&q=80',
              'Storage Tips',
              '4 min read',
              'How to Store Medicines Properly',
              'Proper storage of medications is crucial for maintaining their effectiveness and safety.',
              'Heat, air, light, and moisture may damage your medicine. Store your medicines in a cool, dry place. For example, store it in your dresser drawer or a kitchen cabinet away from the stove, sink, and any hot appliances. \n\nThe bathroom is often not a good place to store medicines because of the moisture and heat from your shower/bath.',
            ),
            const SizedBox(height: 16),
            _buildArticleCard(
              context,
              'https://images.unsplash.com/photo-1576091160550-2173bd999c05?auto=format&fit=crop&w=800&q=80',
              'Safety Alert',
              '6 min read',
              'Recognizing Counterfeit Medicines',
              'Important signs to look for when checking if your medicine is genuine or fake.',
              'Counterfeit medicines are fake medicines. They may be contaminated or contain the wrong or no active ingredient. They could have the right active ingredient but at the wrong dose. Counterfeit medicines are illegal and may be harmful to your health. \n\nCheck for:\n- Spelling errors on packaging\n- Mismatched fonts\n- Different pill color/shape than usual',
            ),
            const SizedBox(height: 32),
            const Text('Quick Health Tips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            _buildTipItem(LucideIcons.heart, 'Never Share Prescriptions', 'Medications prescribed for one person may be harmful to another.'),
            _buildTipItem(LucideIcons.activity, 'Check Expiry Dates', 'Always check medicine expiry dates before use.'),
            _buildTipItem(LucideIcons.fileText, 'Read Instructions', 'Always read the patient information leaflet before taking any medicine.'),
            const SizedBox(height: 32),
            _buildEmergencyContacts(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, String imageUrl, String category, String readTime, String title, String description, String fullContent) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                              child: Text(category, style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                            ),
                            const Spacer(),
                            const Icon(LucideIcons.clock, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(readTime, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 12),
                        Text(description, style: const TextStyle(fontSize: 14, color: Color(0xFF475569))),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(fullContent, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.6)),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(LucideIcons.image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(category, style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      Icon(LucideIcons.clock, size: 12, color: const Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(readTime, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  const Text('Read More', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFFA855F7), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContacts() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Emergency Contacts', style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.bold, fontSize: 14)),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Poison Control:', style: TextStyle(color: Color(0xFFB91C1C), fontSize: 13)),
              Text('1-800-222-1222', style: TextStyle(color: Color(0xFFB91C1C), fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Emergency Services:', style: TextStyle(color: Color(0xFFB91C1C), fontSize: 13)),
              Text('911', style: TextStyle(color: Color(0xFFB91C1C), fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

