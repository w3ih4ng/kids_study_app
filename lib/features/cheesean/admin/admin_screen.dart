import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../alyssa/auth/screens/login_screen.dart';
import '../../weihang/admin/admin_lessons_screen.dart';
import '../../weihang/admin/admin_quizzes_screen.dart';
import '../../yijia/admin/admin_pets_screen.dart';
import '../../yijia/admin/admin_books_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.secondary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text('Manage Content',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Select a category to manage',
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _AdminCard(
                    icon: Icons.play_lesson,
                    title: 'Lessons',
                    color: AppTheme.lessonsColor,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const AdminLessonsScreen())),
                  ),
                  _AdminCard(
                    icon: Icons.quiz,
                    title: 'Quizzes',
                    color: AppTheme.quizzesColor,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const AdminQuizzesScreen())),
                  ),
                  _AdminCard(
                    icon: Icons.pets,
                    title: 'Pets',
                    color: AppTheme.petsColor,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const AdminPetsScreen())),
                  ),
                  _AdminCard(
                    icon: Icons.menu_book,
                    title: 'Comics',
                    color: AppTheme.booksColor,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const AdminBooksScreen())),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha:0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}