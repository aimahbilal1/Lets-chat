import 'package:flutter/material.dart';
import '../screens/calls/calls_screen.dart';
import '../screens/community/community_screen.dart';
import '../screens/chats/chats_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/updates/updates_screen.dart';

class BottomNav extends StatelessWidget {

  final int currentIndex;

  const BottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      height: 75,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [

          navItem(
            context,
            Icons.call_outlined,
            0,
            const CallsScreen(),
          ),

          navItem(
            context,
            Icons.update_outlined,
            1,
            const UpdatesScreen(),
          ),

          navItem(
            context,
            Icons.people_alt_outlined,
            2,
            const CommunityScreen(),
          ),

          navItem(
            context,
            Icons.chat_bubble_outline,
            3,
            const ChatsScreen(),
          ),

          navItem(
            context,
            Icons.settings_outlined,
            4,
            const SettingsScreen(),
          ),
        ],
      ),
    );
  }

  Widget navItem(
    BuildContext context,
    IconData icon,
    int index,
    Widget screen,
  ) {

    final selected = currentIndex == index;

    return GestureDetector(
      onTap: () {

        if (!selected) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => screen,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFA8D5BA)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          color: selected
              ? Colors.green.shade900
              : Colors.grey.shade600,
        ),
      ),
    );
  }
}