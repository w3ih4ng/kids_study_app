import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/child_service.dart';
import '../../core/widgets/app_snackbar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _newPasswordController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    _newPasswordController.clear();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: _newPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (_newPasswordController.text.trim().isEmpty) {
        AppSnackbar.warning(context, 'Please enter a new password.');
        return;
      }
      try {
        await AuthService.updatePassword(_newPasswordController.text.trim());
        if (mounted)
          AppSnackbar.success(context, 'Password updated successfully!');
      } catch (e) {
        if (mounted)
          AppSnackbar.error(
            context,
            'Failed to update password: ${e.toString()}',
          );
      }
    }
  }

  Future<void> _changePin() async {
    _pinController.clear();
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_pinController.text.length == 4) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (_pinController.text.length != 4) {
        AppSnackbar.warning(context, 'PIN must be exactly 4 digits.');
        return;
      }
      try {
        await ChildService.updatePin(_pinController.text);
        if (mounted) AppSnackbar.success(context, 'PIN updated successfully!');
      } catch (e) {
        if (mounted)
          AppSnackbar.error(context, 'Failed to update PIN. Try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.person, 'Account Details', AppTheme.secondary),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.email,
                      color: AppTheme.textSecondary,
                    ),
                    title: const Text('Email'),
                    subtitle: Text(email),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.lock,
                      color: AppTheme.textSecondary,
                    ),
                    title: const Text('Password'),
                    subtitle: const Text('••••••••'),
                    trailing: TextButton(
                      onPressed: _changePassword,
                      child: const Text('Change'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _sectionHeader(Icons.lock, 'Security', AppTheme.petsColor),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.pin, color: AppTheme.textSecondary),
                title: const Text('Parent PIN'),
                subtitle: const Text('4-digit PIN to access parent dashboard'),
                trailing: TextButton(
                  onPressed: _changePin,
                  child: const Text('Change'),
                ),
              ),
            ),
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
