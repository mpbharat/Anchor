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

  // Web needs the remote audio attached to a media element to play; a renderer
  // does that. On native, audio auto-routes, but this is harmless there too.
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  bool _rendererReady = false;
  void Function()? onAudioReady;

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
      if (!_rendererReady) {
        await remoteRenderer.initialize();
        _rendererReady = true;
      }

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
      // attach the remote audio so it plays (essential on web).
      _pc!.onTrack = (e) {
        if (e.track.kind == 'audio' && e.streams.isNotEmpty) {
          remoteRenderer.srcObject = e.streams.first;
          onAudioReady?.call();
        }
      };

      // 3. mic
      // Explicit echo cancellation stops Anchor's own voice (from the speakers)
      // being picked up by the mic and treated as the user talking, which
      // garbles the turn-taking during a speaker-out demo.
      _local = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });
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
        // The user's whisper transcript resolves AFTER Anchor starts replying,
        // so we must reserve the user's slot the moment their speech is
        // committed — before any Anchor item is created — or the bubble lands
        // out of order. This event fires early and carries the user item_id.
        case 'input_audio_buffer.committed':
          final uid = e['item_id'] as String?;
          if (uid != null) {
            _roleById[uid] = 'user';
            _textById[uid] ??= '';
            onItem?.call(uid, 'user'); // reserves the user slot in true order
          }
          break;
        case 'conversation.item.created':
        case 'conversation.item.added': // GA gpt-realtime renamed this event
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
      remoteRenderer.srcObject = null;
      if (_rendererReady) {
        await remoteRenderer.dispose();
        _rendererReady = false;
      }
    } catch (_) {}
    _pc = null;
    _local = null;
    _dc = null;
    onState?.call('ended');
  }
}
