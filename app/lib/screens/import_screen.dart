import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/anchor_api.dart';
import '../theme/anchor_theme.dart';
import '../widgets/anchor_chrome.dart';

/// Screen 07 — Import (optional): teach Anchor about you.
///
/// Offered after the first commitments, never before. The person runs a prompt
/// in the AI they already use and pastes the reply back; the backend extracts it
/// into user_patterns. Staying fresh is always a choice.
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  /// The prompt the person runs in ChatGPT/Claude. Deliberately blunt — the
  /// briefing is for a coach who will say no to them.
  static const prompt =
      'Write a briefing about me for a new accountability coach. '
      'How I work, where I overcommit, my recurring pitfalls, what I\'m working '
      'on now and how loaded I am, what matters most right now. '
      'Be blunt. Return markdown.';

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _paste = TextEditingController();
  bool _busy = false;
  String? _error;
  ImportedProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadExisting();
    _paste.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _paste.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final p = await AnchorApi.instance.patterns();
    if (mounted && p != null && p.hasContent) setState(() => _profile = p);
  }

  Future<void> _copyPrompt() async {
    await Clipboard.setData(const ClipboardData(text: ImportScreen.prompt));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prompt copied — paste it into ChatGPT or Claude')),
    );
  }

  Future<void> _extract() async {
    final text = _paste.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final profile = await AnchorApi.instance.extractPatterns(source: 'chatgpt', rawText: text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (profile == null) {
        _error = "Couldn't read that. Paste the reply again, or stay fresh.";
      } else {
        _profile = profile;
        _paste.clear();
      }
    });
  }

  Future<void> _stayFresh() async {
    await AnchorApi.instance.clearPatterns();
    if (!mounted) return;
    setState(() => _profile = null);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AnchorHeader(trailing: AnchorBadge('OPTIONAL')),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _PromptCard(onCopy: _copyPrompt),
                    const SizedBox(height: 16),
                    _PasteBox(controller: _paste, enabled: !_busy),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!,
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AnchorColors.alert)),
                    ],
                    if (_paste.text.trim().isNotEmpty || _busy) ...[
                      const SizedBox(height: 14),
                      _ExtractButton(busy: _busy, onTap: _extract),
                    ],
                    const SizedBox(height: 22),
                    Text(_profile == null ? 'ANCHOR LEARNS' : 'ANCHOR LEARNED',
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AnchorColors.dim,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 10),
                    _LearnedChips(profile: _profile),
                  ],
                ),
              ),
              const Divider(color: AnchorColors.dim, height: 24, thickness: 1),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _stayFresh,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text('OR STAY FRESH — START WITH A BLANK SLATE',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AnchorColors.dim,
                          letterSpacing: 0.3)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dark card: what to run, and where to run it.
class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.onCopy});
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AnchorBox.surface(bg: AnchorColors.ink, radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: AnchorBox.surface(radius: 20, shadow: 0),
                  child: const Text('RUN THIS IN CHATGPT OR CLAUDE',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4)),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onCopy,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: AnchorBox.surface(bg: AnchorColors.energy, radius: 8, shadow: 0),
                  child: const Text('COPY',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('“${ImportScreen.prompt}”',
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: AnchorColors.scr)),
        ],
      ),
    );
  }
}

/// Dashed drop/paste target. Expands as the person pastes.
class _PasteBox extends StatelessWidget {
  const _PasteBox({required this.controller, required this.enabled});
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final empty = controller.text.isEmpty;
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Container(
        constraints: BoxConstraints(minHeight: empty ? 96 : 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        alignment: empty ? Alignment.center : Alignment.topLeft,
        child: TextField(
          controller: controller,
          enabled: enabled,
          maxLines: null,
          minLines: empty ? 2 : 5,
          textAlign: empty ? TextAlign.center : TextAlign.start,
          style: const TextStyle(fontSize: 13, height: 1.4, color: AnchorColors.ink),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            hintText: '↓ Paste the reply here\nor drop a .md / .json file',
            hintMaxLines: 2,
            hintStyle: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: AnchorColors.dim),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AnchorColors.dim
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dash = 7.0, gap = 5.0, r = 10.0;
    final rect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(r));
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, (d + dash).clamp(0, metric.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ExtractButton extends StatelessWidget {
  const _ExtractButton({required this.busy, required this.onTap});
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: AnchorBox.surface(bg: busy ? AnchorColors.dim : AnchorColors.accent, radius: 12),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Text('EXTRACT',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1)),
      ),
    );
  }
}

/// Before import: the categories Anchor will learn. After: what it actually found.
class _LearnedChips extends StatelessWidget {
  const _LearnedChips({required this.profile});
  final ImportedProfile? profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    if (p == null) {
      return const Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Chip('PERSONALITY'),
          _Chip('PITFALLS'),
          _Chip('PROJECTS'),
          _Chip('CURRENT LOAD'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (p.baselineLoad?.isNotEmpty ?? false) _Group('CURRENT LOAD', [p.baselineLoad!]),
        if (p.workingStyle?.isNotEmpty ?? false) _Group('WORKING STYLE', [p.workingStyle!]),
        if (p.pitfalls.isNotEmpty) _Group('PITFALLS', p.pitfalls),
        if (p.currentProjects.isNotEmpty) _Group('PROJECTS', p.currentProjects),
        if (p.priorities.isNotEmpty) _Group('PRIORITIES', p.priorities),
        if (p.habits.isNotEmpty) _Group('HABITS', p.habits),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.label, this.values);
  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AnchorColors.dim,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final v in values) _Chip(v)]),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: AnchorBox.surface(radius: 8, shadow: 2),
      child: Text(label,
          style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3)),
    );
  }
}
