import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/providers/child_provider.dart';
import '../../../../core/services/friend_service.dart';
import '../../../../core/services/leaderboard_service.dart';
import '../../../../core/widgets/child_avatar.dart';
import '../../../../models/friend_model.dart';
import '../../../../models/leaderboard_model.dart';
import '../../social/screens/friend_profile_screen.dart';
import '../../social/screens/friends_screen.dart';
import '../../social/screens/leaderboard_screen.dart';
import 'package:kids_study_app/main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with RouteAware{
  List<FriendModel> _friends = [];
  List<LeaderboardModel> _topPlayers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _load();
  }

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
                const Text('My Friends',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const FriendsScreen())),
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
                      color: cs.onSurface.withOpacity(0.6)),
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
                                  FriendProfileScreen(
                                      friend: info),
                            ),
                          );
                        }
                      },
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              ChildAvatar(
                                nickname: friend
                                    .friendInfo?.nickname ??
                                    '?',
                                avatarUrl:
                                friend.friendInfo?.avatarUrl,
                                radius: 28,
                              ),
                              if (friend.isBestFriend)
                                const Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Text('⭐',
                                      style: TextStyle(
                                          fontSize: 12)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            friend.friendInfo?.nickname ?? '?',
                            style:
                            const TextStyle(fontSize: 11),
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
                const Text('Top Players',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) =>
                          const LeaderboardScreen())),
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
                      color: cs.onSurface.withOpacity(0.6)),
                ),
              ),
            )
                : Column(
              children:
              _topPlayers.asMap().entries.map((e) {
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
                    shape:
                    const RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.vertical(
                          top:
                          Radius.circular(24)),
                    ),
                    builder: (_) =>
                        LimitedProfileSheet(
                            entry: entry),
                  ),
                  child: Container(
                    margin:
                    const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? AppTheme.primary
                          .withOpacity(0.1)
                          : cs.surface,
                      borderRadius:
                      BorderRadius.circular(12),
                      border: Border.all(
                          color: isMe
                              ? AppTheme.primary
                              : cs.outline),
                    ),
                    child: Row(
                      children: [
                        Text(
                          rank == 1
                              ? '🥇'
                              : rank == 2
                              ? '🥈'
                              : '🥉',
                          style: const TextStyle(
                              fontSize: 20),
                        ),
                        const SizedBox(width: 12),
                        ChildAvatar(
                          nickname: entry.childInfo
                              ?.nickname ??
                              '?',
                          avatarUrl:
                          entry.childInfo?.avatarUrl,
                          radius: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.childInfo?.nickname ??
                                'Unknown',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isMe
                                  ? AppTheme.primary
                                  : cs.onSurface,
                            ),
                          ),
                        ),
                        const Text(
                          // score shown via entry below
                          '',
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