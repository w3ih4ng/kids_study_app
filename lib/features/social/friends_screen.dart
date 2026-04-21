import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_theme.dart';
import '../../core/providers/child_provider.dart';
import '../../core/services/friend_service.dart';
import '../../core/widgets/child_avatar.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../models/friend_model.dart';
import 'qr_scanner_screen.dart';
import '../../../../main.dart';
import 'friend_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  List<FriendModel> _friends = [];
  List<FriendRequestModel> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _tabController.dispose();
    super.dispose();
  }

  // Reloads every time Friends screen becomes visible
  @override
  void didPopNext() {
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final child = context.read<ChildProvider>().activeChild!;
    final friends = await FriendService.getFriends(child.id);
    final requests = await FriendService.getPendingRequests(child.id);
    if (mounted) {
      setState(() {
        _friends = friends;
        _pendingRequests = requests;
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
              Text(
                child.nickname,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  child.childCode ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: AppTheme.primary,
                  ),
                ),
              ),
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
            child: const Text('Close'),
          ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
              const Text(
                'Add Friend',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Search by nickname or friend code',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Nickname or code (e.g. A3F2B1C8)',
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
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No children found',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              else
                ...results.map((result) {
                  return ListTile(
                    leading: ChildAvatar(
                      nickname: result.nickname,
                      avatarUrl: result.avatarUrl,
                      radius: 20,
                    ),
                    title: Text(
                      result.nickname,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      result.childCode ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        letterSpacing: 2,
                      ),
                    ),
                    trailing: _AddButton(result: result, child: child),
                  );
                }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    _load();
  }

  Future<void> _removeFriend(FriendModel friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text(
          'Remove ${friend.friendInfo?.nickname ?? 'this friend'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            const Tab(text: 'My Friends'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Requests'),
                  if (_pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.danger,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingRequests.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'My QR Code',
            onPressed: _showMyQrCode,
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR Code',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrScannerScreen()),
              );
              _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Friend',
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [_buildFriendsList(), _buildRequestsList()],
            ),
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: EmptyStateWidget(
              message:
                  'No friends yet!\nSearch or scan a QR code to add friends.',
              icon: Icons.people_outline,
              actionLabel: 'Add Friend',
              onAction: _showSearchDialog,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _friends.length,
        itemBuilder: (_, i) {
          final friend = _friends[i];
          final info = friend.friendInfo;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                final info = friend.friendInfo;
                if (info != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FriendProfileScreen(friend: info),
                    ),
                  );
                }
              },
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (friend.isBestFriend) ...[
                      const SizedBox(width: 6),
                      const Text('⭐', style: TextStyle(fontSize: 14)),
                    ],
                  ],
                ),
                subtitle: Text(
                  info?.childCode ?? '',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    letterSpacing: 2,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        friend.isBestFriend ? Icons.star : Icons.star_border,
                        color: friend.isBestFriend
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                      ),
                      onPressed: () async {
                        final child = context
                            .read<ChildProvider>()
                            .activeChild!;
                        await FriendService.toggleBestFriend(
                          childId: child.id,
                          friendId: friend.friendId,
                          isBestFriend: !friend.isBestFriend,
                        );
                        _load();
                        if (mounted) {
                          AppSnackbar.success(
                            context,
                            friend.isBestFriend
                                ? '${friend.friendInfo?.nickname} removed from best friends.'
                                : '${friend.friendInfo?.nickname} is now your best friend! ⭐',
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.person_remove,
                        color: AppTheme.danger,
                      ),
                      onPressed: () => _removeFriend(friend),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestsList() {
    if (_pendingRequests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: EmptyStateWidget(
              message: 'No pending friend requests.',
              icon: Icons.mail_outline,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (_, i) {
          final request = _pendingRequests[i];
          final sender = request.senderInfo;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ChildAvatar(
                    nickname: sender?.nickname ?? '?',
                    avatarUrl: sender?.avatarUrl,
                    radius: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sender?.nickname ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          sender?.childCode ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            letterSpacing: 2,
                          ),
                        ),
                        const Text(
                          'wants to be your friend!',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      // Accept
                      ElevatedButton(
                        onPressed: () async {
                          final child = context
                              .read<ChildProvider>()
                              .activeChild!;
                          await FriendService.acceptRequest(
                            requestId: request.id,
                            senderId: request.senderId,
                            receiverId: child.id,
                          );
                          _load();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'You and ${sender?.nickname} are now friends!',
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Accept',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Decline
                      OutlinedButton(
                        onPressed: () async {
                          await FriendService.declineRequest(request.id);
                          _load();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.danger,
                          side: const BorderSide(color: AppTheme.danger),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Decline',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
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

// ── Add button widget ─────────────────────────────────────
class _AddButton extends StatefulWidget {
  final ChildInfo result;
  final dynamic child;

  const _AddButton({required this.result, required this.child});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  String _status = 'none'; // none, pending, friends
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final isFriend = await FriendService.isFriend(
      childId: widget.child.id,
      friendId: widget.result.id,
    );
    if (isFriend) {
      setState(() {
        _status = 'friends';
        _isLoading = false;
      });
      return;
    }
    final reqStatus = await FriendService.getRequestStatus(
      senderId: widget.child.id,
      receiverId: widget.result.id,
    );
    setState(() {
      _status = reqStatus ?? 'none';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_status == 'friends') {
      return const Text(
        'Friends ✓',
        style: TextStyle(
          color: AppTheme.success,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }

    if (_status == 'pending') {
      return const Text(
        'Requested',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      );
    }

    return ElevatedButton(
      onPressed: () async {
        await FriendService.sendRequest(
          senderId: widget.child.id,
          receiverId: widget.result.id,
        );
        setState(() => _status = 'pending');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${widget.result.nickname}!'),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('Add', style: TextStyle(fontSize: 12)),
    );
  }
}
