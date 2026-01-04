import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  final _personNameController = TextEditingController();
  
  String _medicineType = 'Tablet';
  String _forPerson = 'Self';
  int _dosesPerDay = 1;
  List<TimeOfDay> _reminderTimes = [const TimeOfDay(hour: 9, minute: 0)];
  bool _notificationsEnabled = true;
  bool _isLoading = false;

  final List<String> _medicineTypes = ['Tablet', 'Capsule', 'Syrup', 'Injection', 'Cream', 'Drops', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Medication', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Medicine Details'),
              const SizedBox(height: 16),
              
              _buildLabel('Medicine Name'),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Enter medicine name'),
                validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 20),
              
              _buildLabel('Medicine Type'),
              DropdownButtonFormField<String>(
                value: _medicineType,
                decoration: _inputDecoration(''),
                items: _medicineTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => _medicineType = val!),
              ),
              const SizedBox(height: 20),
              
              _buildLabel('Dosage Amount'),
              TextFormField(
                controller: _dosageController,
                decoration: _inputDecoration('Enter dosage (e.g., 500 mg)'),
                validator: (v) => v!.isEmpty ? 'Please enter dosage' : null,
              ),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Who is this for?'),
              const SizedBox(height: 16),
              
              // Self/Other Toggle
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _forPerson = 'Self'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _forPerson == 'Self' ? const Color(0xFF2563EB) : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.user, size: 18, color: _forPerson == 'Self' ? Colors.white : Colors.grey),
                              const SizedBox(width: 8),
                              Text('Self', style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _forPerson == 'Self' ? Colors.white : Colors.grey,
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _forPerson = 'Other'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _forPerson == 'Other' ? const Color(0xFF2563EB) : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.users, size: 18, color: _forPerson == 'Other' ? Colors.white : Colors.grey),
                              const SizedBox(width: 8),
                              Text('Other Person', style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _forPerson == 'Other' ? Colors.white : Colors.grey,
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (_forPerson == 'Other') ...[
                const SizedBox(height: 16),
                _buildLabel('Person\'s Name'),
                TextFormField(
                  controller: _personNameController,
                  decoration: _inputDecoration('Enter the person\'s name'),
                  validator: (v) => _forPerson == 'Other' && v!.isEmpty ? 'Please enter name' : null,
                ),
              ],
              
              const SizedBox(height: 32),
              _buildSectionTitle('Schedule'),
              const SizedBox(height: 16),
              
              _buildLabel('How many doses per day?'),
              _buildDoseCounter(),
              const SizedBox(height: 24),
              
              _buildLabel('Reminder Times'),
              Column(
                children: List.generate(_dosesPerDay, (index) => _buildTimePicker(index)),
              ),
              const SizedBox(height: 24),
              
              _buildLabel('Duration (Number of days)'),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Enter number of days (leave empty for ongoing)'),
              ),
              const SizedBox(height: 24),
              
              _buildLabel('Notes (Optional)'),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: _inputDecoration('Add any special instructions'),
              ),
              const SizedBox(height: 24),
              
              SwitchListTile(
                value: _notificationsEnabled,
                onChanged: (val) => setState(() => _notificationsEnabled = val),
                title: const Text('Enable Reminders', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Get notifications at reminder times', style: TextStyle(fontSize: 12)),
                activeColor: const Color(0xFF2563EB),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _saveMedication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Add Medication', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)));
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildDoseCounter() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _counterBtn(LucideIcons.minus, () {
            if (_dosesPerDay > 1) {
              setState(() {
                _dosesPerDay--;
                _reminderTimes.removeLast();
              });
            }
          }),
          Text('$_dosesPerDay', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          _counterBtn(LucideIcons.plus, () {
            if (_dosesPerDay < 6) {
              setState(() {
                _dosesPerDay++;
                _reminderTimes.add(const TimeOfDay(hour: 12, minute: 0));
              });
            }
          }),
        ],
      ),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: const Color(0xFF2563EB)),
      style: IconButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
    );
  }

  Widget _buildTimePicker(int index) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () async {
          final time = await showTimePicker(context: context, initialTime: _reminderTimes[index]);
          if (time != null) setState(() => _reminderTimes[index] = time);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dose ${index + 1} Time', style: const TextStyle(color: Color(0xFF1E293B))),
              Row(
                children: [
                  Text(_reminderTimes[index].format(context), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.clock, size: 16, color: Color(0xFF2563EB)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveMedication() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Convert TimeOfDay to formatted strings
      List<String> timeStrings = _reminderTimes
          .map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
          .toList();

      // Calculate end date if duration is provided
      DateTime? endDate;
      if (_durationController.text.isNotEmpty) {
        int days = int.tryParse(_durationController.text) ?? 0;
        if (days > 0) {
          endDate = DateTime.now().add(Duration(days: days));
        }
      }

      final med = Medication(
        id: '', // Firestore will generate this
        name: _nameController.text,
        dosage: _dosageController.text,
        frequency: '$_dosesPerDay times daily',
        times: timeStrings,
        startDate: DateTime.now(),
        endDate: endDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        notificationsEnabled: _notificationsEnabled,
        medicineType: _medicineType,
        forPerson: _forPerson,
        personName: _forPerson == 'Other' ? _personNameController.text : null,
      );

      final success = await Provider.of<MedicationProvider>(context, listen: false).addMedication(med);

      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.checkCircle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('${med.name} added successfully!'),
                ],
              ),
              backgroundColor: const Color(0xFF22C55E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add medication. Please try again.'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }
}
