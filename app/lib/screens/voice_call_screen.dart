import 'package:flutter/material.dart';
import '../theme/anchor_theme.dart';
import '../api/anchor_api.dart';
import '../services/realtime_voice_service.dart';

/// Live voice call with Anchor (duplex). Shows the running conversation as it
/// happens, like a call transcript, with mute and end. Modelled on Claude voice.
class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});
  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VTurn {
  final String role; // user | anchor
  String text;
  _VTurn(this.role, this.text);
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final _rt = RealtimeVoice();
  final _api = AnchorApi();
  final _scroll = ScrollController();
  final List<String> _order = [];
  final Map<String, _VTurn> _byId = {};
  String _state = 'connecting';
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _rt
      ..onState = (s) {
        if (mounted) setState(() => _state = s);
      }
      ..onItem = (id, role) {
        if (!mounted) return;
        setState(() {
          if (!_byId.containsKey(id)) {
            _byId[id] = _VTurn(role, '');
            _order.add(id);
          }
        });
        _scrollDown();
      }
      ..onTranscript = (id, text, _) {
        if (!mounted) return;
        setState(() {
          final t = _byId[id];
          if (t != null) {
            t.text = text;
          } else {
            _byId[id] = _VTurn('anchor', text);
            _order.add(id);
          }
        });
        _scrollDown();
      }
      ..onItemDone = (id, role, text) {
        // persist so Talk shows the full voice conversation afterwards
        _api.postMessage(role == 'anchor' ? 'anchor' : 'user', text);
      };
    _rt.connect();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _end() async {
    await _rt.disconnect();
    if (mounted) Navigator.of(context).maybePop();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _rt.setMuted(_muted);
  }

  @override
  void dispose() {
    _rt.disconnect();
    _scroll.dispose();
    super.dispose();
  }

  String get _statusText {
    switch (_state) {
      case 'live':
        return _muted ? 'Muted' : 'Listening';
      case 'error':
        return "Couldn't connect";
      case 'ended':
        return 'Ended';
      default:
        return 'Connecting…';
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _order.map((id) => _byId[id]!).where((t) => t.text.trim().isNotEmpty).toList();
    return Scaffold(
      backgroundColor: AnchorColors.scr,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TALK TO ANCHOR',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800, color: AnchorColors.dim, letterSpacing: 1)),
                  Row(children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: _state == 'live' ? AnchorColors.ok : AnchorColors.dim, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(_statusText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AnchorColors.ink)),
                  ]),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Text(
                          _state == 'error' ? "Couldn't start voice.\nCheck your connection and try again." : 'Say hello to Anchor…',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AnchorColors.dim, height: 1.4),
                        ),
                      )
                    : ListView.separated(
                        controller: _scroll,
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _Bubble(visible[i]),
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _toggleMute,
                    child: Container(
                      width: 64, height: 64, alignment: Alignment.center,
                      decoration: AnchorBox.surface(bg: _muted ? AnchorColors.alert : AnchorColors.card, radius: 32, shadow: 4),
                      child: Icon(_muted ? Icons.mic_off : Icons.mic, color: _muted ? Colors.white : AnchorColors.ink, size: 28),
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: _end,
                    child: Container(
                      width: 64, height: 64, alignment: Alignment.center,
                      decoration: AnchorBox.surface(bg: AnchorColors.ink, radius: 32, shadow: 4),
                      child: const Icon(Icons.close, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.turn);
  final _VTurn turn;
  @override
  Widget build(BuildContext context) {
    final isAnchor = turn.role == 'anchor';
    return Align(
      alignment: isAnchor ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(12),
        decoration: AnchorBox.surface(bg: isAnchor ? AnchorColors.card : AnchorColors.accent, shadow: 3),
        child: Text(
          turn.text,
          style: TextStyle(fontSize: 14, height: 1.35, fontWeight: FontWeight.w600, color: isAnchor ? AnchorColors.ink : Colors.white),
        ),
      ),
    );
  }
}
