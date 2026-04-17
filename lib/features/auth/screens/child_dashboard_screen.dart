import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/child_provider.dart';
import '../../../core/services/child_service.dart';
import '../../../core/widgets/animated_pet_widget.dart';
import '../../../core/widgets/child_bottom_nav_bar.dart';
import '../../../core/widgets/coins_badge.dart';
import '../../../core/widgets/child_avatar.dart';
import '../../home/screens/home_screen.dart';
import '../../lessons/screens/lesson_list_screen.dart';
import '../../quizzes/screens/quiz_list_screen.dart';
import '../../books/screens/book_list_screen.dart';
import '../../pets/screens/pet_shop_screen.dart';
import '../../profile/screens/child_profile_screen.dart';
import 'pin_screen.dart';
import 'parent_dashboard_screen.dart';
import '../../../core/services/pet_service.dart';
import '../../../models/pet_model.dart';
import '../../social/screens/friends_screen.dart';
import '../../social/screens/leaderboard_screen.dart';

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

  final List<String> _tabTitles = const [
    'Home',
    'Lessons',
    'Quizzes',
    'Books',
    'Pets',
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
            onSuccess: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
                  (route) => false,
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

  // Home tab AppBar — shows avatar + name + coins
  PreferredSizeWidget _buildHomeAppBar(child) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChildProfileScreen()),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChildAvatar(
              avatarUrl: child?.avatarUrl,
              nickname: child?.nickname ?? '',
              radius: 22,                    // slightly bigger avatar
            ),
            const SizedBox(width: 10),
            Text(
              child?.nickname ?? 'Learning',
              style: const TextStyle(
                fontSize: 24,                // bigger
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      actions: const [
        CoinsBadge(),
        SizedBox(width: 12),
      ],
    );
  }

  // Other tabs AppBar — shows screen title only
  PreferredSizeWidget _buildDefaultAppBar(String title) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(title),
    );
  }

  Widget _buildFloatingPet() {
    final child = context.watch<ChildProvider>().activeChild;
    if (child?.activePetId == null) return const SizedBox();

    return FutureBuilder<List<PetModel>>(
      future: PetService.getAllPets(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final activePet = snapshot.data!
            .where((p) => p.id == child!.activePetId)
            .firstOrNull;
        if (activePet == null) return const SizedBox();

        return AnimatedPetWidget(
          imageUrl: activePet.imageUrl,
          soundUrl: activePet.soundUrl,
          size: 100,
          animate: true,
          interactive: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = context.watch<ChildProvider>().activeChild;

    return Stack(
      children: [
        Scaffold(
          appBar: _currentIndex == 0
              ? _buildHomeAppBar(child)
              : _buildDefaultAppBar(_tabTitles[_currentIndex]),
          body: _tabs[_currentIndex],
          bottomNavigationBar: ChildBottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        ),
          Positioned(
            bottom: 80, // above nav bar
            right: 16,
            child: _buildFloatingPet(),
          ),
      ],
    );
  }
}