import 'package:flutter/material.dart';
import '../theme/anchor_theme.dart';
import '../api/anchor_api.dart';
import '../widgets/anchor_chrome.dart';
import 'declined_screen.dart';

/// Commit — put something on the record. Speak it or type it.
/// Every commitment captures a WOOP if-then. Trying to exceed the cap
/// routes to the "no" (Declined).
class CommitScreen extends StatelessWidget {
  const CommitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = AnchorApi();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AnchorHeader(trailing: AnchorBadge('1 SLOT LEFT', bg: AnchorColors.energy)),
          const SizedBox(height: 16),
          const Text('WHAT ARE YOU PUTTING ON THE RECORD?',
              style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w700, color: AnchorColors.dim)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AnchorBox.surface(),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Write the launch newsletter',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                SizedBox(height: 12),
                _WoopLine(label: 'IF', value: 'it hits Friday'),
                SizedBox(height: 6),
                _WoopLine(label: 'THEN', value: "I'll draft it Thursday morning"),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: AnchorBox.surface(bg: AnchorColors.scr, shadow: 0),
            child: const Text(
              "You're carrying 3 of 4 already. Anchor will weigh this against what's on your load before it goes on the record.",
              style: TextStyle(fontSize: 12, color: AnchorColors.dim, height: 1.35),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _MicHint(),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final j = await api.judge('Write the launch newsletter');
                    if (!context.mounted) return;
                    if (j.verdict == 'allowed') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(j.spoken.isEmpty ? 'On the record.' : j.spoken)),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => DeclinedScreen(judgment: j)),
                      );
                    }
                  },
                  child: Container(
                    height: 54,
                    alignment: Alignment.center,
                    decoration: AnchorBox.surface(bg: AnchorColors.accent),
                    child: const Text('ASK ANCHOR',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WoopLine extends StatelessWidget {
  const _WoopLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          color: AnchorColors.ink,
          child: Text(label,
              style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontWeight: FontWeight.w800, fontSize: 9)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, height: 1.3))),
      ],
    );
  }
}

class _MicHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: AnchorBox.surface(bg: AnchorColors.card),
      child: const Icon(Icons.mic, color: AnchorColors.ink),
    );
  }
}
