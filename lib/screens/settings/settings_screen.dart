import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/setting_tile.dart';
import '../welcome/welcome_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_detail_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                const SizedBox(height: 10),

                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.pink.shade200,
                  child: const Icon(
                    Icons.person,
                    size: 45,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  "Elena Rossi",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Digital lifestyle enthusiast",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 18),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Edit Profile",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Expanded(
                  child: ListView(
                    children: [

                      SettingTile(
                        icon: Icons.favorite_outline,
                        title: "Favorites",
                        onTap: () {
                          openDetails(context, "Favorites");
                        },
                      ),

                      SettingTile(
                        icon: Icons.star_outline,
                        title: "Starred Messages",
                        onTap: () {
                          openDetails(context, "Starred Messages");
                        },
                      ),

                      SettingTile(
                        icon: Icons.history,
                        title: "Chat History",
                        onTap: () {
                          openDetails(context, "Chat History");
                        },
                      ),

                      SettingTile(
                        icon: Icons.person_outline,
                        title: "Account",
                        onTap: () {
                          openDetails(context, "Account");
                        },
                      ),

                      SettingTile(
                        icon: Icons.lock_outline,
                        title: "Privacy",
                        onTap: () {
                          openDetails(context, "Privacy");
                        },
                      ),

                      SettingTile(
                        icon: Icons.chat_outlined,
                        title: "Chats",
                        onTap: () {
                          openDetails(context, "Chats");
                        },
                      ),

                      SettingTile(
                        icon: Icons.notifications_none,
                        title: "Notifications",
                        onTap: () {
                          openDetails(context, "Notifications");
                        },
                      ),

                      SettingTile(
                        icon: Icons.storage_outlined,
                        title: "Storage and Data",
                        onTap: () {
                          openDetails(context, "Storage and Data");
                        },
                      ),

                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () async {
                          final authService = Provider.of<AuthService>(
                              context,
                              listen: false);
                          await authService.signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const WelcomeScreen()),
                              (route) => false,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "Sign Out",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                const BottomNav(
                  currentIndex: 4,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void openDetails(BuildContext context, String title) {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsDetailScreen(
          title: title,
        ),
      ),
    );
  }
}