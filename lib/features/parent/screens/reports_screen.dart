import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/providers/child_provider.dart';
import '../../../core/services/child_service.dart';
import '../../../core/widgets/child_avatar.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/child_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<ChildModel> _children = [];
  ChildModel? _selectedChild;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;
  bool _isLoadingResults = false;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final children = await ChildService.getChildren();
    if (mounted) {
      setState(() {
        _children = children;
        _selectedChild =
        children.isNotEmpty ? children.first : null;
        _isLoading = false;
      });
      if (_selectedChild != null) {
        _loadResults(_selectedChild!.id);
      }
    }
  }

  Future<void> _loadResults(String childId) async {
    setState(() => _isLoadingResults = true);
    final response = await supabase
        .from('quiz_results')
        .select('*, quizzes(title, subject, coin_value)')
        .eq('child_id', childId)
        .order('completed_at', ascending: false);
    if (mounted) {
      setState(() {
        _results = List<Map<String, dynamic>>.from(response);
        _isLoadingResults = false;
      });
    }
  }

  // ── Summary stats ────────────────────────────────
  int get _totalQuizzes => _results.length;

  int get _totalCoins => _results.fold(
      0, (sum, r) => sum + (r['coins_earned'] as int? ?? 0));

  int get _totalCorrect =>
      _results.fold(0, (sum, r) => sum + (r['score'] as int? ?? 0));

  int get _totalQuestions =>
      _results.fold(0, (sum, r) => sum + (r['total'] as int? ?? 0));

  double get _averageScore => _totalQuestions == 0
      ? 0
      : (_totalCorrect / _totalQuestions) * 100;

  int get _perfectScores => _results
      .where((r) => r['score'] == r['total'])
      .length;

  // ── Chart data ───────────────────────────────────
  List<FlSpot> get _scoreSpots {
    final recent = _results.take(7).toList().reversed.toList();
    return recent.asMap().entries.map((e) {
      final score = e.value['score'] as int? ?? 0;
      final total = e.value['total'] as int? ?? 1;
      return FlSpot(
          e.key.toDouble(), (score / total * 100));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: _isLoading
          ? const LoadingWidget()
          : _children.isEmpty
          ? const Center(
        child: Text('No children profiles found.',
            style: TextStyle(
                color: AppTheme.textSecondary)),
      )
          : Column(
        children: [
          // Child selector
          Container(
            color: AppTheme.primary.withOpacity(0.05),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _children.map((child) {
                  final isSelected =
                      _selectedChild?.id == child.id;
                  return GestureDetector(
                    onTap: () {
                      setState(
                              () => _selectedChild = child);
                      _loadResults(child.id);
                    },
                    child: AnimatedContainer(
                      duration:
                      const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.surface,
                        borderRadius:
                        BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          ChildAvatar(
                            nickname: child.nickname,
                            avatarUrl: child.avatarUrl,
                            radius: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            child.nickname,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Report content
          Expanded(
            child: _isLoadingResults
                ? const LoadingWidget()
                : _results.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  const Icon(
                      Icons.assignment_outlined,
                      size: 72,
                      color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    '${_selectedChild?.nickname} hasn\'t completed any quizzes yet.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color:
                        AppTheme.textSecondary),
                  ),
                ],
              ),
            )
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // Summary cards
                  _buildSummaryCards(),
                  const SizedBox(height: 24),

                  // Score trend chart
                  if (_results.length >= 2) ...[
                    const Text('Score Trend',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text(
                      'Last 7 quiz scores (%)',
                      style: TextStyle(
                          color:
                          AppTheme.textSecondary,
                          fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    _buildScoreChart(),
                    const SizedBox(height: 24),
                  ],

                  // Subject breakdown
                  const Text('By Subject',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildSubjectBreakdown(),
                  const SizedBox(height: 24),

                  // Quiz history
                  const Text('Quiz History',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildQuizHistory(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        // Top row
        Row(
          children: [
            Expanded(
              child: _statCard(
                value: '$_totalQuizzes',
                label: 'Quizzes Done',
                icon: Icons.quiz,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                value:
                '${_averageScore.toStringAsFixed(0)}%',
                label: 'Avg Score',
                icon: Icons.percent,
                color: _averageScore >= 80
                    ? AppTheme.success
                    : _averageScore >= 60
                    ? AppTheme.accent
                    : AppTheme.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bottom row
        Row(
          children: [
            Expanded(
              child: _statCard(
                value: '$_totalCoins',
                label: 'Coins Earned',
                icon: Icons.monetization_on,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                value: '$_perfectScores',
                label: 'Perfect Scores',
                icon: Icons.star,
                color: const Color(0xFFFFD700),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildScoreChart() {
    final spots = _scoreSpots;
    if (spots.isEmpty) return const SizedBox();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppTheme.border,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 25,
                getTitlesWidget: (value, _) => Text(
                  '${value.toInt()}%',
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) => Text(
                  'Q${value.toInt() + 1}',
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary),
                ),
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) =>
                    FlDotCirclePainter(
                      radius: 5,
                      color: AppTheme.primary,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectBreakdown() {
    final Map<String, List<Map<String, dynamic>>> bySubject = {};
    for (final r in _results) {
      final subject =
          r['quizzes']?['subject'] as String? ?? 'Unknown';
      bySubject.putIfAbsent(subject, () => []).add(r);
    }

    return Column(
      children: bySubject.entries.map((e) {
        final subject = e.key;
        final subResults = e.value;
        final correct = subResults.fold(
            0, (s, r) => s + (r['score'] as int? ?? 0));
        final total = subResults.fold(
            0, (s, r) => s + (r['total'] as int? ?? 0));
        final pct = total == 0 ? 0.0 : correct / total;
        final color = subject == 'Math'
            ? AppTheme.lessonsColor
            : AppTheme.quizzesColor;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(subject,
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      Text('${subResults.length} quizzes',
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12)),
                    ],
                  ),
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: pct >= 0.8
                            ? AppTheme.success
                            : pct >= 0.6
                            ? AppTheme.accent
                            : AppTheme.danger),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$correct correct out of $total questions',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuizHistory() {
    return Column(
      children: _results.map((r) {
        final score = r['score'] as int? ?? 0;
        final total = r['total'] as int? ?? 1;
        final coins = r['coins_earned'] as int? ?? 0;
        final title =
            r['quizzes']?['title'] as String? ?? 'Quiz';
        final subject =
            r['quizzes']?['subject'] as String? ?? '';
        final completedAt =
        DateTime.parse(r['completed_at'] as String);
        final pct = score / total;
        final isFirst = r['is_first_attempt'] as bool? ?? true;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              // Score circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (pct >= 0.8
                      ? AppTheme.success
                      : pct >= 0.6
                      ? AppTheme.accent
                      : AppTheme.danger)
                      .withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$score/$total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: pct >= 0.8
                          ? AppTheme.success
                          : pct >= 0.6
                          ? AppTheme.accent
                          : AppTheme.danger,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(subject,
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12)),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(completedAt),
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isFirst && coins > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on,
                            color: AppTheme.accent, size: 14),
                        const SizedBox(width: 2),
                        Text('+$coins',
                            style: const TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ],
                    ),
                  if (!isFirst)
                    const Text('Practice',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary)),
                  const SizedBox(height: 2),
                  // Star rating
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final stars = pct == 1.0 ? 3 : pct >= 0.6 ? 2 : pct >= 0.3 ? 1 : 0;
                      final filled = i < stars;
                      return Icon(
                        filled ? Icons.star : Icons.star_border,
                        color: AppTheme.accent,
                        size: 14,
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '$diff days ago';
  }
}