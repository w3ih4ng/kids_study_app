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
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  List<Widget> get _tabs => [
    HomeScreen(key: _homeKey),
    const LessonListScreen(),
    const QuizListScreen(),
    const BookListScreen(),
    const PetShopScreen(),
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

  // ── Home tab AppBar ──────────────────────────────────────────────────────
  // Taller bar, ripple feedback, pencil icon so users know it's tappable.
  PreferredSizeWidget _buildHomeAppBar(child) {
    return AppBar(
      automaticallyImplyLeading: false,
      // ① Make the bar noticeably taller
      toolbarHeight: 72,
      title: Material(
        color: Colors.transparent,
        child: InkWell(
          // ② Ripple effect confirms the whole row is tappable
          borderRadius: BorderRadius.circular(40),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChildProfileScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ③ Avatar — always has a coloured fallback (initial letter)
                Stack(
                  children: [
                    ChildAvatar(
                      avatarUrl: child?.avatarUrl,
                      // If nickname is somehow blank, '?' is shown by the widget
                      nickname: child?.nickname ?? '',
                      radius: 26,
                    ),
                    // ④ Small pencil badge so it's obvious this is editable
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 11,
                          color: Color(0xFF4F46E5), // AppTheme.primary
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ⑤ "Hello," label above the name for a friendlier look
                    const Text(
                      'Hello,',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      child?.nickname ?? 'Learner',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                // ⑥ Chevron — the clearest possible tap hint
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: const [
        CoinsBadge(),
        SizedBox(width: 12),
      ],
    );
  }

  // ── Other tabs AppBar ────────────────────────────────────────────────────
  PreferredSizeWidget _buildDefaultAppBar(String title) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 72,
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
            onTap: (index) {
              setState(() => _currentIndex = index);
              if (index == 0) {
                _homeKey.currentState?.reload();
              }
            },
          ),
        ),
        Positioned(
          bottom: 80,
          right: 16,
          child: _buildFloatingPet(),
        ),
      ],
    );
  }
}