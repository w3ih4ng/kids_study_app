import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/child_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/child_service.dart';
import '../../../models/child_model.dart';
import 'create_child_screen.dart';
import 'child_dashboard_screen.dart';
import 'login_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  List<ChildModel> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final children = await ChildService.getChildren();
    if (mounted) setState(() { _children = children; _isLoading = false; });
  }

  Future<void> _deleteChild(ChildModel child) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text('Remove ${child.nickname}\'s profile? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await ChildService.deleteChild(child.id);
      _loadChildren();
    }
  }

  void _selectChild(ChildModel child) {
    context.read<ChildProvider>().setActiveChild(child);
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const ChildDashboardScreen()));
  }

  Future<void> _changePin() async {
    final controller = TextEditingController();
    final newPin = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Enter new 4-digit PIN',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                if (controller.text.length == 4) {
                  Navigator.pop(context, controller.text);
                }
              },
              child: const Text('Save')),
        ],
      ),
    );

    if (newPin != null) {
      await ChildService.updatePin(newPin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN updated successfully!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.pin),
            tooltip: 'Change PIN',
            onPressed: _changePin,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _children.isEmpty
          ? const Center(child: Text('No children profiles yet.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _children.length,
        itemBuilder: (context, i) {
          final child = _children[i];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                  child: Icon(Icons.child_care)),
              title: Text(child.nickname,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${child.coins} coins'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteChild(child),
                  ),
                ],
              ),
              onTap: () => _selectChild(child),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const CreateChildScreen(isFirstTime: false))),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}