import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/services/chat_service.dart';
import '../../widgets/bottom_nav.dart';
import 'community_message_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (!_isSearching)
                          const Text(
                            "Your\nCommunity",
                            style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, height: 1.1),
                          )
                        else
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Search communities…',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onChanged: (v) => setState(() => _searchQuery = v),
                            ),
                          ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(_isSearching ? Icons.close : Icons.search),
                              onPressed: () => setState(() {
                                _isSearching = !_isSearching;
                                _searchQuery = '';
                                _searchController.clear();
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Communities list
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _searchQuery.trim().isNotEmpty
                            ? chatService.searchCommunities(_searchQuery)
                            : chatService.getCommunitiesStream(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) return const Center(child: Text("Error loading communities"));
                          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                          final communityDocs = snapshot.data?.docs ?? [];

                          if (communityDocs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("No communities found"),
                                  const SizedBox(height: 10),
                                  if (_searchQuery.isEmpty)
                                    ElevatedButton(
                                      onPressed: () => chatService.joinCommunity("General"),
                                      child: const Text("Initialize General Community"),
                                    ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: communityDocs.length,
                            itemBuilder: (_, index) {
                              final doc = communityDocs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final String name = data['name'] ?? "Unknown Community";
                              final String description = data['description'] ?? "Join and explore the community";
                              final String lastMessage = data['lastMessage'] ?? '';

                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CommunityMessageScreen(
                                      communityId: doc.id,
                                      communityName: name,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 56,
                                        width: 56,
                                        decoration: BoxDecoration(
                                          color: Colors.pink.shade100,
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: const Icon(Icons.groups, size: 30, color: Colors.pink),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            const SizedBox(height: 4),
                                            Text(
                                              lastMessage.isNotEmpty ? lastMessage : description,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: Colors.black38),
                                    ],
                                  ),
                                ),
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
            const BottomNav(currentIndex: 2),
          ],
        ),
      ),
    );
  }
}
