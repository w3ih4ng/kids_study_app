import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/child_provider.dart';
import '../../../core/services/child_service.dart';
import '../../../models/child_model.dart';
import '../../../core/widgets/child_avatar.dart';
import 'login_screen.dart';
import 'child_dashboard_screen.dart';
import '../../parent/screens/reports_screen.dart';
import '../../parent/screens/settings_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  List<ChildModel> _children = [];
  bool _loadingChildren = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final children = await ChildService.getChildren();
    if (mounted) setState(() {
      _children = children;
      _loadingChildren = false;
    });
  }

  // ── Switch Child dialog ──────────────────────────────────────────────────
  void _showSwitchChildDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final activeChild = context.read<ChildProvider>().activeChild;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Switch Child',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select which child to view',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (_children.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('No child profiles found.')),
                )
              else
                ..._children.map((child) {
                  final isActive = child.id == activeChild?.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ChildAvatar(
                      avatarUrl: child.avatarUrl,
                      nickname: child.nickname,
                      radius: 24,
                    ),
                    title: Text(
                      child.nickname,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isActive ? AppTheme.primary : AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      child.childCode ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    trailing: isActive
                        ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                        : const Icon(Icons.chevron_right,
                        color: AppTheme.textSecondary),
                    onTap: isActive
                        ? null
                        : () {
                      context.read<ChildProvider>().setActiveChild(child);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Switched to ${child.nickname}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeChild = context.watch<ChildProvider>().activeChild;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
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
            const SizedBox(height: 16),
            const Text('Welcome, Parent!',
                style:
                TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('What would you like to do?',
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 24),

            // ── Active child chip + Switch button ────────────────────────
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  _loadingChildren
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : ChildAvatar(
                    avatarUrl: activeChild?.avatarUrl,
                    nickname: activeChild?.nickname ?? '?',
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Viewing child',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        Text(
                          activeChild?.nickname ?? '—',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  // ── Switch Child button ──────────────────────────────
                  TextButton.icon(
                    onPressed: _children.length > 1
                        ? _showSwitchChildDialog
                        : null, // greyed out if only 1 child
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Switch'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _DashboardCard(
              icon: Icons.bar_chart,
              title: 'Reports',
              subtitle: "View your children's progress and scores",
              color: AppTheme.lessonsColor,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen())),
            ),
            const SizedBox(height: 16),
            _DashboardCard(
              icon: Icons.settings,
              title: 'Settings',
              subtitle: 'Manage children profiles and account details',
              color: AppTheme.secondary,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            const SizedBox(height: 16),
            _DashboardCard(
              icon: Icons.child_care,
              title: 'Back to Child',
              subtitle: 'Return to the child learning dashboard',
              color: AppTheme.success,
              onTap: () async {
                final children = await ChildService.getChildren();
                if (context.mounted && children.isNotEmpty) {
                  final activeChild =
                      context.read<ChildProvider>().activeChild ??
                          children.first;
                  context.read<ChildProvider>().setActiveChild(activeChild);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ChildDashboardScreen()),
                        (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable dashboard card ─────────────────────────────────────────────────
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}