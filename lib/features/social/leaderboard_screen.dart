import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/providers/child_provider.dart';
import '../../core/services/leaderboard_service.dart';
import '../../core/widgets/child_avatar.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/leaderboard_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // All players data per subject
  List<LeaderboardModel> _allPlayers = [];
  List<LeaderboardModel> _allMath = [];
  List<LeaderboardModel> _allEnglish = [];

  // Friends data per subject
  List<LeaderboardModel> _friendsAll = [];
  List<LeaderboardModel> _friendsMath = [];
  List<LeaderboardModel> _friendsEnglish = [];

  LeaderboardModel? _myStats;
  int _myRank = 0;
  bool _isLoading = true;

  // Subject filter state for each tab
  String _allSubjectFilter = 'All';
  String _friendsSubjectFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final child = context.read<ChildProvider>().activeChild!;

    final all = await LeaderboardService.getLeaderboard();
    final friends =
    await LeaderboardService.getFriendsLeaderboard(childId: child.id);
    final math =
    await LeaderboardService.getLeaderboardBySubject(subject: 'Math');
    final english =
    await LeaderboardService.getLeaderboardBySubject(subject: 'English');
    final friendsMath =
    await LeaderboardService.getFriendsLeaderboardBySubject(
        childId: child.id, subject: 'Math');
    final friendsEnglish =
    await LeaderboardService.getFriendsLeaderboardBySubject(
        childId: child.id, subject: 'English');
    final stats = await LeaderboardService.getChildStats(child.id);
    final rank = await LeaderboardService.getChildRank(child.id);

    if (mounted) {
      setState(() {
        _allPlayers = all;
        _allMath = math;
        _allEnglish = english;
        _friendsAll = friends;
        _friendsMath = friendsMath;
        _friendsEnglish = friendsEnglish;
        _myStats = stats;
        _myRank = rank;
        _isLoading = false;
      });
    }
  }

  // Get current list based on tab + filter
  List<LeaderboardModel> get _currentAllList {
    switch (_allSubjectFilter) {
      case 'Math':
        return _allMath;
      case 'English':
        return _allEnglish;
      default:
        return _allPlayers;
    }
  }

  List<LeaderboardModel> get _currentFriendsList {
    switch (_friendsSubjectFilter) {
      case 'Math':
        return _friendsMath;
      case 'English':
        return _friendsEnglish;
      default:
        return _friendsAll;
    }
  }

  // ── NEW: show limited profile bottom sheet ──────────────
  void _showLimitedProfile(LeaderboardModel entry) {
    final info = entry.childInfo;
    if (info == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => LimitedProfileSheet(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'All Players'),
            Tab(text: 'Friends'),
            Tab(text: 'My Stats'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildFilteredTab(
            list: _currentAllList,
            selectedFilter: _allSubjectFilter,
            onFilterChanged: (f) =>
                setState(() => _allSubjectFilter = f),
            emptyMessage:
            'No rankings yet.\nComplete a quiz to appear!',
          ),
          _buildFilteredTab(
            list: _currentFriendsList,
            selectedFilter: _friendsSubjectFilter,
            onFilterChanged: (f) =>
                setState(() => _friendsSubjectFilter = f),
            emptyMessage:
            'None of your friends are on the leaderboard yet.',
          ),
          _buildMyStats(),
        ],
      ),
    );
  }

  // ── Filtered tab with subject chips ──────────────────────
  Widget _buildFilteredTab({
    required List<LeaderboardModel> list,
    required String selectedFilter,
    required Function(String) onFilterChanged,
    required String emptyMessage,
  }) {
    return Column(
      children: [
        // Subject filter chips
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppTheme.primary.withValues(alpha:0.04),
          child: Row(
            children: ['All', 'Math', 'English'].map((subject) {
              final isSelected = selectedFilter == subject;
              final color = subject == 'Math'
                  ? AppTheme.lessonsColor
                  : subject == 'English'
                  ? AppTheme.quizzesColor
                  : AppTheme.primary;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onFilterChanged(subject),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color
                          : color.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : color.withValues(alpha:0.3),
                      ),
                    ),
                    child: Text(
                      subject,
                      style: TextStyle(
                        color: isSelected ? Colors.white : color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Rankings list
        Expanded(
          child: list.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.leaderboard_outlined,
                      size: 72, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          )
              : _buildRankingsList(list),
        ),
      ],
    );
  }

  Widget _buildRankingsList(List<LeaderboardModel> list) {
    final child = context.read<ChildProvider>().activeChild;
    final cs = Theme.of(context).colorScheme;          // add this

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final entry = list[i];
        final isMe = entry.childId == child?.id;
        final rank = i + 1;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isMe
                ? AppTheme.primary.withValues(alpha:0.08)
                : cs.surface,                           // changed
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMe ? AppTheme.primary : cs.outline, // changed
              width: isMe ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isMe ? null : () => _showLimitedProfile(entry),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 36,
                    child: Center(
                      child: rank <= 3
                          ? Text(_rankEmoji(rank),
                          style: const TextStyle(fontSize: 22))
                          : Text('#$rank',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _rankColor(rank))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChildAvatar(
                    nickname: entry.childInfo?.nickname ?? '?',
                    avatarUrl: entry.childInfo?.avatarUrl,
                    radius: 20,
                  ),
                ],
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      entry.childInfo?.nickname ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMe
                            ? AppTheme.primary
                            : cs.onSurface,           // changed
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('You',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                '${entry.totalCorrect} correct · ${entry.totalCoins} coins',
                style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha:0.6)),  // changed
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _rankColor(rank).withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${entry.score} pts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _rankColor(rank),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyStats() {
    if (_myStats == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Complete a quiz to see your stats here!',
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rank card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  _myRank <= 3 ? _rankEmoji(_myRank) : '#$_myRank',
                  style: const TextStyle(fontSize: 52),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _myRank == 1
                            ? 'You\'re #1! 🎉'
                            : 'Rank #$_myRank',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_myStats!.score} total points',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _statCard(
                  '${_myStats!.totalCorrect}',
                  'Correct Answers',
                  Icons.check_circle,
                  AppTheme.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  '${_myStats!.totalCoins}',
                  'Coins Earned',
                  Icons.monetization_on,
                  AppTheme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text('Score Breakdown',
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'Score = Coins + (Correct Answers × 10)',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (_myStats!.score + 50).toDouble(),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        const labels = [
                          'Coins',
                          'Answers\n×10',
                          'Total'
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[value.toInt()],
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _barGroup(0, _myStats!.totalCoins.toDouble(),
                      AppTheme.accent),
                  _barGroup(
                      1,
                      (_myStats!.totalCorrect * 10).toDouble(),
                      AppTheme.success),
                  _barGroup(
                      2, _myStats!.score.toDouble(), AppTheme.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_allPlayers.length >= 2) ...[
            const Text('Top 5 Comparison',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: _buildComparisonChart(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonChart() {
    final child = context.read<ChildProvider>().activeChild;
    final top = _allPlayers.take(5).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (top.first.score + 50).toDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) {
              final entry = top[group.x];
              return BarTooltipItem(
                '${entry.childInfo?.nickname ?? '?'}\n${entry.score} pts',
                const TextStyle(color: Colors.white, fontSize: 11),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i >= top.length) return const SizedBox();
                final name = top[i].childInfo?.nickname ?? '?';
                final short =
                name.length > 6 ? '${name.substring(0, 6)}..' : name;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(short,
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: top.asMap().entries.map((e) {
          final isMe = e.value.childId == child?.id;
          return _barGroup(
            e.key,
            e.value.score.toDouble(),
            isMe ? AppTheme.accent : AppTheme.primary,
          );
        }).toList(),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 32,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _statCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppTheme.primary;
    }
  }

  String _rankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }
}

// ── Limited profile bottom sheet ─────────────────────────
/// Shown when tapping a leaderboard entry (non-self).
/// Intentionally limited — only shows avatar, nickname, friend code
/// (copyable), rank, and score. No full stats.
class LimitedProfileSheet extends StatelessWidget {
  final LeaderboardModel entry;

  const LimitedProfileSheet({required this.entry});

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    Navigator.pop(context); // close sheet first
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Friend code "$code" copied!'),
          ],
        ),
        backgroundColor: AppTheme.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _rankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = entry.childInfo;
    final nickname = info?.nickname ?? 'Unknown';
    final code = info?.childCode ?? '';

    // Approximate rank from score (sheet doesn't know list position,
    // caller can pass rank explicitly — here we show score prominence)
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Avatar
          ChildAvatar(
            nickname: nickname,
            avatarUrl: info?.avatarUrl,
            radius: 44,
          ),
          const SizedBox(height: 12),

          // Nickname
          Text(
            nickname,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),

          // Score badge
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${entry.score} pts',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Friend code row with copy button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(16),
              border:
              Border.all(color: AppTheme.primary.withValues(alpha:0.2)),
            ),
            child: Column(
              children: [
                const Text(
                  'Friend Code',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      code.isNotEmpty ? code : '--------',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: AppTheme.primary,
                      ),
                    ),
                    if (code.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Tooltip(
                        message: 'Copy friend code',
                        child: InkWell(
                          onTap: () => _copyCode(context, code),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.copy_rounded,
                              size: 18,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Use this code to send a friend request',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Close button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Close',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}