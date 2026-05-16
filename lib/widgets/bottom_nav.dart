import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../screens/calls/calls_screen.dart';
import '../screens/community/community_screen.dart';
import '../screens/chats/chats_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/updates/updates_screen.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;

  const BottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md, 0, AppSpacing.md, AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadow.elevated,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(context, Icons.call_outlined, Icons.call, 0, const CallsScreen()),
          _navItem(context, Icons.radio_button_checked_outlined, Icons.radio_button_checked, 1, const UpdatesScreen()),
          _navItem(context, Icons.people_alt_outlined, Icons.people_alt, 2, const CommunityScreen()),
          _navItem(context, Icons.chat_bubble_outline, Icons.chat_bubble, 3, const ChatsScreen()),
          _navItem(context, Icons.settings_outlined, Icons.settings, 4, const SettingsScreen()),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    IconData activeIcon,
    int index,
    Widget screen,
  ) {
    final selected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (!selected) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => screen,
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 280),
            ),
          );
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? activeIcon : icon,
              size: 22,
              color: selected ? AppColors.accent : AppColors.textTertiary,
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 4 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
