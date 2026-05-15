import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload file to Firebase Storage
  Future<String?> uploadFile(File file, String folder) async {
    try {
      final String uid = _auth.currentUser!.uid;
      final String fileName = "${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}";
      final Reference ref = _storage.ref().child(folder).child(uid).child(fileName);
      
      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading file: $e");
      return null;
    }
  }

  // Delete file from Firebase Storage
  Future<void> deleteFile(String url) async {
    try {
      final Reference ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print("Error deleting file: $e");
    }
  }
}
