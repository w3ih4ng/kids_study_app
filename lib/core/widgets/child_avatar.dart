import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class ChildAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String nickname;
  final double radius;

  const ChildAvatar({
    super.key,
    this.avatarUrl,
    required this.nickname,
    this.radius = 28,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primary.withValues(alpha:0.15),
      child: Text(
        nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}