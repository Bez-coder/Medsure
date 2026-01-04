
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class MedicineRegistrationScreen extends StatefulWidget {
  const MedicineRegistrationScreen({super.key});

  @override
  State<MedicineRegistrationScreen> createState() => _MedicineRegistrationScreenState();
}

class _MedicineRegistrationScreenState extends State<MedicineRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  // Controllers
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _dosageController = TextEditingController();
  final _purposeController = TextEditingController();
  final _sideEffectsController = TextEditingController();
  final _warningsController = TextEditingController();

  // Date fields
  DateTime? _expiryDate;
  DateTime? _manufacturedDate;

  // Dropdown values
  String _medicineType = 'Tablet';
  String _routeOfAdmin = 'Oral';
  String _status = 'Verified';

  // Options
  final List<String> _medicineTypes = ['Tablet', 'Capsule', 'Syrup', 'Injection', 'Cream', 'Drops'];
  final List<String> _routes = ['Oral', 'Injection', 'Topical', 'Inhalation', 'Sublingual', 'Rectal'];
  final List<String> _statuses = ['Verified', 'Banned'];

  bool _isLoading = false;
  String? _generatedBatchNo;
  String? _registeredMedicineId;
  bool _isSuccess = false;

  void _generateBatchNumber() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String randomString(int length) => String.fromCharCodes(
          Iterable.generate(
            length, 
            (_) => chars.codeUnitAt(random.nextInt(chars.length)),
          ),
        );
    
    setState(() {
      _generatedBatchNo = 'MDS-${randomString(4)}-${randomString(4)}';
    });
  }

  @override
  void initState() {
    super.initState();
    _generateBatchNumber();
  }

  Future<void> _selectDate(BuildContext context, bool isExpiry) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isExpiry 
          ? DateTime.now().add(const Duration(days: 365))
          : DateTime.now(),
      firstDate: isExpiry ? DateTime.now() : DateTime(2020),
      lastDate: isExpiry ? DateTime(2035) : DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _manufacturedDate = picked;
        }
      });
    }
  }

  Future<void> _registerMedicine() async {
    if (_formKey.currentState!.validate()) {
      if (_expiryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select expiry date'), backgroundColor: Colors.orange),
        );
        return;
      }
      if (_manufacturedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select manufactured date'), backgroundColor: Colors.orange),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final docRef = _firestore.collection('medicines').doc();
        
        final medicineData = {
          'medicineId': docRef.id,
          'name': _nameController.text.trim(),
          'manufacturer': _manufacturerController.text.trim(),
          'dosage': _dosageController.text.trim(),
          'expiryDate': DateFormat('MM/yyyy').format(_expiryDate!),
          'manufacturedDate': DateFormat('MM/yyyy').format(_manufacturedDate!),
          'expiryTimestamp': Timestamp.fromDate(_expiryDate!),
          'batchNo': _generatedBatchNo,
          'medicineType': _medicineType,
          'purpose': _purposeController.text.trim(),
          'route': _routeOfAdmin,
          'sideEffects': _sideEffectsController.text.trim(),
          'warnings': _warningsController.text.trim(),
          'isAuthentic': _status == 'Verified',
          'registeredAt': FieldValue.serverTimestamp(),
          'status': _status,
        };

        await docRef.set(medicineData);

        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSuccess = true;
            _registeredMedicineId = docRef.id;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medicine Registered Successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _resetForm() {
    // _formKey.currentState?.reset(); // Form is not in tree when this is called
    _nameController.clear();
    _manufacturerController.clear();
    _dosageController.clear();
    _purposeController.clear();
    _sideEffectsController.clear();
    _warningsController.clear();
    _generateBatchNumber();
    setState(() {
      _isSuccess = false;
      _registeredMedicineId = null;
      _expiryDate = null;
      _manufacturedDate = null;
      _medicineType = 'Tablet';
      _routeOfAdmin = 'Oral';
      _status = 'Verified';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return _buildSuccessView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Medicine'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Basic Information'),
              _buildTextField('Medicine Name', _nameController, icon: LucideIcons.pill),
              _buildTextField('Manufacturer', _manufacturerController, icon: LucideIcons.factory),
              Row(
                children: [
                  Expanded(child: _buildTextField('Dosage (e.g., 500mg)', _dosageController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdown('Medicine Type', _medicineType, _medicineTypes, (val) => setState(() => _medicineType = val!))),
                ],
              ),
              const SizedBox(height: 16),
              
              // Date pickers row
              Row(
                children: [
                  Expanded(child: _buildDatePicker('Manufactured Date', _manufacturedDate, false)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDatePicker('Expiry Date', _expiryDate, true)),
                ],
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Medical Details'),
              _buildTextField('Purpose/Indication', _purposeController, maxLines: 2),
              _buildDropdown('Route of Administration', _routeOfAdmin, _routes, (val) => setState(() => _routeOfAdmin = val!)),
              const SizedBox(height: 16),
              _buildTextField('Side Effects', _sideEffectsController, maxLines: 3),
              _buildTextField('Warnings', _warningsController, maxLines: 3),

              const SizedBox(height: 24),
              _buildSectionTitle('Status & Authorization'),
              _buildStatusSelector(),

              const SizedBox(height: 24),
              _buildSectionTitle('System Generation'),
              _buildBatchNumberDisplay(),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerMedicine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Register & Generate QR',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, bool isExpiry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _selectDate(context, isExpiry),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(LucideIcons.calendar, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          child: Text(
            date != null ? DateFormat('MMM yyyy').format(date) : 'Select date',
            style: TextStyle(
              color: date != null ? Colors.black : Colors.grey[500],
              fontStyle: date == null ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _status == 'Verified' ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _status == 'Verified' ? Colors.green[300]! : Colors.red[300]!),
      ),
      child: Row(
        children: [
          Icon(
            _status == 'Verified' ? LucideIcons.checkCircle : LucideIcons.xCircle,
            color: _status == 'Verified' ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Authorization Status', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  value: _status,
                  underline: const SizedBox(),
                  isExpanded: true,
                  items: _statuses.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      s,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: s == 'Verified' ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  )).toList(),
                  onChanged: (val) => setState(() => _status = val!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchNumberDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.qrCode, color: Colors.blue),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Batch Number', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                _generatedBatchNo ?? 'Generating...',
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Monospace',
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _generateBatchNumber,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration Complete')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _status == 'Verified' ? LucideIcons.checkCircle : LucideIcons.xCircle,
                color: _status == 'Verified' ? Colors.green : Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Medicine Registered!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${_nameController.text} has been added to database.',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _status == 'Verified' ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _status == 'Verified' ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: _registeredMedicineId!,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Scan this QR Code to Verify',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _generatedBatchNo ?? '',
                      style: const TextStyle(
                        fontFamily: 'Monospace',
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Exit Admin'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _resetForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Register Another', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    TextEditingController controller, 
    {IconData? icon, int maxLines = 1}
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Enter $label',
          hintStyle: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required field';
          }
          return null;
        },
      ),
    );
  }
}
