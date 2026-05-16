import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
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
  String _selectedFilter = "All";
  final List<String> _filters = ["All", "Unread", "Favourites", "Groups"];
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
      final storageService = Provider.of<StorageService>(context, listen: false);
      final chatService = Provider.of<ChatService>(context, listen: false);
      final url = await storageService.uploadFile(File(pickedFile.path), 'status_images');
      if (url != null && mounted) {
        await chatService.postStatus(url, 'image');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Status updated")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.md, 0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text("Messages", style: AppTextStyle.heading1),
                  ),
                  IconButton(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt_outlined,
                        color: AppColors.textSecondary, size: 22),
                    tooltip: "Post status",
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz,
                        color: AppColors.textSecondary, size: 22),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg)),
                    onSelected: (value) {
                      switch (value) {
                        case "Starred":
                          Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const SettingsDetailScreen(title: "Starred Messages")));
                        case "New community":
                          Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const CommunityScreen()));
                        case "New group":
                          Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const CreateGroupScreen()));
                        case "Linked devices":
                          Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const LinkedDevicesScreen()));
                      }
                    },
                    itemBuilder: (_) => [
                      "New group", "New community", "Linked devices", "Starred"
                    ].map((c) => PopupMenuItem(value: c, child: Text(c, style: AppTextStyle.body1))).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ─── Search ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: AppTextStyle.body1,
                decoration: InputDecoration(
                  hintText: "Search conversations…",
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textTertiary, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ─── Filter chips ─────────────────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final selected = _selectedFilter == _filters[i];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = _filters[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accent : AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        _filters[i],
                        style: AppTextStyle.body2.copyWith(
                          color: selected ? Colors.white : AppColors.textSecondary,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ─── Chat list ────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _buildChatList(context, chatService, currentUser),
              ),
            ),

            const BottomNav(currentIndex: 3),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const NewMessageScreen())),
          child: const Icon(Icons.edit_outlined),
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context, ChatService chatService, User? currentUser) {
    if (_selectedFilter == "Groups") {
      return StreamBuilder<QuerySnapshot>(
        stream: chatService.getGroupsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return _loader();
          if (snapshot.hasError) return _errorState();
          final groups = snapshot.data?.docs ?? [];
          if (groups.isEmpty) return _emptyState("No groups yet", "Create one to get started");
          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (_, i) {
              final data = groups[i].data() as Map<String, dynamic>;
              final name = data['name'] ?? "Group";
              return ChatTile(
                name: name,
                message: data['lastMessage'] ?? "Start chatting",
                time: _formatTime(data['lastMessageTime']),
                leadingIcon: Icons.group_outlined,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => GroupMessageScreen(groupId: groups[i].id, groupName: name))),
              );
            },
          );
        },
      );
    }

    if (_selectedFilter == "Favourites") {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users').doc(currentUser?.uid ?? '').snapshots(),
        builder: (context, userSnap) {
          final List favourites = [];
          if (userSnap.hasData && userSnap.data?.data() != null) {
            favourites.addAll((userSnap.data!.data() as Map)['favourites'] ?? []);
          }
          if (favourites.isEmpty) {
            return _emptyState("No favourites", "Long-press a contact to add them");
          }
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: chatService.getFavouriteUsersStream(List<String>.from(favourites)),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return _loader();
              final users = snapshot.data!.where((u) => u['uid'] != currentUser?.uid).toList();
              if (users.isEmpty) return _emptyState("No favourites found", "");
              return _buildUserList(context, chatService, currentUser, users);
            },
          );
        },
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: chatService.getChatRoomsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _errorState();
        if (snapshot.connectionState == ConnectionState.waiting) return _loader();

        var rooms = snapshot.data ?? [];
        final query = _searchController.text.toLowerCase().trim();
        if (query.isNotEmpty) {
          rooms = rooms.where((r) => r['name'].toString().toLowerCase().contains(query)).toList();
        }
        if (_selectedFilter == "Unread") {
          rooms = rooms.where((r) =>
              r['lastMessageSenderId'] != currentUser?.uid &&
              (r['lastMessage'] ?? '').isNotEmpty).toList();
        }
        if (rooms.isEmpty) {
          return _emptyState(
            _selectedFilter == "Unread" ? "All caught up" : "No conversations yet",
            _selectedFilter == "Unread" ? "You're up to date" : "Tap the edit button to start one",
          );
        }
        return ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (_, i) {
            final room = rooms[i];
            final name = room['name'] ?? 'User';
            final privacy = room['profilePhotoPrivacy'] ?? 'Everyone';
            return ChatTile(
              name: name,
              message: room['lastMessage'] ?? '',
              time: _formatTime(room['lastMessageTime']),
              avatarText: name.isNotEmpty ? name[0].toUpperCase() : null,
              photoUrl: privacy == 'Nobody' ? null : room['photoUrl'],
              isOnline: room['isOnline'] == true,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => MessageScreen(
                        userName: name,
                        receiverId: room['uid'],
                        chatRoomId: room['chatRoomId'],
                      ))),
            );
          },
        );
      },
    );
  }

  Widget _buildUserList(BuildContext context, ChatService chatService,
      User? currentUser, List<Map<String, dynamic>> users) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (_, i) {
        final user = users[i];
        final name = user['name'] ?? (user['email'] ?? 'User').toString().split('@')[0];
        return ChatTile(
          name: name,
          message: user['about'] ?? 'Tap to chat',
          time: '',
          avatarText: name.isNotEmpty ? name[0].toUpperCase() : null,
          photoUrl: user['photoUrl'],
          onTap: () {
            final ids = [currentUser!.uid, user['uid'] as String]..sort();
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => MessageScreen(
                      userName: name,
                      receiverId: user['uid'],
                      chatRoomId: ids.join('_'),
                    )));
          },
        );
      },
    );
  }

  Widget _loader() => const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
      );

  Widget _errorState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text("Couldn't load chats", style: AppTextStyle.body2),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => setState(() {}),
            child: const Text("Retry", style: TextStyle(color: AppColors.accent)),
          ),
        ]),
      );

  Widget _emptyState(String title, String subtitle) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyle.label),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: AppTextStyle.body2),
          ],
        ]),
      );

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
