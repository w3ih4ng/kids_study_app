import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/providers/child_provider.dart';
import '../../../core/services/child_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/child_avatar.dart';
import '../../auth/screens/pin_screen.dart';
import '../../auth/screens/parent_dashboard_screen.dart';

class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({super.key});

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  bool _isUploading = false;

  Future<void> _changeProfilePicture() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Change Profile Picture',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primary,
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.secondary,
                child: Icon(Icons.photo_library, color: Colors.white),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final child = context.read<ChildProvider>().activeChild!;
      final bytes = await picked.readAsBytes();
      final fileName = 'avatar_${child.id}.jpg';

      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(fileName, bytes,
          fileOptions: const FileOptions(upsert: true));

      final url = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      final urlWithCacheBust =
          '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      await Supabase.instance.client
          .from('children')
          .update({'avatar_url': urlWithCacheBust}).eq('id', child.id);

      final children = await ChildService.getChildren();
      final updated = children.firstWhere((c) => c.id == child.id);
      if (mounted) {
        context.read<ChildProvider>().setActiveChild(updated);
        setState(() {});
        AppSnackbar.success(context, 'Profile picture updated!');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to upload picture. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

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
              MaterialPageRoute(
                  builder: (_) => const ParentDashboardScreen()),
                  (route) => false,
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.error(context, 'Failed to load PIN. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = context.watch<ChildProvider>().activeChild;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                ChildAvatar(
                  avatarUrl: child?.avatarUrl,
                  nickname: child?.nickname ?? '',
                  radius: 60,
                ),
                GestureDetector(
                  onTap: _isUploading ? null : _changeProfilePicture,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _isUploading
                        ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.camera_alt,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              child?.nickname ?? '',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on,
                      color: AppTheme.accent, size: 36),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Coins',
                          style: TextStyle(color: AppTheme.textSecondary)),
                      Text(
                        '${child?.coins ?? 0}',
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border:
                Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Text('My Friend Code',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    child?.childCode ?? '--------',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Share this code with friends to connect!',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _goToParentDashboard,
                icon: const Icon(Icons.shield_outlined),
                label: const Text('Parent Dashboard'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.primary),
                  foregroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}