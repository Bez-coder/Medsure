import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/scan_service.dart';
import '../services/drug_search_service.dart';
import '../services/web_qr_service.dart';
import '../providers/user_provider.dart';

class ScanAuthScreen extends StatefulWidget {
  final bool isGuest;
  final int initialTab;
  const ScanAuthScreen({super.key, this.isGuest = false, this.initialTab = 0});

  @override
  State<ScanAuthScreen> createState() => _ScanAuthScreenState();
}

class _ScanAuthScreenState extends State<ScanAuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MobileScannerController? _scannerController;
  bool _isCameraStarted = false;
  bool _isProcessing = false;
  final ScanService _scanService = ScanService();
  final DrugSearchService _drugSearchService = DrugSearchService();
  final ImagePicker _imagePicker = ImagePicker();
  int _remainingScans = 5;
  bool _isUploadingImage = false;
  
  // Search tab state
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _codeController = TextEditingController(); // Added for Auth tab
  bool _isSearching = false;
  Map<String, dynamic>? _searchResults;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    
    _tabController.addListener(() {
      if (_tabController.index != 1) {
        _stopScanner();
        setState(() => _isCameraStarted = false);
      }
    });

    _loadRemainingScans();
  }

  Future<void> _loadRemainingScans() async {
    final remaining = await _scanService.getRemainingScans();
    if (mounted) {
      setState(() => _remainingScans = remaining);
    }
  }

  Future<void> _startScanner() async {
    if (_remainingScans <= 0 && widget.isGuest) {
      _showLimitExceededDialog();
      return;
    }
    
    setState(() => _isCameraStarted = true);
    _scannerController = MobileScannerController();
  }

  void _stopScanner() {
    _scannerController?.dispose();
    _scannerController = null;
    setState(() => _isCameraStarted = false);
  }

  void _showLimitExceededDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limit Reached'),
        content: const Text('You have reached your 5 free scans for this month. Please log in for unlimited access.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _disposeCamera() {
    _stopScanner();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController?.dispose();
    _searchController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _handleVerify(String code) async {
    setState(() => _isProcessing = true);
    
    try {
      final result = await _scanService.verifyMedicine(code);
      if (!mounted) return;
      
      setState(() => _isProcessing = false);
      
      if (result['code'] == 'LIMIT_REACHED') {
        _showLimitExceededDialog();
      } else {
        // Save to history if authenticated and valid
        if (result['isAuthentic'] == true && !widget.isGuest) {
          final scanData = result['data'] as Map<String, dynamic>? ?? {};
          Provider.of<UserProvider>(context, listen: false).addScanToHistory(scanData);
        }

        _showResultSheet(
          result['isAuthentic'] ?? false, 
          result['message'] ?? 'Unknown status',
          data: result['data'],
        );
        _loadRemainingScans(); // Refresh limits
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error communicating with server')),
        );
      }
    }
  }

  void _showResultSheet(bool isAuthentic, String message, {Map<String, dynamic>? data}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              _buildResultHeader(isAuthentic, message, isBanned: data?['status'] == 'Banned'),
              const SizedBox(height: 24),
              if (isAuthentic && data != null) _buildDetailedInfo(data),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAuthentic ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Confirm & Close', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader(bool isAuthentic, String message, {bool isBanned = false}) {
    final bool isPositive = isAuthentic && !isBanned;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPositive ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPositive ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
            child: Icon(isPositive ? LucideIcons.check : LucideIcons.x, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBanned ? 'MEDICINE BANNED' : (isAuthentic ? 'Verified Authentic' : 'Verification Failed'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? const Color(0xFF166534) : const Color(0xFF991B1B),
                  ),
                ),
                Text(
                  message,
                  style: TextStyle(
                    color: isPositive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                  ),
                ),
                if (isBanned)
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text(
                      'DO NOT USE THIS MEDICINE.',
                      style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo(Map<String, dynamic> data) {
    // Check status
    final status = data['status'] ?? 'Verified';
    final isVerified = status == 'Verified';
    final isBanned = status == 'Banned';
    
    // Check expiry
    bool isExpired = false;
    if (data['expiryTimestamp'] != null) {
      final expiryDate = (data['expiryTimestamp'] as dynamic).toDate();
      isExpired = DateTime.now().isAfter(expiryDate);
    } else if (data['expiryDate'] != null) {
      // Parse MM/YYYY format
      final parts = data['expiryDate'].toString().split('/');
      if (parts.length == 2) {
        final month = int.tryParse(parts[0]) ?? 1;
        final year = int.tryParse(parts[1]) ?? 2099;
        final expiryDate = DateTime(year, month + 1, 0); // Last day of month
        isExpired = DateTime.now().isAfter(expiryDate);
      }
    }
    
    return Column(
      children: [
        // Status Badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isBanned || isExpired ? Colors.red[50] : Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isBanned || isExpired ? Colors.red[300]! : Colors.green[300]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isBanned ? LucideIcons.xCircle : (isExpired ? LucideIcons.alertTriangle : LucideIcons.checkCircle),
                color: isBanned || isExpired ? Colors.red[700] : Colors.green[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isBanned ? 'BANNED' : (isExpired ? 'EXPIRED' : 'VERIFIED'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isBanned || isExpired ? Colors.red[700] : Colors.green[700],
                ),
              ),
            ],
          ),
        ),
        
        _buildInfoGrid([
          {'label': 'Name:', 'value': data['name'] ?? 'N/A'},
          {'label': 'Manufacturer:', 'value': data['manufacturer'] ?? 'N/A'},
        ]),
        const SizedBox(height: 16),
        _buildInfoGrid([
          {'label': 'Type:', 'value': data['medicineType'] ?? 'N/A'},
          {'label': 'Dosage:', 'value': data['dosage'] ?? 'N/A'},
        ]),
        const SizedBox(height: 16),
        _buildInfoGrid([
          {'label': 'Manufactured:', 'value': data['manufacturedDate'] ?? 'N/A'},
          {'label': 'Expiry Date:', 'value': '${data['expiryDate'] ?? 'N/A'}${isExpired ? ' ⚠' : ''}'},
        ]),
        const SizedBox(height: 16),
        _buildInfoGrid([
          {'label': 'Batch No:', 'value': data['batchNo'] ?? 'N/A'},
          {'label': 'Route:', 'value': data['route'] ?? 'N/A'},
        ]),
        const SizedBox(height: 16),
        _buildFullWidthInfo('Purpose:', data['purpose'] ?? 'N/A'),
        const SizedBox(height: 12),
        _buildFullWidthInfo('Side Effects:', data['sideEffects'] ?? 'N/A'),
        const SizedBox(height: 12),
        _buildFullWidthInfo('Warnings:', data['warnings'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildInfoGrid(List<Map<String, String>> items) {
    return Row(
      children: items.map((item) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['label']!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            Text(item['value']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildFullWidthInfo(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              onTap: (index) => setState(() {}),
              tabs: const [
                Tab(text: 'Authenticate'),
                Tab(text: 'Scan'),
                Tab(text: 'Search'),
              ],
              indicatorColor: const Color(0xFF2563EB),
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: const Color(0xFF94A3B8),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAuthenticateView(),
                _buildScanView(),
                _buildSearchView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticateView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Authenticate Medicine',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isGuest 
              ? 'Guest Limit: $_remainingScans scans left this month.'
              : 'Verify medicine authenticity by entering the product code.',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter Medicine Code',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter the unique code from your medicine packaging',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Medicine Code',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _codeController, // Added controller
                  decoration: InputDecoration(
                    hintText: 'e.g., MED123456789',
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _handleVerify,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isProcessing ? null : () => _handleVerify(_codeController.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isProcessing 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.shield, size: 18, color: Colors.white.withOpacity(0.8)),
                        const SizedBox(width: 8),
                        const Text('Verify Authenticity'),
                      ],
                    ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How to Find Your Medicine Code',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildHowToStep('1. Look for a unique alphanumeric code on the medicine packaging'),
                _buildHowToStep('2. The code is usually printed near the barcode or on a security seal'),
                _buildHowToStep('3. It may be hidden under a scratch panel'),
                _buildHowToStep('4. Each code is unique and can only be verified once'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
      ),
    );
  }

  Widget _buildScanView() {
    // Use platform-specific UI
    return kIsWeb ? _buildWebScanView() : _buildMobileScanView();
  }

  // Web: Image upload for QR decoding
  Widget _buildWebScanView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scan Medicine',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isGuest 
              ? 'Guest Limit: $_remainingScans scans left this month.'
              : 'Upload a QR code image to verify',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 32),
          Container(
            height: 350,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.upload, size: 48, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Upload QR Code Image',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select an image containing a QR code',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isUploadingImage ? null : _handleImageUpload,
                    icon: _isUploadingImage 
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(LucideIcons.image),
                    label: Text(_isUploadingImage ? 'Processing...' : 'Choose Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.info, color: Color(0xFFD97706), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'For live camera scanning, please use the mobile app.',
                    style: TextStyle(color: Colors.amber[900], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tips for Image Upload',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildHowToStep('• Ensure the QR code is clearly visible in the image'),
                _buildHowToStep('• Use a well-lit, high-quality image'),
                _buildHowToStep('• Avoid blurry or distorted images'),
                _buildHowToStep('• Crop the image to focus on the QR code if needed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImageUpload() async {
    if (_remainingScans <= 0 && widget.isGuest) {
      _showLimitExceededDialog();
      return;
    }

    setState(() => _isUploadingImage = true);

    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      
      if (image == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      // Read image bytes
      final bytes = await image.readAsBytes();
      
      // Use WebQRService to decode QR from image
      final qrData = await WebQRService.decodeFromBytes(bytes);

      if (!mounted) return;

      if (qrData != null && qrData.isNotEmpty) {
        setState(() => _isUploadingImage = false);
        _handleVerify(qrData);
        return;
      }

      // No QR code found in image
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No QR code found in the selected image'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  // Mobile: Native camera scanner
  Widget _buildMobileScanView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scan Medicine',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isGuest 
              ? 'Guest Limit: $_remainingScans scans left this month.'
              : 'Scan the QR code on the medicine packaging to verify its authenticity.',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 32),
          Container(
            height: 350,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: !_isCameraStarted
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.qrCode, size: 48, color: Colors.white30),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _startScanner,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Start Scanner', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            if (barcode.rawValue != null && !_isProcessing) {
                              _handleVerify(barcode.rawValue!);
                            }
                          }
                        },
                      ),
                      Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isCameraStarted ? _stopScanner : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Stop Scanner'),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scanning Tips',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildHowToStep('• Ensure good lighting for accurate scanning'),
                _buildHowToStep('• Hold your phone steady and align the barcode in the frame'),
                _buildHowToStep('• Make sure the barcode is clean and not damaged'),
                _buildHowToStep('• Keep a distance of 10-15cm from the barcode'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Drug Search',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search for drug information using openFDA database',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Search for Medicine',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter the generic name of the medicine',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Medicine Name',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Aspirin, Ibuprofen',
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _handleSearch(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSearching ? null : _handleSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSearching
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.search, size: 18, color: Colors.white.withOpacity(0.8)),
                            const SizedBox(width: 8),
                            const Text('Search Drug'),
                          ],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_hasSearched) _buildSearchResults(),
        ],
      ),
    );
  }

  void _handleSearch() async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a medicine name')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = false;
    });

    try {
      final results = await _drugSearchService.searchDrug(_searchController.text.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _hasSearched = true;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _hasSearched = true;
          _searchResults = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildSearchResults() {
    if (_searchResults == null || _searchResults!['found'] == false) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.alertCircle, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Results Found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                  ),
                  Text(
                    'No drug information found for this search term',
                    style: TextStyle(color: Color(0xFFB91C1C)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final data = _searchResults!['data'] as Map<String, dynamic>;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.checkCircle, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Drug Information',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildResultTable(data),
        ],
      ),
    );
  }

  Widget _buildResultTable(Map<String, dynamic> data) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(2),
      },
      border: TableBorder.all(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(8),
      ),
      children: [
        _buildTableRow('Generic Name', data['genericName'] ?? 'N/A', isHeader: true),
        _buildTableRow('Purpose / Indication', data['purpose'] ?? 'N/A'),
        _buildTableRow('Standard Dosage', data['dosage'] ?? 'N/A'),
        _buildTableRow('Warnings', data['warnings'] ?? 'N/A'),
        _buildTableRow('Common Side Effects', data['sideEffects'] ?? 'N/A'),
        _buildTableRow('Authorization Status', data['authorizationStatus'] ?? 'N/A', isLast: true),
      ],
    );
  }

  TableRow _buildTableRow(String label, String value, {bool isHeader = false, bool isLast = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? const Color(0xFFF8FAFC) : Colors.white,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: const Color(0xFF475569),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF1E293B),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
