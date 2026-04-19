import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/leaderboard_service.dart';
import '../../../core/widgets/child_avatar.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/friend_model.dart';
import '../../../models/leaderboard_model.dart';

/// Full profile screen for a friend.
/// Shows avatar, nickname, friend code (copyable), and their leaderboard
/// ranking with All / Math / English subject filter chips.
class FriendProfileScreen extends StatefulWidget {
  final ChildInfo friend;

  const FriendProfileScreen({super.key, required this.friend});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  bool _isLoading = true;

  // Leaderboard data per filter
  LeaderboardModel? _statsAll;
  LeaderboardModel? _statsMath;
  LeaderboardModel? _statsEnglish;

  int _rankAll = 0;
  int _rankMath = 0;
  int _rankEnglish = 0;

  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    // Load overall stats + rank
    final stats = await LeaderboardService.getChildStats(widget.friend.id);
    final rankAll = await LeaderboardService.getChildRank(widget.friend.id);

    // Load Math subject rank
    final mathBoard =
        await LeaderboardService.getLeaderboardBySubject(subject: 'Math');
    final mathIdx =
        mathBoard.indexWhere((e) => e.childId == widget.friend.id);

    // Load English subject rank
    final englishBoard =
        await LeaderboardService.getLeaderboardBySubject(subject: 'English');
    final englishIdx =
        englishBoard.indexWhere((e) => e.childId == widget.friend.id);

    if (mounted) {
      setState(() {
        _statsAll = stats;
        _statsMath =
            mathIdx != -1 ? mathBoard[mathIdx] : null;
        _statsEnglish =
            englishIdx != -1 ? englishBoard[englishIdx] : null;
        _rankAll = rankAll;
        _rankMath = mathIdx != -1 ? mathIdx + 1 : 0;
        _rankEnglish = englishIdx != -1 ? englishIdx + 1 : 0;
        _isLoading = false;
      });
    }
  }

  void _copyFriendCode() {
    final code = widget.friend.childCode ?? '';
    if (code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Returns the stats + rank matching the current filter
  LeaderboardModel? get _currentStats {
    switch (_selectedFilter) {
      case 'Math':
        return _statsMath;
      case 'English':
        return _statsEnglish;
      default:
        return _statsAll;
    }
  }

  int get _currentRank {
    switch (_selectedFilter) {
      case 'Math':
        return _rankMath;
      case 'English':
        return _rankEnglish;
      default:
        return _rankAll;
    }
  }

  @override
  Widget build(BuildContext context) {
    final friend = widget.friend;

    return Scaffold(
      appBar: AppBar(
        title: Text(friend.nickname),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // ── Avatar ──────────────────────────────────
                  ChildAvatar(
                    nickname: friend.nickname,
                    avatarUrl: friend.avatarUrl,
                    radius: 60,
                  ),
                  const SizedBox(height: 16),

                  // ── Nickname ────────────────────────────────
                  Text(
                    friend.nickname,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // ── Friend Code card with copy shortcut ─────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Friend Code',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              friend.childCode ?? '--------',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Copy shortcut button
                            Tooltip(
                              message: 'Copy friend code',
                              child: InkWell(
                                onTap: _copyFriendCode,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primary.withOpacity(0.1),
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
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Leaderboard section header ───────────────
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Leaderboard Ranking',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Subject filter chips ─────────────────────
                  Row(
                    children: ['All', 'Math', 'English'].map((subject) {
                      final isSelected = _selectedFilter == subject;
                      final color = subject == 'Math'
                          ? AppTheme.lessonsColor
                          : subject == 'English'
                              ? AppTheme.quizzesColor
                              : AppTheme.primary;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedFilter = subject),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color
                                  : color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? color
                                    : color.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              subject,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : color,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // ── Rank + stats card ────────────────────────
                  _currentStats == null
                      ? _buildNoDataCard()
                      : _buildRankCard(
                          stats: _currentStats!,
                          rank: _currentRank,
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildRankCard({
    required LeaderboardModel stats,
    required int rank,
  }) {
    return Column(
      children: [
        // Gradient rank banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Text(
                rank <= 3 ? _rankEmoji(rank) : '#$rank',
                style: TextStyle(
                  fontSize: rank <= 3 ? 52 : 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rank == 0
                          ? 'Not ranked yet'
                          : rank == 1
                              ? '${widget.friend.nickname} is #1! 🎉'
                              : 'Rank #$rank',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${stats.score} total points',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Stat cards row
        Row(
          children: [
            Expanded(
              child: _miniStatCard(
                '${stats.totalCorrect}',
                'Correct Answers',
                Icons.check_circle_outline,
                AppTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _miniStatCard(
                '${stats.totalCoins}',
                'Coins Earned',
                Icons.monetization_on_outlined,
                AppTheme.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoDataCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.border.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.leaderboard_outlined,
              size: 48, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          Text(
            '${widget.friend.nickname} hasn\'t completed any'
            '${_selectedFilter == 'All' ? '' : ' $_selectedFilter'}'
            ' quizzes yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _miniStatCard(
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
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
        ],
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
}
