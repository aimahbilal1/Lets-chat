import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;

  User? get user => _user;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  String _mapError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> signUp(
    String email,
    String password,
    String name, {
    String? phone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(name);
      try {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': email,
          'name': name,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'createdAt': FieldValue.serverTimestamp(),
          'photoUrl': null,
        });
      } catch (e) {
        debugPrint('Firestore error during signUp: $e');
        return 'Account created but profile could not be saved. Check Firestore rules.';
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Delete account logic
  Future<String?> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete Firestore data
        await _firestore.collection('users').doc(user.uid).delete();
        
        // Delete Auth user
        await user.delete();
        return null;
      }
      return "No user logged in";
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (e) {
      return e.toString();
    }
  }

  // Update phone number
  Future<String?> updatePhoneNumber(String newPhone) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'phone': newPhone,
        });
        return null;
      }
      return "No user logged in";
    } catch (e) {
      return e.toString();
    }
  }

  // Update user settings (Privacy, Chats, Notifications, etc.)
  Future<void> updateSettings(String category, String key, dynamic value) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'settings': {
            category: {
              key: value,
            }
          }
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error updating settings: $e");
    }
  }

  // Calculate storage usage (placeholder logic)
  Future<Map<String, String>> getStorageUsage() async {
    return {
      'used': '124 MB',
      'total': '1 GB',
    };
  }
}
