import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
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
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.user?.uid ?? "";

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    Text("Settings", style: AppTextStyle.heading1),
                    const SizedBox(height: AppSpacing.xl),

                    // ─── Profile card ────────────────────────────────────────
                    _ProfileCard(currentUserId: currentUserId, authService: authService),

                    const SizedBox(height: AppSpacing.xl),

                    // ─── Section: Account ────────────────────────────────────
                    _sectionLabel("Account"),
                    const SizedBox(height: AppSpacing.sm),
                    _card([
                      SettingTile(
                        icon: Icons.person_outline,
                        title: "Account",
                        onTap: () => _open(context, "Account"),
                      ),
                      _divider(),
                      SettingTile(
                        icon: Icons.lock_outline,
                        title: "Privacy",
                        onTap: () => _open(context, "Privacy"),
                      ),
                      _divider(),
                      SettingTile(
                        icon: Icons.notifications_none_rounded,
                        title: "Notifications",
                        onTap: () => _open(context, "Notifications"),
                      ),
                    ]),

                    const SizedBox(height: AppSpacing.lg),

                    // ─── Section: Chats ──────────────────────────────────────
                    _sectionLabel("Chats"),
                    const SizedBox(height: AppSpacing.sm),
                    _card([
                      SettingTile(
                        icon: Icons.chat_outlined,
                        title: "Chats",
                        onTap: () => _open(context, "Chats"),
                      ),
                      _divider(),
                      SettingTile(
                        icon: Icons.star_outline_rounded,
                        title: "Starred Messages",
                        onTap: () => _open(context, "Starred Messages"),
                      ),
                      _divider(),
                      SettingTile(
                        icon: Icons.history_rounded,
                        title: "Chat History",
                        onTap: () => _open(context, "Chat History"),
                      ),
                      _divider(),
                      SettingTile(
                        icon: Icons.storage_outlined,
                        title: "Storage and Data",
                        onTap: () => _open(context, "Storage and Data"),
                      ),
                    ]),

                    const SizedBox(height: AppSpacing.lg),

                    // ─── Danger zone ─────────────────────────────────────────
                    _card([
                      SettingTile(
                        icon: Icons.logout_rounded,
                        title: "Sign Out",
                        iconColor: AppColors.error,
                        onTap: () async {
                          final auth = Provider.of<AuthService>(context, listen: false);
                          await auth.signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                              (_) => false,
                            );
                          }
                        },
                      ),
                    ]),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
            const BottomNav(currentIndex: 4),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, String title) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SettingsDetailScreen(title: title)),
      );

  Widget _sectionLabel(String text) => Text(
        text.toUpperCase(),
        style: AppTextStyle.caption.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      );

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadow.card,
        ),
        child: Column(children: children),
      );

  Widget _divider() => const Divider(
        indent: 56,
        height: 1,
        color: AppColors.divider,
      );
}

class _ProfileCard extends StatelessWidget {
  final String currentUserId;
  final AuthService authService;

  const _ProfileCard({required this.currentUserId, required this.authService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: currentUserId.isNotEmpty
          ? FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        String? photoUrl;
        String displayName = authService.user?.displayName ?? "User";
        String about = "";

        if (snapshot.hasData && snapshot.data?.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          photoUrl = data['photoUrl'];
          displayName = data['name'] ?? displayName;
          about = data['about'] ?? "";
        }

        return GestureDetector(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppShadow.card,
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentLight,
                    image: photoUrl != null
                        ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: photoUrl == null
                      ? const Icon(Icons.person_outline, color: AppColors.accent, size: 30)
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: AppTextStyle.label),
                      if (about.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(about,
                            style: AppTextStyle.body2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Text("Edit profile",
                          style: AppTextStyle.caption.copyWith(
                              color: AppColors.accent, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textTertiary, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
