import 'package:flutter/material.dart';
import '../theme/anchor_theme.dart';
import '../api/anchor_api.dart';
import '../services/voice_service.dart';
import '../widgets/anchor_chrome.dart';
import 'commit_sheet.dart';

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
  final _voice = VoiceService.instance;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<Turn> _turns = [];
  bool _listening = false;
  bool _sending = false;
  String _loadLabel = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final history = await _api.conversation();
    final load = await _api.currentLoad();
    if (!mounted) return;
    setState(() {
      _turns
        ..clear()
        ..addAll(history);
      if (_turns.isEmpty) {
        _turns.add(const Turn(
          role: 'anchor',
          text: "I'm Anchor. I help you hold to a few things and say no to the rest. What are you taking on this week?",
        ));
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
    if (reply.isNotEmpty) _voice.speak(reply);
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _voice.stop();
      setState(() => _listening = false);
      return;
    }
    final ok = await _voice.listen(
      onPartial: (t) => setState(() => _input.text = t),
      onFinal: (t) {
        setState(() => _listening = false);
        if (t.trim().isNotEmpty) _send(t);
      },
    );
    setState(() => _listening = ok);
  }

  Future<void> _openCommit() async {
    await showCommitSheet(context);
    _bootstrap(); // refresh load label after a commitment lands
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
          AnchorHeader(trailing: _loadLabel.isEmpty ? null : AnchorBadge(_loadLabel)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: _openCommit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: AnchorBox.surface(bg: AnchorColors.accent, radius: 8, shadow: 3),
                child: const Text('+ COMMIT TO SOMETHING',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
            listening: _listening,
            sending: _sending,
            onMic: _toggleMic,
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
    required this.listening,
    required this.sending,
    required this.onMic,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool listening;
  final bool sending;
  final VoidCallback onMic;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onMic,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: AnchorBox.surface(bg: listening ? AnchorColors.alert : AnchorColors.card, radius: 24, shadow: 3),
            child: Icon(listening ? Icons.stop : Icons.mic, color: listening ? Colors.white : AnchorColors.ink),
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
              decoration: InputDecoration(
                hintText: listening ? 'Listening…' : 'Talk to Anchor',
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
