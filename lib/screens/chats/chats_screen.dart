import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/storage_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/chat_tile.dart';
import 'message_screen.dart';
import 'new_message_screen.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploading photo...")));
      
      final storageService = Provider.of<StorageService>(context, listen: false);
      final chatService = Provider.of<ChatService>(context, listen: false);
      
      final url = await storageService.uploadFile(File(pickedFile.path), 'status_images');
      if (url != null) {
        await chatService.postStatus(url, 'image');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Status updated with photo!"), backgroundColor: AppColors.mint));
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
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Let's Chat",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.camera_alt_outlined),
                          onPressed: _takePhoto,
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == "Starred") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsDetailScreen(title: "Starred Messages"),
                                ),
                              );
                            } else if (value == "New community") {
                              // Navigate to community tab
                              // We can't easily switch tabs from here without a controller, 
                              // but we can push the screen directly or use a shared state.
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CommunityScreen()),
                              );
                            } else if (value == "New group") {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Group creation feature coming soon!")));
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              'New group',
                              'New community',
                              'Linked devices',
                              'Starred'
                            ].map((String choice) {
                              return PopupMenuItem<String>(
                                value: choice,
                                child: Text(choice),
                              );
                            }).toList();
                          },
                        ),
                      ],
                    )
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
                              onTap: () {
                                setState(() {
                                  selectedFilter = filters[index];
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.black.withOpacity(0.1) : Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: isSelected ? Border.all(color: Colors.black26) : null,
                                ),
                                child: Text(
                                  filters[index],
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.black : Colors.black54,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Chat List
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _searchController.text.isNotEmpty
                              ? chatService.searchUsers(_searchController.text)
                              : chatService.getUsersStream(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red, size: 40),
                                    const SizedBox(height: 10),
                                    const Text("Error loading chats"),
                                    Text(snapshot.error.toString(), style: const TextStyle(fontSize: 10, color: Colors.black45)),
                                    const SizedBox(height: 10),
                                    TextButton(onPressed: () => setState(() {}), child: const Text("Retry")),
                                  ],
                                ),
                              );
                            }
                            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                            final data = snapshot.data ?? [];
                            var users = data
                                .where((user) => user['uid'] != currentUser?.uid)
                                .toList();

                            if (users.isEmpty) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.chat_bubble_outline, size: 50, color: Colors.grey),
                                    SizedBox(height: 10),
                                    Text("No chats found. Start a new conversation!"),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                final String email = user['email'] ?? "User";
                                final String name = email.contains('@') ? email.split('@')[0] : email;
                                
                                return ChatTile(
                                  name: name,
                                  message: user['about'] ?? "Tap to chat",
                                  time: "Now",
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MessageScreen(
                                          userName: name,
                                          receiverId: user['uid'],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const BottomNav(
                currentIndex: 3,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90), // Move up to avoid overlap with BottomNav
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NewMessageScreen(),
              ),
            );
          },
          backgroundColor: AppColors.mint,
          child: const Icon(Icons.message),
        ),
      ),
    );
  }
}