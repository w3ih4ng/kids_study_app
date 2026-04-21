import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../models/child_model.dart';

class CoinsHistoryScreen extends StatefulWidget {
  final ChildModel child;
  const CoinsHistoryScreen({super.key, required this.child});

  @override
  State<CoinsHistoryScreen> createState() => _CoinsHistoryScreenState();
}

class _CoinsHistoryScreenState extends State<CoinsHistoryScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Supabase.instance.client
        .from('coin_transactions')
        .select()
        .eq('child_id', widget.child.id)
        .order('created_at', ascending: false);

    if (mounted) {
      setState(() {
        _history = List<Map<String, dynamic>>.from(results);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.child.nickname}\'s Coins'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            // Total coins card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accent, Color(0xFFE67E00)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on,
                      color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Coins',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      Text(
                        '${widget.child.coins}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // History list
            Expanded(
              child: _history.isEmpty
                  ? Center(
                child: Text(
                  'No coins history yet.',
                  style: TextStyle(
                      color:
                      cs.onSurface.withValues(alpha: 0.6)),
                ),
              )
                  : ListView.builder(
                physics:
                const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
                itemCount: _history.length,
                itemBuilder: (_, i) {
                  final r = _history[i];
                  final amount = r['amount'] as int? ?? 0;
                  final type = r['type'] as String? ?? '';
                  final description = r['description'] as String? ?? '';
                  final date = DateTime.parse(r['created_at'] as String);
                  final isEarned = amount > 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outline),
                    ),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isEarned
                                ? AppTheme.success.withValues(alpha: 0.15)
                                : AppTheme.danger.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              type == 'pet_purchase'
                                  ? Icons.pets
                                  : Icons.quiz,
                              color: isEarned
                                  ? AppTheme.success
                                  : AppTheme.danger,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Description + date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(description,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(date),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ),

                        // Amount
                        Text(
                          isEarned ? '+$amount' : '$amount',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isEarned ? AppTheme.success : AppTheme.danger,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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