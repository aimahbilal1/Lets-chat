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
      debugPrint("Auth State Changed: ${user?.email ?? 'Logged Out'}");
      _user = user;
      notifyListeners();
    });
  }

  Future<String?> signUp(String email, String password) async {
    debugPrint("Attempting Sign Up for: $email");
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint("Sign Up successful: ${userCredential.user!.uid}");

      // Save user info to firestore
      try {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
        });
        debugPrint("User info saved to Firestore");
      } catch (e) {
        debugPrint("Firestore Error (SignUp): $e");
        return "Account created, but failed to save profile: $e. Check your Firestore rules.";
      }

      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Error (SignUp): ${e.code} - ${e.message}");
      return e.message;
    } catch (e) {
      debugPrint("Unexpected Error (SignUp): $e");
      return "An unexpected error occurred: $e";
    }
  }

  Future<String?> signIn(String email, String password) async {
    debugPrint("Attempting Sign In for: $email");
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      debugPrint("Sign In successful");
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Error (SignIn): ${e.code} - ${e.message}");
      return e.message;
    } catch (e) {
      debugPrint("Unexpected Error (SignIn): $e");
      return "An unexpected error occurred: $e";
    }
  }

  Future<void> signOut() async {
    debugPrint("Signing Out");
    await _auth.signOut();
  }
}
