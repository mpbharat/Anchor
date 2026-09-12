import 'package:flutter/material.dart';
import '../theme/anchor_theme.dart';
import '../services/realtime_voice_service.dart';

/// Live voice call with Anchor (duplex, hands-free). Talk and it talks back.
class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});
  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final _rt = RealtimeVoice();
  String _state = 'connecting';
  String _caption = '';

  @override
  void initState() {
    super.initState();
    _rt
      ..onState = (s) {
        if (mounted) setState(() => _state = s);
      }
      ..onCaption = (t) {
        if (mounted) setState(() => _caption = t);
      };
    _rt.connect();
  }

  Future<void> _end() async {
    await _rt.disconnect();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _rt.disconnect();
    super.dispose();
  }

  String get _statusText {
    switch (_state) {
      case 'live':
        return 'Listening';
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
    final live = _state == 'live';
    return Scaffold(
      backgroundColor: AnchorColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('TALK TO ANCHOR',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 1)),
              const Spacer(),
              Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: live ? AnchorColors.accent : AnchorColors.dim,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: AnchorColors.accent.withValues(alpha: live ? 0.5 : 0), blurRadius: 40, spreadRadius: 8)],
                  ),
                  child: const Icon(Icons.graphic_eq, color: Colors.white, size: 64),
                ),
              ),
              const SizedBox(height: 24),
              Text(_statusText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              if (_caption.isNotEmpty)
                Text(_caption, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4)),
              const Spacer(),
              GestureDetector(
                onTap: _end,
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AnchorColors.alert,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: const Text('END', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
