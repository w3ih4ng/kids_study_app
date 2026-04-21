import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/child_provider.dart';
import '../../core/services/child_service.dart';
import '../../models/child_model.dart';
import '../../core/widgets/child_avatar.dart';
import '../auth/create_child_screen.dart';
import '../auth/login_screen.dart';
import '../child/home_screen_shell.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

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
    setState(() => _loadingChildren = true);
    final children = await ChildService.getChildren();
    if (mounted) {
      setState(() {
        _children = children;
        _loadingChildren = false;
      });
    }
  }

  void _switchToChild(ChildModel child) async {
    context.read<ChildProvider>().setActiveChild(child);
    await ChildService.saveLastActiveChild(child.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to ${child.nickname}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _editChild(ChildModel child) async {
    final controller = TextEditingController(text: child.nickname);

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nickname',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Delete button inside dialog
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, 'delete'),
                icon: const Icon(Icons.delete, color: AppTheme.danger),
                label: const Text(
                  'Delete Profile',
                  style: TextStyle(color: AppTheme.danger),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.danger),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == 'save' && controller.text.trim().isNotEmpty) {
      await ChildService.updateChild(child.id, controller.text.trim());
      await _loadChildren();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nickname updated!')));
      }
    } else if (result == 'delete') {
      await _deleteChild(child);
    }
  }

  Future<void> _deleteChild(ChildModel child) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text(
          'Remove ${child.nickname}\'s profile? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final activeChild = context.read<ChildProvider>().activeChild;
    await ChildService.deleteChild(child.id);
    await _loadChildren();

    if (activeChild?.id == child.id && mounted) {
      if (_children.isNotEmpty) {
        context.read<ChildProvider>().setActiveChild(_children.first);
      } else {
        context.read<ChildProvider>().clearActiveChild();
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile deleted.')));
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),

            // ── Child Profiles section ───────────────────────────────────
            _sectionHeader(
              Icons.child_care,
              'Child Profiles',
              AppTheme.primary,
            ),
            const SizedBox(height: 12),

            if (_loadingChildren)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_children.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'No child profiles yet. Add one below!',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              )
            else
              ..._children.map((child) {
                final isActive = child.id == activeChild?.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isActive
                        ? const BorderSide(color: AppTheme.primary, width: 2)
                        : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        ChildAvatar(
                          avatarUrl: child.avatarUrl,
                          nickname: child.nickname,
                          radius: 22,
                        ),
                        const SizedBox(width: 12),

                        // Name + coins + active badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      child.nickname,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isActive) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Active',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${child.coins} coins',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Switch button (non-active only)
                        if (!isActive)
                          IconButton(
                            icon: const Icon(
                              Icons.switch_account,
                              color: AppTheme.primary,
                            ),
                            tooltip: 'Switch to this profile',
                            onPressed: () => _switchToChild(child),
                          ),

                        // Edit button (delete moved inside)
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: AppTheme.textSecondary,
                          ),
                          tooltip: 'Edit',
                          onPressed: () => _editChild(child),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateChildScreen(isFirstTime: false),
                  ),
                );
                _loadChildren();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Child Profile'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Quick Actions section ────────────────────────────────────
            _sectionHeader(
              Icons.dashboard,
              'Quick Actions',
              AppTheme.secondary,
            ),
            const SizedBox(height: 12),

            _DashboardCard(
              icon: Icons.bar_chart,
              title: 'Reports',
              subtitle: "View your children's progress and scores",
              color: AppTheme.lessonsColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _DashboardCard(
              icon: Icons.settings,
              title: 'Settings',
              subtitle: 'Account details and PIN security',
              color: AppTheme.secondary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _DashboardCard(
              icon: Icons.child_care,
              title: 'Back to Child',
              subtitle: 'Return to the child learning dashboard',
              color: AppTheme.success,
              onTap: () async {
                final children = await ChildService.getChildren();
                if (context.mounted && children.isNotEmpty) {
                  final current =
                      context.read<ChildProvider>().activeChild ??
                      children.first;
                  context.read<ChildProvider>().setActiveChild(current);
                  await ChildService.saveLastActiveChild(current.id); // save it
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChildDashboardScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
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
