import 'package:flutter/material.dart';
import '../theme/anchor_theme.dart';
import '../api/anchor_api.dart';
import '../widgets/anchor_chrome.dart';

/// Talk to Anchor — the always-on companion (coach / counsellor / friend who
/// keeps you accountable). Silent by default, but always available (spec §8.7).
/// Static transcript today; live voice on event day.
class TalkScreen extends StatelessWidget {
  const TalkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = AnchorApi();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnchorHeader(
                trailing: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Icon(Icons.close, color: AnchorColors.ink),
                ),
              ),
              const SizedBox(height: 6),
              const Text('TALK TO ANCHOR',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w700, color: AnchorColors.dim)),
              const SizedBox(height: 14),
              Expanded(
                child: FutureBuilder<List<Turn>>(
                  future: api.conversation(),
                  builder: (context, snap) {
                    final turns = snap.data ?? const [];
                    return ListView.separated(
                      itemCount: turns.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _Bubble(turns[i]),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              const _ListeningBar(),
            ],
          ),
        ),
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
        decoration: AnchorBox.surface(
          bg: isAnchor ? AnchorColors.card : AnchorColors.accent,
          shadow: 3,
        ),
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

class _ListeningBar extends StatelessWidget {
  const _ListeningBar();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AnchorBox.surface(bg: AnchorColors.ink),
      child: const Row(
        children: [
          Icon(Icons.mic, color: Colors.white, size: 20),
          SizedBox(width: 12),
          Text('Listening…',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          Spacer(),
          Text('TAP TO STOP',
              style: TextStyle(fontFamily: 'monospace', color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
