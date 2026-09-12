import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Backend URLs. Web (the public embed) hits the deployed Render backend; the
/// iOS simulator hits the local dev backend.
const String kAnchorRemoteUrl = 'https://anchor-qo9j.onrender.com';
const String kAnchorLocalUrl = 'http://localhost:3000';

/// Direct Supabase auth for the demo. The publishable key is client-safe by
/// design; the demo account is a throwaway shared login for judges.
const String kSupabaseUrl = 'https://kdpgslmbvyybulgashxz.supabase.co';
const String kSupabasePublishableKey = 'sb_publishable_wM7ORk1nTD_uztKRQItXGg_nRbKbiV2';
const String kDemoEmail = 'demo@anchor.app';
const String kDemoPassword = 'anchor-demo-2026';

/// Typed client for the Anchor API (see ANCHOR-BUILD-SPEC.md §7).
/// Singleton so the auth token is shared across screens. For the demo it
/// dev-logs in automatically; on the day this is replaced by real sign-in.
class AnchorApi {
  AnchorApi._();
  static final AnchorApi instance = AnchorApi._();
  factory AnchorApi() => instance;

  final String baseUrl = kIsWeb ? kAnchorRemoteUrl : kAnchorLocalUrl;
  String? _token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Auth headers for callers that need to hit the backend directly (realtime).
  Map<String, String> get authHeaders => _headers;

  /// Ensures we have a session by authenticating the demo account directly
  /// against Supabase (works in production; independent of the backend's /auth).
  Future<void> ensureAuth() async {
    if (_token != null) return;
    final res = await http.post(
      Uri.parse('$kSupabaseUrl/auth/v1/token?grant_type=password'),
      headers: {'apikey': kSupabasePublishableKey, 'Content-Type': 'application/json'},
      body: jsonEncode({'email': kDemoEmail, 'password': kDemoPassword}),
    );
    if (res.statusCode == 200) {
      _token = (jsonDecode(res.body) as Map<String, dynamic>)['access_token'] as String?;
    }
  }

  /// GET /weeks/current/commitments — the Load.
  Future<List<Commitment>> currentCommitments() async {
    await ensureAuth();
    final res = await http.get(Uri.parse('$baseUrl/weeks/current/commitments'), headers: _headers);
    if (res.statusCode != 200) return const [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data['commitments'] as List? ?? const []);
    return items.map((c) => Commitment.fromJson(c as Map<String, dynamic>)).toList();
  }

  /// GET the current load envelope (cap + loaded), for the gauge.
  Future<Load> currentLoad() async {
    await ensureAuth();
    final res = await http.get(Uri.parse('$baseUrl/weeks/current/commitments'), headers: _headers);
    if (res.statusCode != 200) return const Load(cap: 4, loaded: 0, weekId: null);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Load(
      cap: (data['cap'] as num?)?.toInt() ?? 4,
      loaded: (data['loaded'] as num?)?.toInt() ?? 0,
      weekId: (data['week'] as Map<String, dynamic>?)?['id'] as String?,
    );
  }

