import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/storage_service.dart';
import '../../widgets/bottom_nav.dart';
import '../settings/linked_devices_screen.dart';
import '../../widgets/chat_tile.dart';
import 'message_screen.dart';
import 'new_message_screen.dart';
import 'create_group_screen.dart';
import 'group_message_screen.dart';
import '../community/community_screen.dart';
import '../settings/settings_detail_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  String selectedFilter = "All";
  final List<String> filters = ["All", "Unread", "Favourites", "Groups"];
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Uploading photo...")),
      );
      final storageService = Provider.of<StorageService>(context, listen: false);
      final chatService = Provider.of<ChatService>(context, listen: false);
      final url = await storageService.uploadFile(File(pickedFile.path), 'status_images');
      if (url != null) {
        await chatService.postStatus(url, 'image');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Status updated!"), backgroundColor: AppColors.mint),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Let's Chat",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                            icon: const Icon(Icons.camera_alt_outlined), onPressed: _takePhoto),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == "Starred") {
                              Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => const SettingsDetailScreen(title: "Starred Messages")));
                            } else if (value == "New community") {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const CommunityScreen()));
                            } else if (value == "New group") {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
                            } else if (value == "Linked devices") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LinkedDevicesScreen()),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) => ['New group', 'New community', 'Linked devices', 'Starred']
                              .map((c) => PopupMenuItem<String>(value: c, child: Text(c)))
                              .toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() {}),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Search conversations...",
                            icon: Icon(Icons.search, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Filter Bar
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: filters.length,
                          itemBuilder: (context, index) {
                            bool isSelected = selectedFilter == filters[index];
                            return GestureDetector(
                              onTap: () => setState(() => selectedFilter = filters[index]),
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.black.withOpacity(0.1)
                                      : Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: isSelected ? Border.all(color: Colors.black26) : null,
                                ),
                                child: Text(filters[index],
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.black : Colors.black54,
                                    )),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Chat List
                      Expanded(child: _buildChatList(context, chatService, currentUser)),
                    ],
                  ),
                ),
              ),
              const BottomNav(currentIndex: 3),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          onPressed: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NewMessageScreen())),
          backgroundColor: AppColors.mint,
          child: const Icon(Icons.message),
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context, ChatService chatService, User? currentUser) {
    // Groups filter
    if (selectedFilter == "Groups") {
      return StreamBuilder<QuerySnapshot>(
        stream: chatService.getGroupsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading groups"));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final groups = snapshot.data?.docs ?? [];
          if (groups.isEmpty)
            return const Center(child: Text("No groups yet. Create one!"));
          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final data = groups[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? "Group";
              final lastMessage = data['lastMessage'] ?? "Start chatting";
              return ChatTile(
                name: name,
                message: lastMessage,
                time: _formatTime(data['lastMessageTime']),
                leadingIcon: Icons.group,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupMessageScreen(groupId: groups[index].id, groupName: name),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    // Favourites filter
    if (selectedFilter == "Favourites") {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid ?? '')
            .snapshots(),
        builder: (context, userSnap) {
          final List favourites = [];
          if (userSnap.hasData && userSnap.data?.data() != null) {
            final data = userSnap.data!.data() as Map<String, dynamic>;
            favourites.addAll(data['favourites'] ?? []);
          }
          if (favourites.isEmpty)
            return const Center(child: Text("No favourite contacts yet.\nTap ❤️ on a contact to add."));
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: chatService.getFavouriteUsersStream(List<String>.from(favourites)),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final users = snapshot.data!.where((u) => u['uid'] != currentUser?.uid).toList();
              if (users.isEmpty) return const Center(child: Text("No favourite contacts found."));
              return _buildUserList(context, chatService, currentUser, users);
            },
          );
        },
      );
    }

    // All and Unread — use chat rooms stream (sorted by lastMessageTime)
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: chatService.getChatRoomsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 10),
                const Text("Error loading chats"),
                const SizedBox(height: 10),
                TextButton(onPressed: () => setState(() {}), child: const Text("Retry")),
              ],
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        var rooms = snapshot.data ?? [];

        // Search filter
        final query = _searchController.text.toLowerCase().trim();
        if (query.isNotEmpty) {
          rooms = rooms.where((r) => r['name'].toString().toLowerCase().contains(query)).toList();
        }

        // Unread filter
        if (selectedFilter == "Unread") {
          rooms = rooms
              .where((r) =>
                  r['lastMessageSenderId'] != currentUser?.uid &&
                  (r['lastMessage'] ?? '').isNotEmpty)
              .toList();
        }

        if (rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 50, color: Colors.grey),
                const SizedBox(height: 10),
                Text(selectedFilter == "Unread"
                    ? "No unread chats!"
                    : "No chats yet.\nTap the message button to start!"),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            final String name = room['name'] ?? 'User';
            final String lastMsg = room['lastMessage'] ?? '';
            final String time = _formatTime(room['lastMessageTime']);
            final String privacy = room['profilePhotoPrivacy'] ?? 'Everyone';
            final String? photoUrl = privacy == 'Nobody' ? null : room['photoUrl'];
            final bool isOnline = room['isOnline'] == true;

            return ChatTile(
              name: name,
              message: lastMsg,
              time: time,
              avatarText: name.isNotEmpty ? name[0].toUpperCase() : null,
              photoUrl: photoUrl,
              isOnline: isOnline,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MessageScreen(
                    userName: name,
                    receiverId: room['uid'],
                    chatRoomId: room['chatRoomId'],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserList(BuildContext context, ChatService chatService, User? currentUser,
      List<Map<String, dynamic>> users) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final String name = user['name'] ??
            (user['email'] ?? 'User').toString().split('@')[0];
        return ChatTile(
          name: name,
          message: user['about'] ?? 'Tap to chat',
          time: '',
          avatarText: name.isNotEmpty ? name[0].toUpperCase() : null,
          photoUrl: user['photoUrl'],
          onTap: () {
            final ids = [currentUser!.uid, user['uid'] as String]..sort();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MessageScreen(
                  userName: name,
                  receiverId: user['uid'],
                  chatRoomId: ids.join('_'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[dt.weekday - 1];
      } else {
        return '${dt.day}/${dt.month}/${dt.year % 100}';
      }
    } catch (_) {
      return '';
    }
  }
}
