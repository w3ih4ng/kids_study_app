import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/providers/child_provider.dart';
import '../../core/services/child_service.dart';
import '../../core/widgets/app_snackbar.dart';
import '../child/home_screen_shell.dart';

class CreateChildScreen extends StatefulWidget {
  final bool isFirstTime;
  const CreateChildScreen({super.key, this.isFirstTime = false});

  @override
  State<CreateChildScreen> createState() => _CreateChildScreenState();
}

class _CreateChildScreenState extends State<CreateChildScreen> {
  final _nicknameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _create() async {
    if (_nicknameController.text.trim().isEmpty) {
      AppSnackbar.warning(context, 'Please enter a nickname for your child.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ChildService.createChild(_nicknameController.text.trim());
      final children = await ChildService.getChildren();
      if (mounted) {
        final newChild = children.last;
        context.read<ChildProvider>().setActiveChild(newChild);

        if (widget.isFirstTime) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ChildDashboardScreen()),
            (route) => false,
          );
        } else {
          Navigator.pop(context);
          AppSnackbar.success(context, 'Child profile created successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context,
          'Failed to create profile. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isFirstTime
          ? null
          : AppBar(title: const Text('Add Child Profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.child_care, size: 72, color: AppTheme.primary),
              const SizedBox(height: 16),
              Text(
                widget.isFirstTime
                    ? "Let's set up your first child profile!"
                    : 'Add a new child profile',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter a nickname for your child.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Child Nickname',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.face),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Continue', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