  /// POST /judge — the "no". Real AI decision, recorded server-side.
  Future<Judgment> judge(String request) async {
    await ensureAuth();
    final res = await http.post(
      Uri.parse('$baseUrl/judge'),
      headers: _headers,
      body: jsonEncode({'source': 'voice', 'request': request}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Judgment(
      verdict: data['verdict'] as String? ?? 'declined',
      spoken: data['spoken'] as String? ?? '',
      weighedAgainst: ((data['weighed_against'] as List?) ?? const []).map((e) => e.toString()).toList(),
    );
  }

  /// POST /commitments — put something on the record (after Anchor allows it).
  Future<bool> addCommitment(String title) async {
    await ensureAuth();
    final res = await http.post(
      Uri.parse('$baseUrl/commitments'),
      headers: _headers,
      body: jsonEncode({'title': title, 'kind': 'oneoff', 'metric': 'boolean'}),
    );
    return res.statusCode == 201;
  }

  /// GET /commitments/:id — one commitment's detail.
  Future<Commitment?> commitment(String id) async {
    await ensureAuth();
    final res = await http.get(Uri.parse('$baseUrl/commitments/$id'), headers: _headers);
    if (res.statusCode != 200) return null;
    final d = jsonDecode(res.body) as Map<String, dynamic>;
    final c = (d['commitment'] as Map<String, dynamic>?) ?? d;
    return Commitment.fromJson(c);
  }

  /// PUT /commitments/:id/checkin — log progress or mark done/miss.
  Future<bool> checkin(String id, {required String kind, double? value}) async {
    await ensureAuth();
    final res = await http.put(
      Uri.parse('$baseUrl/commitments/$id/checkin'),
      headers: _headers,
      body: jsonEncode({'kind': kind, if (value != null) 'value': value}),
    );
    return res.statusCode < 300;
  }

  /// DELETE /commitments/:id — drop a commitment.
  Future<bool> deleteCommitment(String id) async {
    await ensureAuth();
    final res = await http.delete(Uri.parse('$baseUrl/commitments/$id'), headers: _headers);
    return res.statusCode < 300;
  }

  /// POST /companion/chat — talk to Anchor. Returns the reply text.
  Future<String> chat(String message) async {
    await ensureAuth();
    final res = await http.post(
      Uri.parse('$baseUrl/companion/chat'),
      headers: _headers,
      body: jsonEncode({'message': message}),
    );
    if (res.statusCode >= 400) return '';
    return (jsonDecode(res.body) as Map<String, dynamic>)['reply'] as String? ?? '';
  }

  /// POST /messages — persist a turn (used to save voice-call turns to the chat).
  Future<void> postMessage(String role, String content) async {
    if (content.trim().isEmpty) return;
    await ensureAuth();
    await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: _headers,
      body: jsonEncode({'role': role, 'content': content, 'turn_kind': 'chat'}),
    );
  }

  /// POST /companion/reflect — debounced: update durable memory from the
  /// recent conversation. Fire-and-forget on session boundaries.
  Future<void> reflect() async {
    await ensureAuth();
    try {
      await http.post(Uri.parse('$baseUrl/companion/reflect'), headers: _headers);
    } catch (_) {}
  }

  /// GET /messages — the Talk transcript.
  Future<List<Turn>> conversation() async {
    await ensureAuth();
    final res = await http.get(Uri.parse('$baseUrl/messages'), headers: _headers);
    if (res.statusCode != 200) return const [];
    final msgs = (jsonDecode(res.body) as Map<String, dynamic>)['messages'] as List? ?? const [];
    return msgs.map((m) => Turn(role: (m['role'] as String) == 'anchor' ? 'anchor' : 'user', text: m['content'] as String? ?? '')).toList();
  }

  /// GET /weeks/:id/review — the weekly standing.
  Future<WeeklyStanding?> standing() async {
    await ensureAuth();
    final load = await currentLoad();
    if (load.weekId == null) return null;
    final res = await http.get(Uri.parse('$baseUrl/weeks/${load.weekId}/review'), headers: _headers);
    if (res.statusCode != 200) return null;
    final d = jsonDecode(res.body) as Map<String, dynamic>;
    final items = ((d['commitments'] as List?) ?? const []).map((c) {
      final m = c as Map<String, dynamic>;
      final status = m['status'] as String? ?? '';
      final cur = (m['current_value'] as num?)?.toDouble() ?? 0;
      final tgt = (m['target_value'] as num?)?.toDouble() ?? 0;
      final kept = status == 'done' || (tgt > 0 && cur >= tgt);
      return StandingItem(
        title: m['title'] as String? ?? '',
        outcome: kept ? 'kept' : (status == 'carried' ? 'missed' : 'missed'),
        note: status == 'carried' ? 'forgiven · carried' : null,
      );
    }).toList();
    return WeeklyStanding(
      keptCount: (d['kept_count'] as num?)?.toInt() ?? 0,
      totalCount: (d['total_count'] as num?)?.toInt() ?? items.length,
      anchorMessage: d['anchor_message'] as String? ?? '',
      items: items,
    );
  }
}

class Load {
  final int cap;
  final int loaded;
  final String? weekId;
  const Load({required this.cap, required this.loaded, required this.weekId});
}

class Commitment {
  final String id;
  final int position;
  final String title;
  final String status; // on_record | due | done | carried | dropped
  final String metric; // boolean | count | amount
  final double currentValue;
  final double targetValue;
  final String? unit;
  final String? period; // week | month
  final String? kind; // oneoff | recurring | budget
  const Commitment({
    required this.id,
    required this.position,
    required this.title,
    required this.status,
    this.metric = 'boolean',
    this.currentValue = 0,
    this.targetValue = 0,
    this.unit,
    this.period,
    this.kind,
  });

  /// "1 of 3" for counts; null for simple boolean commitments.
  String? get progress =>
      (metric == 'count' && targetValue > 1) ? '${currentValue.toInt()} of ${targetValue.toInt()}' : null;

  bool get isDone => status == 'done' || (targetValue > 0 && currentValue >= targetValue);

  factory Commitment.fromJson(Map<String, dynamic> j) => Commitment(
        id: j['id'] as String? ?? '',
        position: (j['position'] as num?)?.toInt() ?? 0,
        title: j['title'] as String? ?? '',
        status: j['status'] as String? ?? 'on_record',
        metric: j['metric'] as String? ?? 'boolean',
        currentValue: (j['current_value'] as num?)?.toDouble() ?? 0,
        targetValue: (j['target_value'] as num?)?.toDouble() ?? 0,
        unit: j['unit'] as String?,
        period: j['period'] as String?,
        kind: j['kind'] as String?,
      );
}

class Judgment {
  final String verdict; // declined | allowed | swapped | nudge | stay_silent
  final String spoken;
  final List<String> weighedAgainst;
  const Judgment({required this.verdict, required this.spoken, required this.weighedAgainst});
}

class Turn {
  final String role; // user | anchor
  final String text;
  const Turn({required this.role, required this.text});
}

class WeeklyStanding {
  final int keptCount;
  final int totalCount;
  final String anchorMessage;
  final List<StandingItem> items;
  const WeeklyStanding({required this.keptCount, required this.totalCount, required this.anchorMessage, required this.items});
}

class StandingItem {
  final String title;
  final String outcome; // kept | missed | forgiven
  final String? note;
  const StandingItem({required this.title, required this.outcome, this.note});
}
