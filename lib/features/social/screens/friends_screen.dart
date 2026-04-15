import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/providers/child_provider.dart';
import '../../../core/services/friend_service.dart';
import '../../../core/widgets/child_avatar.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/friend_model.dart';
import 'qr_scanner_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<FriendModel> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final child = context.read<ChildProvider>().activeChild!;
    final friends = await FriendService.getFriends(child.id);
    if (mounted) {
      setState(() {
        _friends = friends;
        _isLoading = false;
      });
    }
  }

  void _showMyQrCode() {
    final child = context.read<ChildProvider>().activeChild!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('My QR Code', textAlign: TextAlign.center),
        content: SizedBox(
          width: 200,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: child.id,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(child.nickname,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              const Text(
                'Ask your friend to scan this!',
                style: TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _showSearchDialog() async {
    final child = context.read<ChildProvider>().activeChild!;
    final controller = TextEditingController();
    List<ChildInfo> results = [];
    bool isSearching = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Search Friends',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Search by nickname',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) async {
                  if (value.trim().length < 2) {
                    setModalState(() => results = []);
                    return;
                  }
                  setModalState(() => isSearching = true);
                  final found = await FriendService.searchChildren(
                    query: value.trim(),
                    currentChildId: child.id,
                  );
                  setModalState(() {
                    results = found;
                    isSearching = false;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (isSearching)
                const CircularProgressIndicator()
              else if (results.isEmpty && controller.text.length >= 2)
                const Text('No children found',
                    style:
                    TextStyle(color: AppTheme.textSecondary))
              else
                ...results.map((result) {
                  return ListTile(
                    leading: ChildAvatar(
                        nickname: result.nickname,
                        avatarUrl: result.avatarUrl,
                        radius: 20),
                    title: Text(result.nickname),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        final already =
                        await FriendService.isFriend(
                          childId: child.id,
                          friendId: result.id,
                        );
                        if (already) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                Text('Already friends!')),
                          );
                          return;
                        }
                        await FriendService.addFriend(
                          childId: child.id,
                          friendId: result.id,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          _load();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Added ${result.nickname} as friend!')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Add',
                          style: TextStyle(fontSize: 12)),
                    ),
                  );
                }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeFriend(FriendModel friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text(
            'Remove ${friend.friendInfo?.nickname ?? 'this friend'}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove',
                  style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (confirmed == true) {
      final child = context.read<ChildProvider>().activeChild!;
      await FriendService.removeFriend(
        childId: child.id,
        friendId: friend.friendId,
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          // My QR code
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'My QR Code',
            onPressed: _showMyQrCode,
          ),
          // Scan QR
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR Code',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const QrScannerScreen()),
              );
              _load();
            },
          ),
          // Search
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Friend',
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _friends.isEmpty
          ? EmptyStateWidget(
        message:
        'No friends yet!\nSearch or scan a QR code to add friends.',
        icon: Icons.people_outline,
        actionLabel: 'Add Friend',
        onAction: _showSearchDialog,
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _friends.length,
        itemBuilder: (_, i) {
          final friend = _friends[i];
          final info = friend.friendInfo;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: ChildAvatar(
                nickname: info?.nickname ?? '?',
                avatarUrl: info?.avatarUrl,
                radius: 22,
              ),
              title: Row(
                children: [
                  Text(
                    info?.nickname ?? 'Unknown',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                  if (friend.isBestFriend) ...[
                    const SizedBox(width: 6),
                    const Text('⭐',
                        style: TextStyle(fontSize: 14)),
                  ],
                ],
              ),
              subtitle: Text(
                friend.isBestFriend
                    ? 'Best Friend'
                    : 'Friend',
                style: TextStyle(
                  color: friend.isBestFriend
                      ? AppTheme.accent
                      : AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle best friend
                  IconButton(
                    icon: Icon(
                      friend.isBestFriend
                          ? Icons.star
                          : Icons.star_border,
                      color: friend.isBestFriend
                          ? AppTheme.accent
                          : AppTheme.textSecondary,
                    ),
                    tooltip: friend.isBestFriend
                        ? 'Remove best friend'
                        : 'Mark as best friend',
                    onPressed: () async {
                      final child = context
                          .read<ChildProvider>()
                          .activeChild!;
                      await FriendService.toggleBestFriend(
                        friendId: friend.friendId,
                        childId: child.id,
                        isBestFriend:
                        !friend.isBestFriend,
                      );
                      _load();
                    },
                  ),
                  // Remove
                  IconButton(
                    icon: const Icon(Icons.person_remove,
                        color: AppTheme.danger),
                    onPressed: () =>
                        _removeFriend(friend),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}