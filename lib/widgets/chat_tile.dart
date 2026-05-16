import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';

class ChatTile extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final String? avatarText;
  final Color? avatarColor;
  final String? photoUrl;
  final bool isOnline;

  const ChatTile({
    super.key,
    required this.name,
    required this.message,
    required this.time,
    required this.onTap,
    this.leadingIcon,
    this.avatarText,
    this.avatarColor,
    this.photoUrl,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: avatarColor ?? AppColors.accentLight,
                    image: photoUrl != null
                        ? DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: photoUrl == null
                      ? (avatarText != null
                          ? Text(
                              avatarText!,
                              style: AppTextStyle.label.copyWith(color: AppColors.accent),
                            )
                          : Icon(leadingIcon ?? Icons.person, color: AppColors.accent, size: 22))
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.background, width: 2),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: AppSpacing.md),

            // Name + preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyle.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.body2,
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Timestamp
            Text(time, style: AppTextStyle.caption),
          ],
        ),
      ),
    );
  }
}
