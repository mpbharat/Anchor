import 'package:flutter/material.dart';
import '../theme/anchor_theme.dart';
import '../api/anchor_api.dart';
import '../services/voice_service.dart';
import 'declined_screen.dart';

/// Capture a commitment (type or voice), run it past Anchor. Allowed -> it goes
/// on the record. Declined/swapped -> the "no" (Declined screen).
Future<void> showCommitSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CommitSheet(),
  );
}

class _CommitSheet extends StatefulWidget {
  const _CommitSheet();
  @override
  State<_CommitSheet> createState() => _CommitSheetState();
}

class _CommitSheetState extends State<_CommitSheet> {
  final _api = AnchorApi();
  final _voice = VoiceService.instance;
  final _title = TextEditingController();
  bool _listening = false;
  bool _asking = false;

  Future<void> _toggleMic() async {
    if (_listening) {
      await _voice.stop();
      setState(() => _listening = false);
      return;
    }
    final ok = await _voice.listen(
      onPartial: (t) => setState(() => _title.text = t),
      onFinal: (_) => setState(() => _listening = false),
    );
    setState(() => _listening = ok);
  }

  Future<void> _ask() async {
    final text = _title.text.trim();
    if (text.isEmpty || _asking) return;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _asking = true);
    final j = await _api.judge(text);
    if (!mounted) return;
    if (j.verdict == 'allowed') {
      await _api.addCommitment(text);
      nav.pop();
      messenger.showSnackBar(SnackBar(content: Text(j.spoken.isEmpty ? 'On the record.' : j.spoken)));
    } else {
      nav.pop();
      nav.push(MaterialPageRoute(builder: (_) => DeclinedScreen(judgment: j)));
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        padding: const EdgeInsets.all(18),
        decoration: AnchorBox.surface(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('WHAT ARE YOU TAKING ON?',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800, color: AnchorColors.dim)),
                GestureDetector(onTap: () => Navigator.of(context).maybePop(), child: const Icon(Icons.close, size: 20, color: AnchorColors.ink)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: _toggleMic,
                  child: Container(
                    width: 48, height: 48, alignment: Alignment.center,
                    decoration: AnchorBox.surface(bg: _listening ? AnchorColors.alert : AnchorColors.card, radius: 10, shadow: 3),
                    child: Icon(_listening ? Icons.stop : Icons.mic, color: _listening ? Colors.white : AnchorColors.ink),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    decoration: AnchorBox.surface(radius: 10, shadow: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _title,
                      autofocus: true,
                      minLines: 1, maxLines: 2,
                      decoration: InputDecoration(
                        hintText: _listening ? 'Listening…' : 'e.g. Write the launch newsletter',
                        border: InputBorder.none, isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _ask,
              child: Container(
                height: 52, alignment: Alignment.center,
                decoration: AnchorBox.surface(bg: AnchorColors.accent),
                child: _asking
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('ASK ANCHOR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
