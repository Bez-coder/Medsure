import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ScanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> verifyMedicine(String medicineId) async {
    try {
      final cleanId = medicineId.trim();
      debugPrint('🔎 Verifying medicine: "$cleanId"');

      // 1. Try Direct Lookup (Medicine ID / QR Code)
      DocumentSnapshot? medicineDoc;
      final docRef = _firestore.collection('medicines').doc(cleanId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        debugPrint('✅ Found verify direct Doc ID: $cleanId');
        medicineDoc = docSnapshot;
      } else {
        debugPrint('⚠️ Doc ID not found. Trying Batch Number query...');
        
        // 2. Try Lookup by Batch Number (Manual Entry)
        // Try exact match first
        var querySnapshot = await _firestore
            .collection('medicines')
            .where('batchNo', isEqualTo: cleanId)
            .limit(1)
            .get();

        // If not found, try Uppercase (common for manual entry)
        if (querySnapshot.docs.isEmpty) {
           debugPrint('⚠️ Exact batch match failed. Trying Uppercase: ${cleanId.toUpperCase()}');
           querySnapshot = await _firestore
            .collection('medicines')
            .where('batchNo', isEqualTo: cleanId.toUpperCase())
            .limit(1)
            .get();
        }

        if (querySnapshot.docs.isNotEmpty) {
          debugPrint('✅ Found via Batch Number: ${querySnapshot.docs.first.id}');
          medicineDoc = querySnapshot.docs.first;
        }
      }

      if (medicineDoc == null || !medicineDoc.exists) {
        return {
          'isAuthentic': false,
          'message': 'Not registered under EFDA',
          'code': 'NOT_FOUND',
        };
      }

      // Check scan limits for guest users
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        // Guest user - check scan limit
        int remainingScans = await getRemainingScans();
        if (remainingScans <= 0) {
          return {
            'isAuthentic': false,
            'message': 'Scan limit reached. Please log in for unlimited scans.',
            'code': 'LIMIT_REACHED',
          };
        }

        // Decrement guest scans (store in local or session)
        // For now, we'll track in Firestore with device ID
        await _recordGuestScan();
      }

      // Record scan in user's history (if logged in)
      if (currentUser != null) {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('medication_history')
            .add({
          'medicineId': medicineId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Get medicine data
      Map<String, dynamic> medicineData = medicineDoc.data() as Map<String, dynamic>;

      return {
        'isAuthentic': true,
        'message': 'Medicine verified successfully',
        'code': 'SUCCESS',
        'data': medicineData,
      };
    } catch (e) {
      return {
        'isAuthentic': false,
        'message': 'Error verifying medicine: $e',
        'code': 'ERROR',
      };
    }
  }

  Future<int> getRemainingScans() async {
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      // Logged-in users have unlimited scans
      return 999;
    }

    // Guest users have limited scans
    // For simplicity, return 5 for now
    // TODO: Implement proper guest scan tracking with device ID and Firestore
    return 5;
  }

  Future<void> _recordGuestScan() async {
    // TODO: Implement guest scan tracking
    // This would typically use device ID and store in Firestore
    // For now, this is a placeholder
  }
}
