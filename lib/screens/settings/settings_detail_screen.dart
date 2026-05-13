import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/chat_service.dart';
import '../welcome/welcome_screen.dart';

class SettingsDetailScreen extends StatelessWidget {

  final String title;

  const SettingsDetailScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),

              Expanded(
                child: _buildContent(context),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (title) {
      case "Account":
        return _buildAccountSettings(context);
      case "Favorites":
        return _buildFavoritesList(context);
      case "Starred Messages":
        return _buildStarredMessagesList(context);
      case "Chat History":
        return _buildChatHistory(context);
      case "Privacy":
        return _buildPrivacySettings(context);
      case "Chats":
        return _buildChatsSettings(context);
      case "Notifications":
        return _buildNotificationsSettings(context);
      case "Storage and Data":
        return _buildStorageSettings(context);
      default:
        return Center(
          child: Text(
            "$title Settings",
            style: TextStyle(
              fontSize: 22,
              color: Colors.grey.shade700,
            ),
          ),
        );
    }
  }

  Widget _buildPrivacySettings(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final String currentUserId = authService.user?.uid ?? "";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic> settings = {};
        if (snapshot.hasData && snapshot.data?.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          settings = data['settings']?['Privacy'] ?? {};
        }

        final List<Map<String, dynamic>> options = [
          {"title": "Last seen", "subtitle": settings['Last seen'] ?? "Everyone", "icon": Icons.access_time},
          {"title": "Profile photo", "subtitle": settings['Profile photo'] ?? "My contacts", "icon": Icons.person_outline},
          {"title": "About", "subtitle": settings['About'] ?? "Everyone", "icon": Icons.info_outline},
          {"title": "Status", "subtitle": settings['Status'] ?? "My contacts", "icon": Icons.update_outlined},
        ];

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final opt = options[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
              child: ListTile(
                leading: Icon(opt['icon']),
                title: Text(opt['title']),
                subtitle: Text(opt['subtitle']),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () async {
                  String current = opt['subtitle'];
                  String newVal = current == "Everyone" ? "My contacts" : (current == "My contacts" ? "Nobody" : "Everyone");
                  await authService.updateSettings("Privacy", opt['title'], newVal);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChatsSettings(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final String currentUserId = authService.user?.uid ?? "";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic> settings = {};
        if (snapshot.hasData && snapshot.data?.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          settings = data['settings']?['Chats'] ?? {};
        }

        final List<Map<String, dynamic>> options = [
          {"title": "Wallpaper", "subtitle": settings['Wallpaper'] ?? "Default", "icon": Icons.wallpaper},
          {"title": "Font size", "subtitle": settings['Font size'] ?? "Medium", "icon": Icons.format_size},
          {"title": "Hide chat pop ups", "subtitle": settings['Hide chat pop ups'] ?? "Off", "icon": Icons.visibility_off_outlined, "isToggle": true},
        ];

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final opt = options[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
              child: ListTile(
                leading: Icon(opt['icon']),
                title: Text(opt['title']),
                subtitle: opt['subtitle'] != null ? Text(opt['subtitle']) : null,
                trailing: opt['isToggle'] == true 
                  ? Switch(value: opt['subtitle'] == "On", onChanged: (val) => authService.updateSettings("Chats", opt['title'], val ? "On" : "Off"))
                  : const Icon(Icons.arrow_forward_ios, size: 14),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationsSettings(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final String currentUserId = authService.user?.uid ?? "";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic> settings = {};
        if (snapshot.hasData && snapshot.data?.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          settings = data['settings']?['Notifications'] ?? {};
        }

        final List<Map<String, dynamic>> options = [
          {"title": "Notification sound", "subtitle": settings['Notification sound'] ?? "Default", "icon": Icons.music_note},
          {"title": "Vibrate", "subtitle": settings['Vibrate'] ?? "Default", "icon": Icons.vibration},
          {"title": "Hide notifications", "subtitle": settings['Hide notifications'] ?? "Off", "icon": Icons.notifications_off_outlined, "isToggle": true},
        ];

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final opt = options[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
              child: ListTile(
                leading: Icon(opt['icon']),
                title: Text(opt['title']),
                trailing: opt['isToggle'] == true 
                  ? Switch(value: opt['subtitle'] == "On", onChanged: (val) => authService.updateSettings("Notifications", opt['title'], val ? "On" : "Off"))
                  : const Icon(Icons.arrow_forward_ios, size: 14),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStorageSettings(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return FutureBuilder<Map<String, String>>(
      future: authService.getStorageUsage(),
      builder: (context, snapshot) {
        final used = snapshot.data?['used'] ?? "0 MB";
        final total = snapshot.data?['total'] ?? "0 MB";

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(25)),
                child: Column(
                  children: [
                    const Icon(Icons.storage, size: 40, color: Colors.purple),
                    const SizedBox(height: 15),
                    const Text("Network & Storage", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(value: 0.12, backgroundColor: Colors.grey.shade300, color: AppColors.mint),
                    const SizedBox(height: 10),
                    Text("$used used of $total", style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const ListTile(title: Text("Manage Storage"), trailing: Icon(Icons.arrow_forward_ios, size: 14)),
              const ListTile(title: Text("Network usage"), subtitle: Text("24.5 GB sent • 12.1 GB received")),
              const ListTile(title: Text("Use less data for calls"), trailing: Switch(value: false, onChanged: null)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountSettings(BuildContext context) {
    final List<Map<String, dynamic>> options = [
      {"title": "Email address", "subtitle": "elena.rossi@example.com", "icon": Icons.email_outlined},
      {"title": "Pass keys", "subtitle": "Simplified login methods", "icon": Icons.key_outlined},
      {"title": "Two-step verification", "subtitle": "On", "icon": Icons.verified_user_outlined},
      {"title": "Change phone number", "subtitle": "+1 234 567 890", "icon": Icons.phone_android_outlined},
      {"title": "Add account", "subtitle": null, "icon": Icons.person_add_alt_1_outlined},
      {"title": "Delete account", "subtitle": "This action is permanent", "icon": Icons.delete_outline, "color": Colors.red},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final opt = options[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            leading: Icon(opt['icon'], color: opt['color'] ?? Colors.black87),
            title: Text(opt['title'], style: TextStyle(color: opt['color'], fontWeight: FontWeight.bold)),
            subtitle: opt['subtitle'] != null ? Text(opt['subtitle']) : null,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              if (opt['title'] == "Delete account") {
                _showDeleteDialog(context);
              } else if (opt['title'] == "Change phone number") {
                _showPhoneDialog(context);
              }
            },
          ),
        );
      },
    );
  }

  void _showPhoneDialog(BuildContext context) {
    final TextEditingController phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Phone Number"),
        content: TextField(
          controller: phoneController,
          decoration: const InputDecoration(hintText: "Enter new phone number"),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              final error = await authService.updatePhoneNumber(phoneController.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? "Phone number updated!"),
                    backgroundColor: error == null ? AppColors.mint : Colors.red,
                  ),
                );
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final authService = Provider.of<AuthService>(context);
    final String currentUserId = authService.user?.uid ?? "";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data?.data() == null) return const Center(child: Text("No favorites found"));

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final List favourites = data['favourites'] ?? [];

        if (favourites.isEmpty) return const Center(child: Text("No favorite contacts yet."));

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: chatService.getUsersStream(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const SizedBox();
            final favUsers = userSnapshot.data!.where((u) => favourites.contains(u['uid'])).toList();

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: favUsers.length,
              itemBuilder: (context, index) {
                final user = favUsers[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.pink.shade100,
                      child: Text(user['email'][0].toUpperCase()),
                    ),
                    title: Text(user['email'] != null ? user['email'].split('@')[0] : "User", style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () => chatService.toggleFavoriteUser(user['uid']),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStarredMessagesList(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);

    return StreamBuilder<QuerySnapshot>(
      stream: chatService.getStarredMessages(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No starred messages yet."));

        final messages = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final data = messages[index].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("From: ${data['senderEmail'] != null ? data['senderEmail'].split('@')[0] : "Unknown"}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(data['message']),
                  const SizedBox(height: 4),
                  Text(
                    (data['timestamp'] as Timestamp).toDate().toString().substring(0, 16),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChatHistory(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final chatService = Provider.of<ChatService>(context);
    final String currentUserId = authService.user?.uid ?? "";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
      builder: (context, snapshot) {
        String lastBackup = "Never";
        if (snapshot.hasData && snapshot.data?.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          if (data['lastBackup'] != null) {
            lastBackup = (data['lastBackup'] as Timestamp).toDate().toString().substring(0, 16);
          }
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.blue),
                    const SizedBox(height: 15),
                    const Text("Chat Backup", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("Last Backup: $lastBackup", style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await chatService.performBackup();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Backup started..."), backgroundColor: AppColors.mint),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mint,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("Back Up Now", style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const ListTile(
                leading: Icon(Icons.history),
                title: Text("Auto Backup"),
                trailing: Text("Weekly", style: TextStyle(color: Colors.blue)),
              ),
              const ListTile(
                leading: Icon(Icons.network_wifi),
                title: Text("Backup over"),
                trailing: Text("Wi-Fi only", style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("This action cannot be undone. All your data will be permanently deleted."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              final error = await authService.deleteAccount();
              
              if (context.mounted) {
                if (error == null) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}