import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
import 'history.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _history = HistoryService();
  ShortenResult? _result;
  String? _error;
  bool _loading = false;
  List<HistoryEntry> _historyEntries = const [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final entries = await _history.load();
    if (!mounted) return;
    setState(() => _historyEntries = entries);
  }

  Future<void> _shorten() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final r = await shortenUrl(url);
      final updated = await _history.add(HistoryEntry(
        shortCode: r.shortCode,
        shortUrl: r.shortUrl,
        longUrl: r.longUrl,
        createdAt: DateTime.now(),
      ));
      if (mounted) {
        setState(() {
          _result = r;
          _historyEntries = updated;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Network error — check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clearHistory() async {
    await _history.clear();
    if (!mounted) return;
    setState(() => _historyEntries = const []);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shortly')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Paste a long URL, get a short one.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _shorten(),
                  decoration: const InputDecoration(
                    hintText: 'https://example.com/some/very/long/path',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _loading ? null : _shorten,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Shorten'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _ErrorBox(message: _error!),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 20),
                  _ResultCard(result: _result!),
                ],
                if (_historyEntries.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recent',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      TextButton(
                        onPressed: _clearHistory,
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ..._historyEntries.map(
                    (e) => _HistoryTile(entry: e),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;
  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        title: Text(
          entry.shortUrl,
          style: TextStyle(
            color: scheme.primary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          entry.longUrl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.bar_chart, size: 20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StatsScreen(shortCode: entry.shortCode),
            ),
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final ShortenResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your short URL:',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () =>
                  launchUrl(Uri.parse(result.shortUrl), mode: LaunchMode.externalApplication),
              child: Text(
                result.shortUrl,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: result.shortUrl));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.bar_chart, size: 16),
                  label: const Text('View stats'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StatsScreen(shortCode: result.shortCode),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade800)),
    );
  }
}
