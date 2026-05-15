import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/storage_service.dart';
import '../../widgets/bottom_nav.dart';
import '../chats/message_screen.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  String _searchQuery = '';

  bool _matchesQuery(String name, String status) {
    if (_searchQuery.trim().isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    return name.toLowerCase().contains(q) || status.toLowerCase().contains(q);
  }

  void _openSearch(BuildContext context) {
    final controller = TextEditingController(text: _searchQuery);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Search updates'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Type a name or status',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _searchQuery = controller.text.trim());
                  Navigator.pop(context);
                },
                child: const Text('Search'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Updates",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _openSearch(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView(
                    children: [
                      // My Status
                      GestureDetector(
                        onTap: () => _showStatusOptions(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.orange.shade100,
                                    child: const Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 15),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "My Status",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      "Tap to add status update",
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),
                      const Text(
                        "Recent Updates",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 15),

                      StreamBuilder<QuerySnapshot>(
                        stream: chatService.getStatusUpdates(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 20),
                                child: Text("No updates yet"),
                              ),
                            );
                          }

                          return Column(
                            children:
                                snapshot.data!.docs.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final String name = data['userName'];
                                  final String time =
                                      (data['timestamp'] as Timestamp?)
                                          ?.toDate()
                                          .toString()
                                          .substring(11, 16) ??
                                      "Recently";
                                  final String statusText =
                                      data['statusText'] ?? "No status message";
                                  final List likes = List.from(
                                    data['likes'] ?? [],
                                  );
                                  final currentUser =
                                      FirebaseAuth.instance.currentUser;
                                  final bool isLiked =
                                      currentUser != null &&
                                      likes.contains(currentUser.uid);
                                  final likeCount = likes.length;

                                  return _statusItem(
                                    context,
                                    name,
                                    statusText,
                                    "Today, $time",
                                    Colors.pink.shade100,
                                    isLiked: isLiked,
                                    likeCount: likeCount,
                                    onLike:
                                        () => chatService.toggleStatusLike(
                                          doc.id,
                                        ),
                                    onReply: () {
                                      if (currentUser == null) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MessageScreen(
                                            receiverId: data['uid'],
                                            userName: name,
                                            chatRoomId: chatService.getChatRoomId(currentUser.uid, data['uid']),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const BottomNav(currentIndex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusItem(
    BuildContext context,
    String name,
    String status,
    String time,
    Color color, {
    required bool isLiked,
    required int likeCount,
    required VoidCallback onLike,
    required VoidCallback onReply,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: color,
                  child: Text(
                    name[0],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 65),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _reactionButton(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      likeCount > 0 ? "Like ($likeCount)" : "Like",
                      onTap: onLike,
                      color: isLiked ? Colors.red : null,
                    ),
                    const SizedBox(width: 20),
                    _reactionButton(
                      Icons.reply_outlined,
                      "Reply",
                      onTap: onReply,
                    ),
                    const SizedBox(width: 20),
                    _reactionButton(
                      Icons.repeat_outlined,
                      "Repost",
                      onTap:
                          () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Repost action logged")),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Add Status",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.blue,
                  ),
                  title: const Text("Take Photo"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.green,
                  ),
                  title: const Text("Upload from Gallery"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia(context, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.edit_note_outlined,
                    color: Colors.orange,
                  ),
                  title: const Text("Write Text Status"),
                  onTap: () {
                    Navigator.pop(context);
                    _showTextStatusDialog(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickMedia(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Uploading status...")));

      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );
      final chatService = Provider.of<ChatService>(context, listen: false);

      final url = await storageService.uploadFile(
        File(pickedFile.path),
        'status_images',
      );
      if (url != null) {
        await chatService.postStatus(url, 'image');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Status updated!"),
            backgroundColor: AppColors.mint,
          ),
        );
      }
    }
  }

  void _showTextStatusDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Text Status"),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
              ),
              maxLength: 100,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    final chatService = Provider.of<ChatService>(
                      context,
                      listen: false,
                    );
                    await chatService.postStatus(
                      null,
                      'text',
                      statusText: controller.text,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Status posted!"),
                          backgroundColor: AppColors.mint,
                        ),
                      );
                    }
                  }
                },
                child: const Text("Post"),
              ),
            ],
          ),
    );
  }

  Widget _reactionButton(
    IconData icon,
    String label, {
    VoidCallback? onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.black54),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
