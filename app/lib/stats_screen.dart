import 'package:flutter/material.dart';
import 'api.dart';

class StatsScreen extends StatefulWidget {
  final String shortCode;
  const StatsScreen({super.key, required this.shortCode});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<Stats> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchStats(widget.shortCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('/${widget.shortCode}')),
      body: FutureBuilder<Stats>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load stats: ${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return _StatsBody(stats: snap.data!);
        },
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  final Stats stats;
  const _StatsBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('→ ${stats.longUrl}',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${stats.totalClicks}',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TOTAL CLICKS',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text('Clicks by day (last 30)',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (stats.clicksByDay.isEmpty)
                const _EmptyRow()
              else
                _Rows(
                  rows: stats.clicksByDay
                      .map((d) => (d.day, d.count.toString()))
                      .toList(),
                ),
              const SizedBox(height: 28),
              Text('Top referrers',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (stats.topReferrers.isEmpty)
                const _EmptyRow()
              else
                _Rows(
                  rows: stats.topReferrers
                      .map((r) => (r.referrer, r.count.toString()))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rows extends StatelessWidget {
  final List<(String, String)> rows;
  const _Rows({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows.map((row) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black12)),
          ),
          child: Row(
            children: [
              Expanded(child: Text(row.$1, overflow: TextOverflow.ellipsis)),
              Text(row.$2, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Text('No clicks yet', style: TextStyle(color: Colors.grey)),
    );
  }
}
