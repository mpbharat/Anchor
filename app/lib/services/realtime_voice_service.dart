import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import '../api/anchor_api.dart';

/// Live duplex voice with Anchor via OpenAI Realtime over WebRTC.
/// The backend mints a short-lived key (seeded with the persona + load); the
/// app streams mic audio and plays Anchor's audio back in real time.
class RealtimeVoice {
  final _api = AnchorApi();
  RTCPeerConnection? _pc;
  MediaStream? _local;
  RTCDataChannel? _dc;

  void Function(String state)? onState; // connecting | live | ended | error
  // Item-ordered transcript so turns render in true conversation order even
  // though user transcription (whisper) resolves after Anchor starts replying.
  void Function(String id, String role)? onItem; // a conversation item was created
  void Function(String id, String text, bool append)? onTranscript; // text for an item
  void Function(String id, String role, String text)? onItemDone; // item finalised (persist)

  bool _muted = false;
  bool get isMuted => _muted;

  void setMuted(bool m) {
    _muted = m;
    for (final t in _local?.getAudioTracks() ?? const []) {
      t.enabled = !m;
    }
  }

  Future<void> connect() async {
    try {
      onState?.call('connecting');
      await _api.ensureAuth();

      // 1. ephemeral key from our backend (seeded with persona + load)
      final sres = await http.post(
        Uri.parse('${_api.baseUrl}/realtime/session'),
        headers: _api.authHeaders,
      );
      if (sres.statusCode >= 400) {
        onState?.call('error');
        return;
      }
      final s = jsonDecode(sres.body) as Map<String, dynamic>;
      final ek = s['ephemeral_key'] as String;
      final model = s['model'] as String? ?? 'gpt-realtime';

      // 2. peer connection
      _pc = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'}
        ],
      });
      _pc!.onConnectionState = (st) {
        if (st == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          onState?.call('live');
        }
        if (st == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            st == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          onState?.call('ended');
        }
      };
      // remote audio plays automatically once the track arrives.
      _pc!.onTrack = (_) {};

      // 3. mic
      _local = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
      for (final t in _local!.getTracks()) {
        await _pc!.addTrack(t, _local!);
      }

      // 4. events channel (Anchor's live transcript)
      _dc = await _pc!.createDataChannel('oai-events', RTCDataChannelInit());
      _dc!.onMessage = (msg) => _onEvent(msg.text);

      // 5. offer -> OpenAI -> answer
      final offer = await _pc!.createOffer({});
      await _pc!.setLocalDescription(offer);

      final resp = await http.post(
        Uri.parse('https://api.openai.com/v1/realtime/calls?model=$model'),
        headers: {'Authorization': 'Bearer $ek', 'Content-Type': 'application/sdp'},
        body: offer.sdp,
      );
      if (resp.statusCode >= 400) {
        onState?.call('error');
        return;
      }
      await _pc!.setRemoteDescription(RTCSessionDescription(resp.body, 'answer'));
      onState?.call('live');
    } catch (_) {
      onState?.call('error');
    }
  }

  final Map<String, String> _roleById = {};
  final Map<String, String> _textById = {};

  void _onEvent(String raw) {
    try {
      final e = jsonDecode(raw) as Map<String, dynamic>;
      final type = e['type'] as String? ?? '';
      switch (type) {
        case 'conversation.item.created':
          final item = e['item'] as Map<String, dynamic>?;
          final id = item?['id'] as String?;
          final role = (item?['role'] as String?) == 'user' ? 'user' : 'anchor';
          if (id != null) {
            _roleById[id] = role;
            _textById[id] ??= '';
            onItem?.call(id, role); // reserves the slot in order
          }
          break;
        case 'response.output_audio_transcript.delta':
        case 'response.audio_transcript.delta':
          _apply(e['item_id'] as String?, 'anchor', e['delta'] as String? ?? '', append: true);
          break;
        case 'response.output_audio_transcript.done':
        case 'response.audio_transcript.done':
          _done(e['item_id'] as String?, 'anchor', full: e['transcript'] as String?);
          break;
        case 'conversation.item.input_audio_transcription.completed':
          _apply(e['item_id'] as String?, 'user', (e['transcript'] as String? ?? '').trim(), append: false);
          _done(e['item_id'] as String?, 'user');
          break;
      }
    } catch (_) {}
  }

  void _apply(String? id, String role, String text, {required bool append}) {
    if (id == null) return;
    _roleById[id] ??= role;
    if (onItem != null && !_textById.containsKey(id)) onItem!(id, _roleById[id]!);
    _textById[id] = append ? (_textById[id] ?? '') + text : text;
    onTranscript?.call(id, _textById[id]!, false);
  }

  void _done(String? id, String role, {String? full}) {
    if (id == null) return;
    if (full != null && full.isNotEmpty) {
      _textById[id] = full;
      onTranscript?.call(id, full, false);
    }
    final t = (_textById[id] ?? '').trim();
    if (t.isNotEmpty) onItemDone?.call(id, _roleById[id] ?? role, t);
  }

  Future<void> disconnect() async {
    try {
      await _dc?.close();
      for (final t in _local?.getTracks() ?? const []) {
        await t.stop();
      }
      await _local?.dispose();
      await _pc?.close();
    } catch (_) {}
    _pc = null;
    _local = null;
    _dc = null;
    onState?.call('ended');
  }
}
