import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/child_provider.dart';
import '../../../core/services/child_service.dart';
import '../../../core/widgets/child_bottom_nav_bar.dart';
import '../../../core/widgets/coins_badge.dart';
import '../../../core/widgets/child_avatar.dart';
import '../../home/screens/home_screen.dart';
import '../../lessons/screens/lesson_list_screen.dart';
import '../../quizzes/screens/quiz_list_screen.dart';
import '../../books/screens/book_list_screen.dart';
import '../../pets/screens/pet_shop_screen.dart';
import 'pin_screen.dart';
import 'parent_dashboard_screen.dart';

class ChildDashboardScreen extends StatefulWidget {
  const ChildDashboardScreen({super.key});

  @override
  State<ChildDashboardScreen> createState() => _ChildDashboardScreenState();
}

class _ChildDashboardScreenState extends State<ChildDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeScreen(),
    LessonListScreen(),
    QuizListScreen(),
    BookListScreen(),
    PetShopScreen(),
  ];

  Future<void> _goToParentDashboard() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final pin = await ChildService.getParentPin();
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PinScreen(
            correctPin: pin,
            onSuccess: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load PIN. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = context.watch<ChildProvider>().activeChild;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChildAvatar(
              avatarUrl: child?.avatarUrl,
              nickname: child?.nickname ?? '',
              radius: 16,
            ),
            const SizedBox(width: 8),
            Text(child?.nickname ?? 'Learning'),
          ],
        ),
        actions: [
          const CoinsBadge(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.switch_account),
            tooltip: 'Switch Profile',
            onPressed: _goToParentDashboard,
          ),
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: ChildBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}