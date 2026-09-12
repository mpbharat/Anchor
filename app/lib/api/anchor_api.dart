import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Backend URLs. Web (the public embed) hits the deployed Render backend; the
/// iOS simulator hits the local dev backend.
const String kAnchorRemoteUrl = 'https://anchor-qo9j.onrender.com';
const String kAnchorLocalUrl = 'http://localhost:3000';

/// Supabase project. The publishable key is client-safe by design.
const String kSupabaseUrl = 'https://kdpgslmbvyybulgashxz.supabase.co';
const String kSupabasePublishableKey = 'sb_publishable_wM7ORk1nTD_uztKRQItXGg_nRbKbiV2';

/// Typed client for the Anchor API (see ANCHOR-BUILD-SPEC.md §7).
/// Singleton so every screen talks to the same signed-in person.
class AnchorApi {
  AnchorApi._();
  static final AnchorApi instance = AnchorApi._();
  factory AnchorApi() => instance;

  final String baseUrl = kIsWeb ? kAnchorRemoteUrl : kAnchorLocalUrl;

  GoTrueClient get _auth => Supabase.instance.client.auth;

  /// The signed-in person's access token. Read straight from the SDK rather
  /// than cached here: the SDK persists the session across restarts and
  /// refreshes it before expiry, and nothing can go stale or survive a sign-out.
  String? get _accessToken => _auth.currentSession?.accessToken;

  bool get isSignedIn => _accessToken != null;
  String? get currentEmail => _auth.currentUser?.email;
  String? get currentUserId => _auth.currentUser?.id;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  /// Auth headers for callers that need to hit the backend directly (realtime).
  Map<String, String> get authHeaders => _headers;

  /// Kept as the seam every call site already goes through. The SDK restores
  /// and refreshes the session itself, so there is nothing to do here now.
  Future<void> ensureAuth() async {}

  Future<AuthResponse> signIn({required String email, required String password}) =>
      _auth.signInWithPassword(email: email.trim(), password: password);

  Future<AuthResponse> signUp({required String email, required String password}) =>
      _auth.signUp(email: email.trim(), password: password);

  Future<void> signOut() => _auth.signOut();

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

