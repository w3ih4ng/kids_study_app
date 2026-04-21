import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_theme.dart';
import '../core/providers/child_provider.dart';
import '../core/services/friend_service.dart';
import '../core/services/leaderboard_service.dart';
import '../core/widgets/child_avatar.dart';
import '../models/friend_model.dart';
import '../models/leaderboard_model.dart';
import 'social/friend_profile_screen.dart';
import 'social/friends_screen.dart';
import 'social/leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

// No more RouteAware
class HomeScreenState extends State<HomeScreen> {
  List<FriendModel> _friends = [];
  List<LeaderboardModel> _topPlayers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Called by child_dashboard_screen when home tab is tapped
  void reload() => _load();

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final child = context.read<ChildProvider>().activeChild!;
    final friends = await FriendService.getFriends(child.id);
    final top = await LeaderboardService.getLeaderboard(limit: 3);
    if (mounted) {
      setState(() {
        _friends = friends;
        _topPlayers = top;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Friends section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Friends',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          // Reload after returning from FriendsScreen
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FriendsScreen(),
                            ),
                          );
                          _load(); // reload friends + leaderboard
                        },
                        child: const Text('See all →'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _friends.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cs.outline),
                          ),
                          child: Center(
                            child: Text(
                              'No friends yet! Add some friends.',
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _friends.length,
                            itemBuilder: (_, i) {
                              final friend = _friends[i];
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: GestureDetector(
                                  onTap: () {
                                    final info = friend.friendInfo;
                                    if (info != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              FriendProfileScreen(friend: info),
                                        ),
                                      );
                                      // No reload — viewing profile
                                      // doesn't change friends list
                                    }
                                  },
                                  child: Column(
                                    children: [
                                      Stack(
                                        children: [
                                          ChildAvatar(
                                            nickname:
                                                friend.friendInfo?.nickname ??
                                                '?',
                                            avatarUrl:
                                                friend.friendInfo?.avatarUrl,
                                            radius: 28,
                                          ),
                                          if (friend.isBestFriend)
                                            const Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Text(
                                                '⭐',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        friend.friendInfo?.nickname ?? '?',
                                        style: const TextStyle(fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 24),

                  // Leaderboard preview
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Top Players',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          // Reload after returning from LeaderboardScreen
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LeaderboardScreen(),
                            ),
                          );
                          _load();
                        },
                        child: const Text('Full board →'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _topPlayers.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cs.outline),
                          ),
                          child: Center(
                            child: Text(
                              'No rankings yet. Complete a quiz!',
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: _topPlayers.asMap().entries.map((e) {
                            final rank = e.key + 1;
                            final entry = e.value;
                            final child = context
                                .read<ChildProvider>()
                                .activeChild;
                            final isMe = entry.childId == child?.id;

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: isMe
                                  ? null
                                  : () => showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(24),
                                        ),
                                      ),
                                      // No reload after modal closes
                                      builder: (_) =>
                                          LimitedProfileSheet(entry: entry),
                                    ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? AppTheme.primary.withValues(alpha: 0.1)
                                      : cs.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isMe ? AppTheme.primary : cs.outline,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      rank == 1
                                          ? '🥇'
                                          : rank == 2
                                          ? '🥈'
                                          : '🥉',
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    ChildAvatar(
                                      nickname:
                                          entry.childInfo?.nickname ?? '?',
                                      avatarUrl: entry.childInfo?.avatarUrl,
                                      radius: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        entry.childInfo?.nickname ?? 'Unknown',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isMe
                                              ? AppTheme.primary
                                              : cs.onSurface,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${entry.score} pts',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
  }
}
