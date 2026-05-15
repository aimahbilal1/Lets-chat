import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/services/chat_service.dart';
import 'package:provider/provider.dart';

class ContactDetailsScreen extends StatelessWidget {
  final String receiverId;

  const ContactDetailsScreen({
    super.key,
    required this.receiverId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(receiverId).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text("Error loading contact"));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              
              if (!snapshot.hasData || snapshot.data?.data() == null) {
                return const Center(child: Text("Contact not found"));
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final String name = data['name'] ?? (data['email'] ?? "User").toString().split('@')[0];
              final String phone = data['phone'] ?? "No phone number";
              final String about = data['about'] ?? "Available";
              final String? photoUrl = data['photoUrl'];

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
                builder: (context, currentUserSnapshot) {
                  bool isBlocked = false;
                  bool isMuted = false;

                  if (currentUserSnapshot.hasData && currentUserSnapshot.data?.data() != null) {
                    final currentUserData = currentUserSnapshot.data!.data() as Map<String, dynamic>;
                    final List blockedUsers = currentUserData['blockedUsers'] ?? [];
                    final List mutedUsers = currentUserData['mutedUsers'] ?? [];
                    isBlocked = blockedUsers.contains(receiverId);
                    isMuted = mutedUsers.contains(receiverId);
                  }

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header with Back Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back),
                              ),
                            ],
                          ),
                        ),

                        // Profile Image & Name
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.pink.shade100,
                              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                              child: photoUrl == null
                                  ? Text(
                                      name[0].toUpperCase(),
                                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              name,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              phone,
                              style: const TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // Quick Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _quickAction(Icons.call_outlined, "Audio"),
                            const SizedBox(width: 30),
                            _quickAction(Icons.videocam_outlined, "Video"),
                            const SizedBox(width: 30),
                            _quickAction(Icons.search, "Search"),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Info Section
                        _infoCard(
                          title: "About and status",
                          content: about,
                          icon: Icons.info_outline,
                        ),
                        _mediaGalleryCard(receiverId),

                        const SizedBox(height: 15),

                        // Group Section
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: Provider.of<ChatService>(context, listen: false).getGroupsInCommon(receiverId),
                          builder: (context, groupSnapshot) {
                            final List commonGroups = groupSnapshot.data ?? [];
                            final String content = commonGroups.isEmpty 
                                ? "No groups in common" 
                                : commonGroups.map((g) => g['name']).join(', ');
                            
                            return _infoCard(
                              title: "Groups in common",
                              content: content,
                              icon: Icons.group_outlined,
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Action List
                        _actionListTile(
                          isMuted ? "Unmute notifications" : "Mute notifications", 
                          isMuted ? Icons.notifications_off : Icons.notifications_none, 
                          Colors.black, 
                          context,
                          onTap: () {
                            final chatService = Provider.of<ChatService>(context, listen: false);
                            if (isMuted) {
                              chatService.unmuteUser(receiverId);
                            } else {
                              chatService.muteUser(receiverId);
                            }
                          }
                        ),
                        _actionListTile(
                          isBlocked ? "Unblock $name" : "Block $name", 
                          Icons.block, 
                          Colors.red, 
                          context,
                          onTap: () {
                            final chatService = Provider.of<ChatService>(context, listen: false);
                            if (isBlocked) {
                              chatService.unblockUser(receiverId);
                            } else {
                              chatService.blockUser(receiverId);
                            }
                          }
                        ),
                        _actionListTile(
                          "Report $name", 
                          Icons.report_gmailerrorred, 
                          Colors.red, 
                          context,
                          onTap: () {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Report sent")));
                          }
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  );
                }
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.black87),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _infoCard({required String title, required String content, required IconData icon, bool showGallery = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.black54),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _actionListTile(String title, IconData icon, Color color, BuildContext context, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 30),
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      onTap: onTap ?? () {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$title action logged")));
      },
    );
  }

  Widget _mediaGalleryCard(String receiverId) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    final chatRoomId = ids.join('_');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image_outlined, size: 20, color: Colors.black54),
              const SizedBox(width: 10),
              const Text("Media, links and docs", style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.bold)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black54),
            ],
          ),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chat_rooms')
                .doc(chatRoomId)
                .collection('messages')
                .where('messageType', isEqualTo: 'image')
                .orderBy('timestamp', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text("No shared media", style: TextStyle(color: Colors.black54));
              }

              final docs = snapshot.data!.docs;
              return SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final url = data['mediaUrl'] as String?;
                    if (url == null) return const SizedBox();
                    return Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(
                          image: NetworkImage(url),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