  /// GET /commitments/:id/checkins — the progress log for a commitment.
  Future<List<CheckIn>> checkins(String id) async {
    await ensureAuth();
    final res = await http.get(Uri.parse('$baseUrl/commitments/$id/checkins'), headers: _headers);
    if (res.statusCode != 200) return const [];
    final list = (jsonDecode(res.body) as Map<String, dynamic>)['checkins'] as List? ?? const [];
    return list.map((c) => CheckIn.fromJson(c as Map<String, dynamic>)).toList();
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

  // ---- Import (screen 7) ------------------------------------------------

  /// POST /users/me/patterns/extract — send the pasted reply; the backend
  /// structures it into user_patterns (via OpenAI) and stores it.
  Future<ImportedProfile?> extractPatterns({
    required String source,
    required String rawText,
  }) async {
    await ensureAuth();
    final res = await http.post(
      Uri.parse('$baseUrl/users/me/patterns/extract'),
      headers: _headers,
      body: jsonEncode({'source': source, 'raw_text': rawText}),
    );
    if (res.statusCode >= 300) return null;
    final p = (jsonDecode(res.body) as Map<String, dynamic>)['patterns'] as Map<String, dynamic>?;
    return p == null ? null : ImportedProfile.fromJson(p);
  }

  /// GET /users/me/patterns — what Anchor already learned (null if never imported).
  Future<ImportedProfile?> patterns() async {
    await ensureAuth();
    final res = await http.get(Uri.parse('$baseUrl/users/me/patterns'), headers: _headers);
    if (res.statusCode != 200) return null;
    final p = (jsonDecode(res.body) as Map<String, dynamic>)['patterns'] as Map<String, dynamic>?;
    return p == null ? null : ImportedProfile.fromJson(p);
  }

  /// DELETE /users/me/patterns — "stay fresh": start with a blank slate.
  Future<bool> clearPatterns() async {
    await ensureAuth();
    final res = await http.delete(Uri.parse('$baseUrl/users/me/patterns'), headers: _headers);
    return res.statusCode < 300;
  }

  // ---- Connect (screen 8) -----------------------------------------------

  /// GET /integrations — which providers are connected.
  Future<Map<String, String>> integrations() async {
    await ensureAuth();
    final res = await http.get(Uri.parse('$baseUrl/integrations'), headers: _headers);
    if (res.statusCode != 200) return {};
    final list = (jsonDecode(res.body) as Map<String, dynamic>)['integrations'] as List? ?? const [];
    return {
      for (final i in list)
        (i as Map<String, dynamic>)['provider'] as String: i['status'] as String? ?? 'revoked',
    };
  }

  /// GET /integrations/google/start — the Google consent URL to open in the
  /// browser. The backend holds the client secret and does the code exchange,
  /// so the app never touches a Google token.
  /// Returns null when Google is not configured server-side.
  Future<String?> googleAuthUrl() async {
    await ensureAuth();
    final res = await http.get(
      Uri.parse('$baseUrl/integrations/google/start'),
      headers: _headers,
    );
    if (res.statusCode != 200) return null;
    return (jsonDecode(res.body) as Map<String, dynamic>)['url'] as String?;
  }

  /// PUT /integrations/status — flip a provider connected/revoked.
  /// Connecting Google goes through real OAuth (see [googleAuthUrl]); this is
  /// for revoking, and for 'notifications', which is device-local and has no
  /// OAuth of its own.
  Future<bool> setIntegration(String provider, {required bool connected}) async {
    await ensureAuth();
    final res = await http.put(
      Uri.parse('$baseUrl/integrations/status'),
      headers: _headers,
      body: jsonEncode({'provider': provider, 'status': connected ? 'connected' : 'revoked'}),
    );
    return res.statusCode < 300;
  }
}

/// The structured profile Anchor extracted from a paste (user_patterns).
class ImportedProfile {
  const ImportedProfile({
    required this.pitfalls,
    required this.currentProjects,
    required this.priorities,
    required this.habits,
    this.workingStyle,
    this.baselineLoad,
    this.source,
  });

  final List<String> pitfalls;
  final List<String> currentProjects;
  final List<String> priorities;
  final List<String> habits;
  final String? workingStyle;
  final String? baselineLoad;
  final String? source;

  static List<String> _strings(dynamic v) =>
      (v is List) ? v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList() : const [];

  factory ImportedProfile.fromJson(Map<String, dynamic> j) => ImportedProfile(
        pitfalls: _strings(j['pitfalls']),
        currentProjects: _strings(j['current_projects']),
        priorities: _strings(j['priorities']),
        habits: _strings(j['habits']),
        workingStyle: j['working_style'] as String?,
        baselineLoad: j['baseline_load'] as String?,
        source: j['source'] as String?,
      );

  /// True when the extraction actually found something worth showing.
  bool get hasContent =>
      pitfalls.isNotEmpty ||
      currentProjects.isNotEmpty ||
      priorities.isNotEmpty ||
      habits.isNotEmpty ||
      (workingStyle?.isNotEmpty ?? false) ||
      (baselineLoad?.isNotEmpty ?? false);
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

class CheckIn {
  final String kind; // progress | done | miss
  final double? value;
  final String? note;
  final DateTime? at;
  const CheckIn({required this.kind, this.value, this.note, this.at});

  factory CheckIn.fromJson(Map<String, dynamic> j) => CheckIn(
        kind: j['kind'] as String? ?? 'progress',
        value: (j['value'] as num?)?.toDouble(),
        note: j['note'] as String?,
        at: DateTime.tryParse(j['occurred_at'] as String? ?? '')?.toLocal(),
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
