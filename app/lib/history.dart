// Local-only history of URLs shortened on this device.
//
// Storage backend is picked at compile time via conditional import:
//   - web    → dart:html localStorage           (kv_web.dart)
//   - mobile → shared_preferences (SharedPrefs) (kv_io.dart)
//
// There's no server-side history (no login/accounts), so each device
// has its own list.

import 'dart:convert';

import 'kv_web.dart' if (dart.library.io) 'kv_io.dart';

class HistoryEntry {
  final String shortCode;
  final String shortUrl;
  final String longUrl;
  final DateTime createdAt;

  HistoryEntry({
    required this.shortCode,
    required this.shortUrl,
    required this.longUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'short_code': shortCode,
        'short_url': shortUrl,
        'long_url': longUrl,
        'created_at': createdAt.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        shortCode: json['short_code'] as String,
        shortUrl: json['short_url'] as String,
        longUrl: json['long_url'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class HistoryService {
  static const _key = 'history_v1';
  static const _maxEntries = 20;

  Future<List<HistoryEntry>> load() async {
    final raw = await kvGet(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupted payload; wipe it and start fresh.
      await kvRemove(_key);
      return const [];
    }
  }

  /// Prepends [entry] and returns the new list (capped at [_maxEntries]).
  Future<List<HistoryEntry>> add(HistoryEntry entry) async {
    final current = await load();
    final updated = [entry, ...current].take(_maxEntries).toList();
    await kvSet(_key, jsonEncode(updated.map((e) => e.toJson()).toList()));
    return updated;
  }

  Future<void> clear() async {
    await kvRemove(_key);
  }
}
