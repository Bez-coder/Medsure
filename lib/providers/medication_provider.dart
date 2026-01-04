import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final List<String> times; // e.g., ['08:00', '14:00', '20:00']
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final bool notificationsEnabled;
  final String medicineType; // Capsule, Syrup, Injection, etc.
  final String forPerson; // Self or Other
  final String? personName; // Name if for other person
  final Map<String, bool> doseHistory; // 'YYYY-MM-DD' => taken

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    required this.startDate,
    this.endDate,
    this.notes,
    this.notificationsEnabled = true,
    this.medicineType = 'Tablet',
    this.forPerson = 'Self',
    this.personName,
    this.doseHistory = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times': times,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'notes': notes,
      'notificationsEnabled': notificationsEnabled,
      'medicineType': medicineType,
      'forPerson': forPerson,
      'personName': personName,
      'doseHistory': doseHistory,
    };
  }

  factory Medication.fromMap(String id, Map<String, dynamic> map) {
    return Medication(
      id: id,
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      times: List<String>.from(map['times'] ?? []),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      notes: map['notes'],
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      medicineType: map['medicineType'] ?? 'Tablet',
      forPerson: map['forPerson'] ?? 'Self',
      personName: map['personName'],
      doseHistory: Map<String, bool>.from(map['doseHistory'] ?? {}),
    );
  }
}

class MedicationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final fln.FlutterLocalNotificationsPlugin _notificationsPlugin = fln.FlutterLocalNotificationsPlugin();

  List<Medication> _medications = [];
  bool _isLoading = false;

  MedicationProvider() {
    // Initialization now happens in main.dart for better background reliability
  }


  List<Medication> get medications => _medications;
  bool get isLoading => _isLoading;

  // Get medications for the current user
  Future<void> loadMedications() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      _medications = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('medications')
          .orderBy('startDate', descending: true)
          .get();

      _medications = snapshot.docs
          .map((doc) => Medication.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading medications: $e');
      _medications = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add a new medication
  Future<bool> addMedication(Medication medication) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('User not logged in');
      return false;
    }

    try {
      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('medications')
          .add(medication.toMap());

      // Update medication with Firestore ID locally to schedule correctly
      Medication newMedication = Medication(
        id: docRef.id, // Use the generated ID
        name: medication.name,
        dosage: medication.dosage,
        frequency: medication.frequency,
        times: medication.times,
        startDate: medication.startDate,
        endDate: medication.endDate,
        notes: medication.notes,
        notificationsEnabled: medication.notificationsEnabled,
      );
      
      if (medication.notificationsEnabled) {
        try {
          await _scheduleNotifications(newMedication);
        } catch (e) {
          debugPrint('Error scheduling notifications: $e');
          // We still want to return true because the medication was added to Firestore
        }
      }

      await loadMedications();
      return true;
    } catch (e) {
      debugPrint('Error adding medication: $e');
      return false;
    }
  }

  // Update an existing medication
  Future<bool> updateMedication(Medication medication) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('User not logged in');
      return false;
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('medications')
          .doc(medication.id)
          .update(medication.toMap());

      await _cancelNotifications(medication.id);
      if (medication.notificationsEnabled) {
        await _scheduleNotifications(medication);
      }

      await loadMedications();
      return true;
    } catch (e) {
      debugPrint('Error updating medication: $e');
      return false;
    }
  }

  // Delete a medication
  Future<bool> deleteMedication(String medicationId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('User not logged in');
      return false;
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('medications')
          .doc(medicationId)
          .delete();
      
      await _cancelNotifications(medicationId);

      await loadMedications();
      return true;
    } catch (e) {
      debugPrint('Error deleting medication: $e');
      return false;
    }
  }

  // Toggle medication notification
  Future<bool> toggleNotification(String medicationId, bool enabled) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('User not logged in');
      return false;
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('medications')
          .doc(medicationId)
          .update({'notificationsEnabled': enabled});

      await loadMedications();
      return true;
    } catch (e) {
      debugPrint('Error toggling notification: $e');
      return false;
    }
  }

  // Get today's medications (medications due today)
  List<Medication> getTodaysMedications() {
    DateTime now = DateTime.now();
    return _medications.where((med) {
      // Check if medication is active
      if (med.endDate != null && now.isAfter(med.endDate!)) {
        return false;
      }
      if (now.isBefore(med.startDate)) {
        return false;
      }
      return true;
    }).toList();
  }

  // Record medication taken (for tracking adherence and UI updates)
  Future<bool> recordMedicationTaken(String medicationId, DateTime takenAt) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('User not logged in');
      return false;
    }

    try {
      // 1. Add to history collection (for detailed stats)
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('medication_history')
          .add({
        'medicationId': medicationId,
        'takenAt': Timestamp.fromDate(takenAt),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Update the medication document's doseHistory map (for UI state)
      final dateKey = '${takenAt.year}-${takenAt.month.toString().padLeft(2, '0')}-${takenAt.day.toString().padLeft(2, '0')}';
      
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('medications')
          .doc(medicationId)
          .set({
            'doseHistory': {
              dateKey: true
            }
          }, SetOptions(merge: true));

      // 3. Reload medications to update UI immediately
      await loadMedications();

      return true;
    } catch (e) {
      debugPrint('Error recording medication: $e');
      return false;
    }
  }

  // Get medication adherence stats
  Future<Map<String, dynamic>> getAdherenceStats(String medicationId, {int days = 7}) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {'taken': 0, 'total': 0, 'percentage': 0.0};
    }

    try {
      DateTime startDate = DateTime.now().subtract(Duration(days: days));
      
      QuerySnapshot historySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('medication_history')
          .where('medicationId', isEqualTo: medicationId)
          .where('takenAt', isGreaterThan: Timestamp.fromDate(startDate))
          .get();

      int takenCount = historySnapshot.docs.length;
      
      // Calculate expected doses based on medication frequency
      Medication? medication = _medications.firstWhere(
        (med) => med.id == medicationId,
      );
      
      int expectedDoses = medication.times.length * days;
      double percentage = expectedDoses > 0 ? (takenCount / expectedDoses) * 100 : 0;

      return {
        'taken': takenCount,
        'total': expectedDoses,
        'percentage': percentage,
      };
    } catch (e) {
      debugPrint('Error getting adherence stats: $e');
      return {'taken': 0, 'total': 0, 'percentage': 0.0};
    }
  }

  Future<void> _scheduleNotifications(Medication medication) async {
    try {
      fln.AndroidScheduleMode scheduleMode = fln.AndroidScheduleMode.exactAllowWhileIdle;

      for (int i = 0; i < medication.times.length; i++) {
        String time = medication.times[i];
        List<String> parts = time.split(':');
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);

        // Unique ID for each dose: Hash of med ID + index
        int notificationId = (medication.id.hashCode + i).abs();

        try {
          await _notificationsPlugin.zonedSchedule(
            notificationId,
            'Time for ${medication.name}',
            'Take ${medication.dosage}',
            _nextInstanceOfTime(hour, minute),
            const fln.NotificationDetails(
              android: fln.AndroidNotificationDetails(
                'medication_reminders',
                'Medication Reminders',
                channelDescription: 'Reminders to take your medication',
                importance: fln.Importance.max,
                priority: fln.Priority.high,
              ),
            ),
            androidScheduleMode: scheduleMode,
            matchDateTimeComponents: fln.DateTimeComponents.time, // Repeat daily
          );
        } catch (e) {
          // If exact alarm fails (e.g. permission missing), fallback to inexact
          if (scheduleMode == fln.AndroidScheduleMode.exactAllowWhileIdle) {
            debugPrint('Exact alarm failed, falling back to inexact: $e');
            scheduleMode = fln.AndroidScheduleMode.inexactAllowWhileIdle;
            await _notificationsPlugin.zonedSchedule(
              notificationId,
              'Time for ${medication.name}',
              'Take ${medication.dosage}',
              _nextInstanceOfTime(hour, minute),
              const fln.NotificationDetails(
                android: fln.AndroidNotificationDetails(
                  'medication_reminders',
                  'Medication Reminders',
                  channelDescription: 'Reminders to take your medication',
                  importance: fln.Importance.max,
                  priority: fln.Priority.high,
                ),
              ),
              androidScheduleMode: scheduleMode,
              matchDateTimeComponents: fln.DateTimeComponents.time, // Repeat daily
            );
          } else {
            rethrow;
          }
        }
      }
    } catch (e) {
      debugPrint('Internal error in _scheduleNotifications: $e');
      rethrow;
    }
  }

  Future<void> _cancelNotifications(String medicationId) async {
    // We don't know exactly how many times per day, but we can assume a reasonable max (e.g. 10)
    // or store notification IDs. For simplicity, we loop 10 times.
    for (int i = 0; i < 10; i++) {
      int notificationId = (medicationId.hashCode + i).abs();
      await _notificationsPlugin.cancel(notificationId);
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
