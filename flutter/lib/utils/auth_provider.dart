import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:heartcloud/utils/app_user.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _appUser;
  bool _isLoading = true; // To track initial loading state

  AppUser? get appUser => _appUser;
  bool get isLoggedIn => _appUser != null;
  bool get isLoading => _isLoading;

  bool get isDoctor => _appUser?.role == UserRole.doctor;
  bool get isPatient => _appUser?.role == UserRole.patient;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      if (_appUser != null || _isLoading) {
        _appUser = null;
        _isLoading = false;
        notifyListeners();
      }
      return;
    }

    // Only fetch user data if the user has changed
    if (_appUser?.uid != firebaseUser.uid) {
      try {
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (userDoc.exists) {
          _appUser = AppUser.fromFirestore(userDoc);
        } else {
          print("Error: User document not found in Firestore for UID: ${firebaseUser.uid}");
          _appUser = null; // Set user to null if profile doesn't exist
        }
      } catch (e) {
        print("Error fetching user data: $e");
        _appUser = null;
      }
    }

    // In all cases of having a firebaseUser, loading is finished.
    if (_isLoading) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // The authStateChanges listener will handle the successful login state.
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // --- FIX: Made signOut more robust to prevent getting stuck ---
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners(); // Show loading indicator

    try {
      await _auth.signOut();
      // The authStateChanges listener will eventually fire.
      // However, to ensure a snappy response and prevent getting stuck,
      // we can manually update the state here.
      _appUser = null;
      _isLoading = false;
      notifyListeners(); // Hide loading indicator and update UI to log out
    } catch (e) {
      print("Error during sign out: $e");
      _isLoading = false; // Ensure loading is turned off on error
      notifyListeners();
      // Optionally re-throw if you want the UI to handle the error
      throw e;
    }
  }
}