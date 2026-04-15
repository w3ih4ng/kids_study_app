import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/providers/child_provider.dart';
import '../../../core/services/leaderboard_service.dart';
import '../../../core/widgets/child_avatar.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/leaderboard_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LeaderboardModel> _leaderboard = [];
  LeaderboardModel? _myStats;
  int _myRank = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final child = context.read<ChildProvider>().activeChild!;
    final board = await LeaderboardService.getLeaderboard();
    final stats = await LeaderboardService.getChildStats(child.id);
    final rank = await LeaderboardService.getChildRank(child.id);
    if (mounted) {
      setState(() {
        _leaderboard = board;
        _myStats = stats;
        _myRank = rank;
        _isLoading = false;
      });
    }
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
            Tab(text: 'Rankings'),
            Tab(text: 'My Stats'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildRankings(),
          _buildMyStats(),
        ],
      ),
    );
  }

  Widget _buildRankings() {
    if (_leaderboard.isEmpty) {
      return const Center(
        child: Text('No rankings yet. Complete a quiz to appear!',
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center),
      );
    }

    final child = context.read<ChildProvider>().activeChild;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leaderboard.length,
      itemBuilder: (_, i) {
        final entry = _leaderboard[i];
        final isMe = entry.childId == child?.id;
        final rank = i + 1;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isMe
                ? AppTheme.primary.withOpacity(0.1)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMe
                  ? AppTheme.primary
                  : AppTheme.border,
              width: isMe ? 2 : 1,
            ),
          ),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rank badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _rankColor(rank).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: rank <= 3
                        ? Text(_rankEmoji(rank),
                        style:
                        const TextStyle(fontSize: 18))
                        : Text('#$rank',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _rankColor(rank))),
                  ),
                ),
                const SizedBox(width: 8),
                ChildAvatar(
                  nickname:
                  entry.childInfo?.nickname ?? '?',
                  avatarUrl: entry.childInfo?.avatarUrl,
                  radius: 18,
                ),
              ],
            ),
            title: Row(
              children: [
                Text(
                  entry.childInfo?.nickname ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isMe
                        ? AppTheme.primary
                        : AppTheme.textPrimary,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
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
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _rankColor(rank).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${entry.score} pts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _rankColor(rank),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary,
                  AppTheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  _myRank <= 3
                      ? _rankEmoji(_myRank)
                      : '#$_myRank',
                  style: const TextStyle(fontSize: 48),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_myStats!.score} total points',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats cards
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

          // Bar chart — score breakdown
          const Text('Score Breakdown',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'Score = Coins + (Correct Answers × 10)',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (_myStats!.score + 50).toDouble(),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const titles = [
                          'Coins',
                          'Answers\n×10',
                          'Total'
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            titles[value.toInt()],
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
                      2,
                      _myStats!.score.toDouble(),
                      AppTheme.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Top 3 bar chart comparison
          if (_leaderboard.length >= 2) ...[
            const Text('Top Players Comparison',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildComparisonChart(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonChart() {
    final top = _leaderboard.take(5).toList();
    final child = context.read<ChildProvider>().activeChild;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (top.first.score + 50).toDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = top[groupIndex];
              return BarTooltipItem(
                '${entry.childInfo?.nickname}\n${entry.score} pts',
                const TextStyle(
                    color: Colors.white, fontSize: 11),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= top.length) return const SizedBox();
                final nickname =
                    top[index].childInfo?.nickname ?? '?';
                final short = nickname.length > 6
                    ? '${nickname.substring(0, 6)}..'
                    : nickname;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(short,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary)),
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
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _statCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 28,
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
      case 1: return const Color(0xFFFFD700);
      case 2: return const Color(0xFFC0C0C0);
      case 3: return const Color(0xFFCD7F32);
      default: return AppTheme.primary;
    }
  }

  String _rankEmoji(int rank) {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '#$rank';
    }
  }
}