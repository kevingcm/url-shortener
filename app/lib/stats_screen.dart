import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';

class StatsScreen extends StatefulWidget {
  final String shortCode;
  const StatsScreen({super.key, required this.shortCode});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Stats? _stats;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Fetches fresh stats. Keeps the previous _stats in place during refresh
  // so the UI doesn't flash to empty while waiting.
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await fetchStats(widget.shortCode);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final refreshingInAppBar = _loading && _stats != null;
    return Scaffold(
      appBar: AppBar(
        title: Text('/${widget.shortCode}'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: refreshingInAppBar
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // Initial load: full-screen spinner (no data to show yet).
    if (_loading && _stats == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // First-load error: show error inside a scrollable so pull-to-refresh
    // still works (RefreshIndicator needs a scrollable child).
    if (_stats == null && _error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
        children: [
          Text(
            'Failed to load stats:\n$_error\n\nPull down to try again.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return _StatsBody(stats: _stats!);
  }
}

class _StatsBody extends StatelessWidget {
  final Stats stats;
  const _StatsBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      // AlwaysScrollable lets RefreshIndicator trigger even if the content
      // fits on screen (without this, pull-to-refresh only works when you
      // already have enough clicks to make the view scrollable).
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UrlLink(label: 'Original', url: stats.longUrl),
              const SizedBox(height: 4),
              _UrlLink(label: 'Short', url: stats.shortUrl),
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

class _UrlLink extends StatelessWidget {
  final String label;
  final String url;
  const _UrlLink({required this.label, required this.url});

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      onLongPress: () => _copy(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 70,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(
                url,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
