import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Base URL of the Anchor backend.
/// iOS simulator reaches the Mac's localhost directly. For the deployed demo,
/// swap this for the Render URL (e.g. https://anchor-backend.onrender.com).
const String kAnchorBaseUrl = 'http://localhost:3000';

/// Typed client for the Anchor API (see ANCHOR-BUILD-SPEC.md §7).
/// Singleton so the auth token is shared across screens. For the demo it
/// dev-logs in automatically; on the day this is replaced by real sign-in.
class AnchorApi {
  AnchorApi._();
  static final AnchorApi instance = AnchorApi._();
  factory AnchorApi() => instance;

  final String baseUrl = kAnchorBaseUrl;
  String? _token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Ensures we have a session. Demo: dev-login (pre-confirmed user).
  Future<void> ensureAuth() async {
    if (_token != null) return;
    final res = await http.post(
      Uri.parse('$baseUrl/auth/dev-login'),
      headers: {'Content-Type': 'application/json'},
      body: '{}',
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      _token = body['access_token'] as String? ??
          (body['session'] as Map<String, dynamic>?)?['access_token'] as String?;
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
  final int position;
  final String title;
  final String status;
  final String? progress;
  const Commitment({required this.position, required this.title, required this.status, this.progress});

  factory Commitment.fromJson(Map<String, dynamic> j) {
    final cur = (j['current_value'] as num?)?.toDouble() ?? 0;
    final tgt = (j['target_value'] as num?)?.toDouble() ?? 0;
    final metric = j['metric'] as String?;
    String? progress;
    if (metric == 'count' && tgt > 1) {
      progress = '${cur.toInt()} of ${tgt.toInt()}';
    }
    return Commitment(
      position: (j['position'] as num?)?.toInt() ?? 0,
      title: j['title'] as String? ?? '',
      status: j['status'] as String? ?? 'on_record',
      progress: progress,
    );
  }
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
