import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/child_provider.dart';
import '../../core/services/child_service.dart';
import '../../core/widgets/animated_pet_widget.dart';
import '../../core/widgets/child_bottom_nav_bar.dart';
import '../../core/widgets/coins_badge.dart';
import '../home_screen.dart';
import '../lessons/lesson_list_screen.dart';
import '../quizzes/quiz_list_screen.dart';
import '../books/book_list_screen.dart';
import '../pets/pet_shop_screen.dart';
import 'child_profile_screen.dart';
import '../parent/pin_screen.dart';
import '../parent/parent_dashboard_screen.dart';
import '../../core/services/pet_service.dart';
import '../../models/pet_model.dart';

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

  // ── Home AppBar ──────────────────────────────────────────────────────────
  PreferredSizeWidget _buildHomeAppBar(child) {
    final nickname = child?.nickname ?? '';
    final avatarUrl = child?.avatarUrl as String?;
    final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : '?';

    return AppBar(
      automaticallyImplyLeading: false,
      // ① Tall enough to breathe
      toolbarHeight: 80,
      title: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChildProfileScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Avatar ───────────────────────────────────────────────
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // If the child has uploaded a photo, show it.
                    // Otherwise show a WHITE circle with a COLOURED initial
                    // so it's always visible on the indigo AppBar.
                    avatarUrl != null && avatarUrl.isNotEmpty
                        ? CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(avatarUrl),
                      onBackgroundImageError: (_, __) {},
                    )
                        : CircleAvatar(
                      radius: 28,
                      // White background so the letter pops against
                      // the indigo AppBar
                      backgroundColor: Colors.white.withValues(alpha:0.6),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          // Indigo letter on white circle
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                    // ② Pencil badge
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 12,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // ── Name column ──────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Hello,',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    Row(
                      children: [
                        Text(
                          nickname.isEmpty ? 'Learner' : nickname,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right,
                            color: Colors.white70, size: 18),
                      ],
                    ),
                  ],
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
      toolbarHeight: 80,
      title: Text(title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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