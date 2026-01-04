import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import 'add_medication_screen.dart';
import 'login_screen.dart';

class MedicationTrackerScreen extends StatefulWidget {
  final bool isGuest;
  const MedicationTrackerScreen({super.key, this.isGuest = false});

  @override
  State<MedicationTrackerScreen> createState() => _MedicationTrackerScreenState();
}

class _MedicationTrackerScreenState extends State<MedicationTrackerScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized && !widget.isGuest) {
      _loadMedications();
      _isInitialized = true;
    }
  }

  Future<void> _loadMedications() async {
    final provider = Provider.of<MedicationProvider>(context, listen: false);
    await provider.loadMedications();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isGuest) return _buildGuestGate(context);

    final provider = Provider.of<MedicationProvider>(context);
    final medications = provider.getTodaysMedications();

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          _buildHeader(),
          if (provider.isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadMedications,
                child: medications.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        itemCount: medications.length,
                        itemBuilder: (context, index) {
                          return _buildMedicationCard(context, medications[index], provider);
                        },
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: const BoxDecoration(
        color: Color(0xFFF97316),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medication Tracker',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Track your daily doses and stay on top of your health. \nGreen boxes indicate taken doses.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        Icon(LucideIcons.pill, size: 80, color: const Color(0xFFCBD5E1)),
        const SizedBox(height: 24),
        const Text(
          'No medications tracked',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add your first medication to start tracking',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  Widget _buildMedicationCard(BuildContext context, Medication med, MedicationProvider provider) {
    // Get icon based on medicine type
    IconData typeIcon = LucideIcons.pill;
    if (med.medicineType == 'Syrup') typeIcon = LucideIcons.glassWater;
    if (med.medicineType == 'Injection') typeIcon = LucideIcons.syringe;
    if (med.medicineType == 'Cream') typeIcon = LucideIcons.droplets;
    if (med.medicineType == 'Drops') typeIcon = LucideIcons.droplet;
    
    // Calculate days for tracking
    int totalDays = 0;
    if (med.endDate != null) {
      totalDays = med.endDate!.difference(med.startDate).inDays + 1;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: const Color(0xFF2563EB), size: 24),
              ),
              const SizedBox(width: 16),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            med.name, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(med.medicineType, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ),
                      ],
                    ),
                    Text(med.dosage, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    if (med.forPerson == 'Other' && med.personName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.user, size: 12, color: Color(0xFFF97316)),
                            const SizedBox(width: 4),
                            Text('For: ${med.personName}', style: const TextStyle(fontSize: 12, color: Color(0xFFF97316))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(LucideIcons.moreVertical, size: 20),
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteMedication(context, med, provider);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(LucideIcons.trash2, size: 16, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Date Tracking Boxes
          if (totalDays > 0 && totalDays <= 30) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Daily Tracking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569))),
            const SizedBox(height: 12),
            _buildTrackingBoxes(med, totalDays),
          ],
          
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(LucideIcons.repeat, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(med.frequency, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              const Spacer(),
              if (med.endDate != null) ...[
                const Icon(LucideIcons.calendar, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  'Until ${_formatDate(med.endDate!)}',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ],
          ),
          if (med.notes != null && med.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.stickyNote, size: 14, color: Color(0xFF64748B)),
                      SizedBox(width: 6),
                      Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(med.notes!, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Today\'s Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569))),
          const SizedBox(height: 12),
          Column(
            children: List.generate(med.times.length, (index) {
              return _buildDoseItem(context, med, index, provider);
            }),
          ),
          const SizedBox(height: 16),
          _buildAdherenceButton(context, med, provider),
        ],
      ),
    );
  }

  Widget _buildTrackingBoxes(Medication med, int totalDays) {
    final today = DateTime.now();
    final startDate = med.startDate;
    
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(totalDays > 30 ? 30 : totalDays, (index) {
        final boxDate = startDate.add(Duration(days: index));
        final dateKey = '${boxDate.year}-${boxDate.month.toString().padLeft(2, '0')}-${boxDate.day.toString().padLeft(2, '0')}';
        final isTaken = med.doseHistory[dateKey] == true;
        final isPast = boxDate.isBefore(DateTime(today.year, today.month, today.day));
        final isToday = boxDate.year == today.year && boxDate.month == today.month && boxDate.day == today.day;
        
        Color boxColor;
        if (isToday) {
          boxColor = const Color(0xFF2563EB); // Blue for today
        } else if (isTaken) {
          boxColor = const Color(0xFF22C55E); // Green for taken
        } else if (isPast) {
          boxColor = const Color(0xFFEF4444); // Red for missed
        } else {
          boxColor = const Color(0xFFE2E8F0); // Grey for future
        }
        
        return Tooltip(
          message: 'Day ${index + 1}: ${boxDate.day}/${boxDate.month}',
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: boxColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: boxColor == const Color(0xFFE2E8F0) ? Colors.grey : Colors.white,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDoseItem(BuildContext context, Medication med, int index, MedicationProvider provider) {
    final time = med.times[index];
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final isTaken = med.doseHistory[dateKey] == true;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            time,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Scheduled',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => _recordMedicationTaken(context, med, provider),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isTaken ? const Color(0xFF22C55E) : Colors.transparent,
                border: isTaken ? null : Border.all(color: const Color(0xFFCBD5E1), width: 2),
              ),
              child: Icon(LucideIcons.check, size: 16, color: isTaken ? Colors.white : const Color(0xFFCBD5E1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdherenceButton(BuildContext context, Medication med, MedicationProvider provider) {
    return OutlinedButton.icon(
      onPressed: () => _showAdherenceStats(context, med, provider),
      icon: const Icon(LucideIcons.barChart3, size: 16),
      label: const Text('View Adherence'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2563EB),
        side: const BorderSide(color: Color(0xFFBFDBFE)),
        minimumSize: const Size(double.infinity, 44),
      ),
    );
  }

  Future<void> _recordMedicationTaken(BuildContext context, Medication med, MedicationProvider provider) async {
    await provider.recordMedicationTaken(med.id, DateTime.now());
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Nice! You took ${med.name}'),
            ],
          ),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _showAdherenceStats(BuildContext context, Medication med, MedicationProvider provider) async {
    final stats = await provider.getAdherenceStats(med.id, days: 7);
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Weekly Adherence',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Taken', '${stats['taken']}', LucideIcons.checkCircle, const Color(0xFF22C55E)),
                _buildStatCard('Expected', '${stats['total']}', LucideIcons.calendar, const Color(0xFF2563EB)),
                _buildStatCard('Rate', '${stats['percentage'].toStringAsFixed(0)}%', LucideIcons.trendingUp, const Color(0xFFF97316)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }

  Future<void> _deleteMedication(BuildContext context, Medication med, MedicationProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete ${med.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.deleteMedication(med.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${med.name} deleted'),
            backgroundColor: const Color(0xFF64748B),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildGuestGate(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                child: const Icon(LucideIcons.lock, size: 64, color: Color(0xFF2563EB)),
              ),
              const SizedBox(height: 32),
              const Text(
                'Personalized Health Tracking',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Create an account to securely track your medications, set reminders, and monitor your health progress.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Login or Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
