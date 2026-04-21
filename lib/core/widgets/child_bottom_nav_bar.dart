import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class ChildBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ChildBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Uses theme colors — adapts to light/dark automatically
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.surface : const Color(0xFFFFFFFF);
    final selectedColor = AppTheme.primary;
    final unselectedColor = isDark
        ? AppTheme.textSecondary
        : const Color(0xFF6B7280);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: bgColor,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 12,
      unselectedFontSize: 11,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.play_lesson_outlined),
          activeIcon: Icon(Icons.play_lesson),
          label: 'Lessons',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.quiz_outlined),
          activeIcon: Icon(Icons.quiz),
          label: 'Quizzes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          activeIcon: Icon(Icons.menu_book),
          label: 'Books',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pets_outlined),
          activeIcon: Icon(Icons.pets),
          label: 'Pets',
        ),
      ],
    );
  }
}
