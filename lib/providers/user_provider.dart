import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );
  
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  bool _isFetchingProfile = true; // New flag for initial load

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isFetchingProfile => _isFetchingProfile;
  bool get isAuthenticated => _auth.currentUser != null;

  UserProvider() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? firebaseUser) async {
      _isFetchingProfile = true;
      notifyListeners();
      
      if (firebaseUser != null) {
        await _loadUserData(firebaseUser);
      } else {
        _user = null;
        _isFetchingProfile = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(User firebaseUser) async {
    try {
      // Reload user to ensure we have latest display name
      await firebaseUser.reload();
      User? currentUser = _auth.currentUser; // Get refreshed user

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists) {
        _user = userDoc.data() as Map<String, dynamic>?;
      } else {
        // Fallback or create if missing
        String displayName = currentUser.displayName ?? 'User';
        
        // Attempt to create/sync if missing
        Map<String, dynamic> userData = {
          'name': displayName,
          'email': currentUser.email ?? '',
          'memberSince': currentUser.metadata.creationTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        // Try to save to Firestore (fire and forget to not block UI)
        _firestore.collection('users').doc(currentUser.uid).set(userData).catchError((e) {
          debugPrint('Error auto-creating user doc: $e');
        });

        _user = userData;
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Minimal fallback
      _user = {
        'name': firebaseUser.displayName ?? 'User',
        'email': firebaseUser.email ?? '',
      };
    } finally {
      _isFetchingProfile = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _loadUserData(credential.user!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Login error: ${e.message}');
      return false;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signUp(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name);

        // Create user document in Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': name,
          'email': email,
          'memberSince': DateTime.now().toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _loadUserData(credential.user!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Sign up error: ${e.message}');
      return false;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      final GoogleSignInAccount? signedInUser = googleUser ?? await _googleSignIn.signIn();
      
      if (signedInUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await signedInUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken ?? googleAuth.serverAuthCode,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Check if user document exists, if not create it
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'name': userCredential.user!.displayName ?? 'Google User',
            'email': userCredential.user!.email ?? '',
            'memberSince': DateTime.now().toIso8601String(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        await _loadUserData(userCredential.user!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Google sign in error: $e');
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signInWithDemoGoogle() async {
    // For demo purposes, just call the regular Google sign-in
    return await signInWithGoogle();
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  Future<void> fetchProfile() async {
    if (_auth.currentUser != null) {
      await _loadUserData(_auth.currentUser!);
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    try {
      final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
    } catch (e) {
      debugPrint('Error changing password: $e');
      throw e; // Rethrow to handle in UI
    }
  }

  Future<bool> updateName(String name) async {
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(name);
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
          'name': name,
        });

        if (_user != null) {
          _user!['name'] = name;
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error updating name: $e');
    }
    return false;
  }

  Future<void> addScanToHistory(Map<String, dynamic> scanData) async {
    if (_auth.currentUser == null) return;

    try {
      final scanEntry = {
        ...scanData,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Update Firestore array
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'scanHistory': FieldValue.arrayUnion([scanEntry]),
      });

      // Update local state
      if (_user != null) {
        if (_user!['scanHistory'] == null) {
          _user!['scanHistory'] = [];
        }
        (_user!['scanHistory'] as List).add(scanEntry);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding scan history: $e');
    }
  }
}
