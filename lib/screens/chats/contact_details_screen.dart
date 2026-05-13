import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class ContactDetailsScreen extends StatelessWidget {
  final String userName;

  const ContactDetailsScreen({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
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
                      child: Text(
                        userName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      userName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "+1 234 567 890",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
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
                  content: "Available • Hey there! I am using Let's Chat.",
                  icon: Icons.info_outline,
                ),
                _infoCard(
                  title: "Media, links and docs",
                  content: "124 items",
                  icon: Icons.image_outlined,
                  showGallery: true,
                ),

                const SizedBox(height: 15),

                // Group Section
                _infoCard(
                  title: "Groups in common",
                  content: "3 groups",
                  icon: Icons.group_outlined,
                ),

                const SizedBox(height: 20),

                // Action List
                _actionListTile("Mute notifications", Icons.notifications_none, Colors.black),
                _actionListTile("Block $userName", Icons.block, Colors.red),
                _actionListTile("Report $userName", Icons.report_gmailerrorred, Colors.red),

                const SizedBox(height: 30),
              ],
            ),
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
          if (showGallery) ...[
            const SizedBox(height: 15),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) => Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(15),
                    image: const DecorationImage(
                      image: NetworkImage("https://picsum.photos/200"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _actionListTile(String title, IconData icon, Color color) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 30),
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      onTap: () {},
    );
  }
}
