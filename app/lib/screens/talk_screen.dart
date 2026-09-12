import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../theme/anchor_theme.dart';
import '../api/anchor_api.dart';
import '../widgets/anchor_chrome.dart';
import 'voice_call_screen.dart';
import 'settings_screen.dart';

/// Talk — the home screen and front door. Anchor is a conversation first:
/// you talk to it (type or voice), it references your load, pushes back, and
/// commitments get made right here. Silent by default, always available.
class TalkScreen extends StatefulWidget {
  const TalkScreen({super.key});
  @override
  State<TalkScreen> createState() => _TalkScreenState();
}

class _TalkScreenState extends State<TalkScreen> {
  final _api = AnchorApi();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<Turn> _turns = [];
  bool _sending = false;
  String _loadLabel = '';
  int _sinceReflect = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Web is a shared public demo: start every page-load fresh (greeting only)
    // so visitors get a clean, consistent state and don't inherit each other's
    // chat. The native app keeps full conversation history.
    final history = kIsWeb ? <Turn>[] : await _api.conversation();
    final load = await _api.currentLoad();
    if (!mounted) return;
    setState(() {
      _turns
        ..clear()
        ..addAll(history);
      if (_turns.isEmpty) {
        // A short scripted opener so the screen is alive, not blank. Real turns
        // append after these; on the shared web demo it resets to this each load.
        _turns.addAll(const [
          Turn(role: 'anchor', text: "I'm Anchor. I help you hold to a few things and say no to the rest."),
          Turn(role: 'user', text: "How's my week looking?"),
          Turn(role: 'anchor', text: "You're at four: pricing revamp, three gym sessions, dining under 1,000 AED, and calling Dad. That's a full plate, so I'd guard it before you add anything."),
        ]);
      }
      _loadLabel = 'FOCUS ${load.loaded}/${load.cap}';
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send(String text) async {
    final msg = text.trim();
    if (msg.isEmpty || _sending) return;
    _input.clear();
    setState(() {
      _turns.add(Turn(role: 'user', text: msg));
      _sending = true;
    });
    _scrollDown();
    final reply = await _api.chat(msg);
    if (!mounted) return;
    setState(() {
      _turns.add(Turn(role: 'anchor', text: reply.isEmpty ? "…" : reply));
      _sending = false;
    });
    _scrollDown();
    // debounced reflection: learn from the conversation every few turns.
    // Skipped on web so the shared public demo's memory stays curated.
    if (!kIsWeb && ++_sinceReflect >= 5) {
      _sinceReflect = 0;
      _api.reflect();
    }
  }

  Future<void> _openCall() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VoiceCallScreen()));
    _bootstrap(); // refresh transcript + load after a voice session
  }

  void _openProfile() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnchorHeader(
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loadLabel.isNotEmpty) AnchorBadge(_loadLabel),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _openProfile,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: AnchorBox.surface(bg: AnchorColors.card, radius: 20, shadow: 3),
                    child: const Icon(Icons.person, color: AnchorColors.ink, size: 22),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              controller: _scroll,
              itemCount: _turns.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _Bubble(_turns[i]),
            ),
          ),
          const SizedBox(height: 10),
          _InputBar(
            controller: _input,
            sending: _sending,
            onVoice: _openCall,
            onSend: () => _send(_input.text),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.turn);
  final Turn turn;
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
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: isAnchor ? AnchorColors.ink : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onVoice,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onVoice;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onVoice,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: AnchorBox.surface(bg: AnchorColors.accent, radius: 24, shadow: 3),
            child: const Icon(Icons.graphic_eq, color: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            decoration: AnchorBox.surface(radius: 24, shadow: 3),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Talk to Anchor',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: sending ? null : onSend,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: AnchorBox.surface(bg: AnchorColors.accent, radius: 24, shadow: 3),
            child: sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.arrow_upward, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
