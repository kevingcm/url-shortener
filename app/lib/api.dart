// API client for the Shortly backend.
// All HTTP calls live here so the UI code stays clean.

import 'dart:convert';
import 'package:http/http.dart' as http;

const apiBaseUrl = 'https://url-shortener-mvzx.onrender.com';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ShortenResult {
  final String shortCode;
  final String shortUrl;
  final String longUrl;

  ShortenResult({
    required this.shortCode,
    required this.shortUrl,
    required this.longUrl,
  });

  factory ShortenResult.fromJson(Map<String, dynamic> json) => ShortenResult(
        shortCode: json['short_code'] as String,
        shortUrl: json['short_url'] as String,
        longUrl: json['long_url'] as String,
      );
}

class Stats {
  final String shortCode;
  final String longUrl;
  final String createdAt;
  final int totalClicks;
  final List<DayCount> clicksByDay;
  final List<ReferrerCount> topReferrers;

  Stats({
    required this.shortCode,
    required this.longUrl,
    required this.createdAt,
    required this.totalClicks,
    required this.clicksByDay,
    required this.topReferrers,
  });

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
        shortCode: json['short_code'] as String,
        longUrl: json['long_url'] as String,
        createdAt: json['created_at'].toString(),
        totalClicks: json['total_clicks'] as int,
        clicksByDay: (json['clicks_by_day'] as List)
            .map((e) => DayCount.fromJson(e as Map<String, dynamic>))
            .toList(),
        topReferrers: (json['top_referrers'] as List)
            .map((e) => ReferrerCount.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DayCount {
  final String day;
  final int count;
  DayCount({required this.day, required this.count});
  factory DayCount.fromJson(Map<String, dynamic> json) =>
      DayCount(day: json['day'] as String, count: json['count'] as int);
}

class ReferrerCount {
  final String referrer;
  final int count;
  ReferrerCount({required this.referrer, required this.count});
  factory ReferrerCount.fromJson(Map<String, dynamic> json) => ReferrerCount(
        referrer: json['referrer'] as String,
        count: json['count'] as int,
      );
}

Future<ShortenResult> shortenUrl(String url) async {
  final res = await http.post(
    Uri.parse('$apiBaseUrl/api/shorten'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'url': url}),
  );
  if (res.statusCode != 200) {
    throw ApiException(_parseError(res.body));
  }
  return ShortenResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
}

Future<Stats> fetchStats(String code) async {
  final res = await http.get(Uri.parse('$apiBaseUrl/api/stats/$code'));
  if (res.statusCode != 200) {
    throw ApiException(_parseError(res.body));
  }
  return Stats.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
}

String _parseError(String body) {
  try {
    final m = jsonDecode(body);
    if (m is Map && m['error'] != null) return m['error'].toString();
  } catch (_) {}
  return body.isEmpty ? 'Unknown error' : body;
}
