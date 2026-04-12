import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/child_provider.dart';
import '../../../core/services/child_service.dart';
import 'pin_screen.dart';
import 'parent_dashboard_screen.dart';

class ChildDashboardScreen extends StatelessWidget {
  const ChildDashboardScreen({super.key});

  Future<void> _goToParentDashboard(BuildContext context) async {
    // Show loading while fetching PIN
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pin = await ChildService.getParentPin();
      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PinScreen(
            correctPin: pin,
            onSuccess: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const ParentDashboardScreen()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // dismiss loading
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
        title: Text(child?.nickname ?? 'Learning'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_account),
            tooltip: 'Switch Profile',
            onPressed: () => _goToParentDashboard(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.child_care, size: 80, color: Colors.indigo),
            const SizedBox(height: 16),
            Text('Hi, ${child?.nickname ?? 'there'}!',
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Ready to learn today?',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 40),
            const Text('Lessons, Quizzes, Pets, Comics coming soon...',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}