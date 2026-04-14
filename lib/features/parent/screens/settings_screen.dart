import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/providers/child_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/child_service.dart';
import '../../../core/widgets/child_avatar.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/child_model.dart';
import '../../auth/screens/create_child_screen.dart';
import '../../auth/screens/child_dashboard_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<ChildModel> _children = [];
  bool _isLoading = true;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => _isLoading = true);
    final children = await ChildService.getChildren();
    if (mounted) setState(() { _children = children; _isLoading = false; });
  }

  // ─── Child Management ───────────────────────────────────────────

  Future<void> _editChild(ChildModel child) async {
    final controller = TextEditingController(text: child.nickname);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Nickname'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nickname',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (confirmed == true && controller.text.trim().isNotEmpty) {
      await ChildService.updateChild(child.id, controller.text.trim());
      _loadChildren();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nickname updated!')));
      }
    }
  }

  Future<void> _deleteChild(ChildModel child) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text(
            'Remove ${child.nickname}\'s profile? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (confirmed == true) {
      final activeChild = context.read<ChildProvider>().activeChild;

      await ChildService.deleteChild(child.id);
      await _loadChildren();

      // If deleted child was active, switch to another
      if (activeChild?.id == child.id && mounted) {
        if (_children.isNotEmpty) {
          context.read<ChildProvider>().setActiveChild(_children.first);
        } else {
          context.read<ChildProvider>().clearActiveChild();
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile deleted.')));
      }
    }
  }

  void _switchToChild(ChildModel child) {
    context.read<ChildProvider>().setActiveChild(child);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ChildDashboardScreen()),
          (route) => false,
    );
  }

  // ─── Account Management ─────────────────────────────────────────

  Future<void> _changePassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Update')),
        ],
      ),
    );

    if (confirmed == true && _newPasswordController.text.trim().isNotEmpty) {
      try {
        await AuthService.updatePassword(_newPasswordController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password updated!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
      _newPasswordController.clear();
    }
  }

  Future<void> _changePin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change PIN'),
        content: TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'New 4-digit PIN',
            border: OutlineInputBorder(),
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                if (_pinController.text.length == 4) {
                  Navigator.pop(context, true);
                } else {
                  // do nothing, keep dialog open
                }
              },
              child: const Text('Save')),
        ],
      ),
    );

    if (confirmed == true) {
      await ChildService.updatePin(_pinController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN updated successfully!')));
      }
      _pinController.clear();
    }
  }

  // ─── UI ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
                Icons.child_care, 'Child Profiles', AppTheme.primary),
            const SizedBox(height: 12),
            ..._children.map((child) => _childCard(child)),
            const SizedBox(height: 8),
            // Add new child button
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                        const CreateChildScreen(isFirstTime: false)));
                _loadChildren();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Child Profile'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            _sectionHeader(
                Icons.person, 'Account Details', AppTheme.secondary),
            const SizedBox(height: 12),
            _accountCard(),
            const SizedBox(height: 32),
            _sectionHeader(
                Icons.lock, 'Security', AppTheme.petsColor),
            const SizedBox(height: 12),
            _securityCard(),
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
        Text(title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  Widget _childCard(ChildModel child) {
    final activeChild = context.watch<ChildProvider>().activeChild;
    final isActive = activeChild?.id == child.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? const BorderSide(color: AppTheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: ChildAvatar(
            avatarUrl: child.avatarUrl, nickname: child.nickname, radius: 22),
        title: Row(
          children: [
            Text(child.nickname,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Active',
                    style:
                    TextStyle(fontSize: 11, color: AppTheme.primary)),
              ),
            ]
          ],
        ),
        subtitle: Text('${child.coins} coins',
            style: const TextStyle(color: AppTheme.textSecondary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Switch to this child
            if (!isActive)
              IconButton(
                icon: const Icon(Icons.switch_account,
                    color: AppTheme.primary),
                tooltip: 'Switch to this profile',
                onPressed: () => _switchToChild(child),
              ),
            // Edit nickname
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.textSecondary),
              tooltip: 'Edit nickname',
              onPressed: () => _editChild(child),
            ),
            // Delete
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.danger),
              tooltip: 'Delete profile',
              onPressed: () => _deleteChild(child),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountCard() {
    final email = AuthService.currentUser?.email ?? '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.email, color: AppTheme.textSecondary),
            title: const Text('Email'),
            subtitle: Text(email),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock, color: AppTheme.textSecondary),
            title: const Text('Password'),
            subtitle: const Text('••••••••'),
            trailing: TextButton(
              onPressed: _changePassword,
              child: const Text('Change'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.pin, color: AppTheme.textSecondary),
        title: const Text('Parent PIN'),
        subtitle: const Text('4-digit PIN to access parent dashboard'),
        trailing: TextButton(
          onPressed: _changePin,
          child: const Text('Change'),
        ),
      ),
    );
  }
}