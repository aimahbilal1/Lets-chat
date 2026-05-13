import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/storage_service.dart';
import '../../widgets/custom_textfield.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _photoUrl;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges(AuthService authService) async {
    setState(() => _isLoading = true);
    try {
      final user = authService.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'name': _nameController.text,
          'about': _aboutController.text,
          'phone': _phoneController.text,
          'photoUrl': _photoUrl,
        }, SetOptions(merge: true));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile updated!"),
              backgroundColor: AppColors.mint,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final storageService = Provider.of<StorageService>(context, listen: false);
    final String currentUserId = authService.user?.uid ?? "";

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data?.data() != null) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            if (_nameController.text.isEmpty)
              _nameController.text = data['name'] ?? "";
            if (_aboutController.text.isEmpty)
              _aboutController.text = data['about'] ?? "";
            if (_phoneController.text.isEmpty)
              _phoneController.text = data['phone'] ?? "";
            _photoUrl ??= data['photoUrl'];
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Edit Profile",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                final picked = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 75,
                                );
                                if (picked == null) return;

                                setState(() => _isLoading = true);
                                final url = await storageService.uploadFile(
                                  File(picked.path),
                                  'profile_photos',
                                );
                                if (url != null) {
                                  setState(() => _photoUrl = url);
                                }
                                if (mounted) setState(() => _isLoading = false);
                              },
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.pink.shade200,
                                backgroundImage:
                                    _photoUrl != null
                                        ? NetworkImage(_photoUrl!)
                                        : null,
                                child:
                                    _photoUrl == null
                                        ? const Icon(Icons.person, size: 50)
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 30),
                            CustomTextField(
                              controller: _nameController,
                              hint: "Username",
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 18),
                            CustomTextField(
                              controller: _aboutController,
                              hint: "About",
                              icon: Icons.info_outline,
                            ),
                            const SizedBox(height: 18),
                            CustomTextField(
                              controller: _phoneController,
                              hint: "Phone",
                              icon: Icons.phone_outlined,
                            ),
                            const SizedBox(height: 30),
                            GestureDetector(
                              onTap:
                                  _isLoading
                                      ? null
                                      : () => _saveChanges(authService),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFA8D5BA),
                                      Color(0xFFE0B0FF),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                alignment: Alignment.center,
                                child:
                                    _isLoading
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text(
                                          "Save Changes",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
