import 'package:flutter/material.dart';
import '../theme/anchor_theme.dart';
import '../api/anchor_api.dart';

/// One commitment's page: status, progress, cadence, check in, or drop it.
class CommitmentDetailScreen extends StatefulWidget {
  const CommitmentDetailScreen({super.key, required this.id});
  final String id;
  @override
  State<CommitmentDetailScreen> createState() => _CommitmentDetailScreenState();
}

class _CommitmentDetailScreenState extends State<CommitmentDetailScreen> {
  final _api = AnchorApi();
  Commitment? _c;
  bool _loading = true;
  bool _busy = false;
  bool _confirmDrop = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await _api.commitment(widget.id);
      if (mounted) setState(() { _c = c; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _do(Future<bool> Function() action) async {
    setState(() => _busy = true);
    await action();
    await _load();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _drop() async {
    setState(() => _busy = true);
    await _api.deleteCommitment(widget.id);
    if (mounted) Navigator.of(context).pop();
  }

  String get _statusLabel {
    final c = _c!;
    if (c.isDone) return 'DONE';
    switch (c.status) {
      case 'due':
        return 'DUE';
      case 'carried':
        return 'CARRIED';
      case 'dropped':
        return 'DROPPED';
      default:
        return 'ON RECORD';
    }
  }

  Color get _statusColor {
    final c = _c!;
    if (c.isDone) return AnchorColors.ok;
    if (c.status == 'due') return AnchorColors.energy;
    if (c.status == 'carried' || c.status == 'dropped') return AnchorColors.dim;
    return AnchorColors.accent;
  }

  String get _cadence {
    final c = _c!;
    if (c.period == 'week') return 'this week';
    if (c.period == 'month') return 'this month';
    if (c.kind == 'oneoff') return 'one-off';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : c == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Couldn't load this one.", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: AnchorBox.surface(bg: AnchorColors.ink),
                          child: const Text('GO BACK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ANCHOR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3)),
                        GestureDetector(onTap: () => Navigator.of(context).maybePop(), child: const Icon(Icons.close, color: AnchorColors.ink)),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: AnchorBox.surface(bg: _statusColor, radius: 6, shadow: 2),
                          child: Text(_statusLabel,
                              style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w900, color: c.isDone || c.status == 'due' ? AnchorColors.ink : Colors.white)),
                        ),
                        if (_cadence.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(_cadence.toUpperCase(),
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w700, color: AnchorColors.dim)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(c.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.2)),
                    const SizedBox(height: 20),
                    if (c.metric == 'count' && c.targetValue > 0) ...[
                      Text('PROGRESS · ${c.currentValue.toInt()} OF ${c.targetValue.toInt()} · ${((c.currentValue / c.targetValue) * 100).round()}%',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w700, color: AnchorColors.dim)),
                      const SizedBox(height: 8),
                      _ProgressBar(value: c.targetValue == 0 ? 0 : (c.currentValue / c.targetValue).clamp(0, 1)),
                      const SizedBox(height: 20),
                    ],
                    const Spacer(),
                    if (!c.isDone) ...[
                      if (c.metric == 'count') ...[
                        const Text('LOG PROGRESS',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w700, color: AnchorColors.dim)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                label: '– 1',
                                bg: AnchorColors.card,
                                fg: c.currentValue <= 0 ? AnchorColors.dim : AnchorColors.ink,
                                busy: _busy || c.currentValue <= 0,
                                onTap: () => _do(() => _api.checkin(c.id, kind: 'progress', value: -1)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ActionButton(
                                label: '+ 1',
                                bg: AnchorColors.energy,
                                fg: AnchorColors.ink,
                                busy: _busy,
                                onTap: () => _do(() => _api.checkin(c.id, kind: 'progress', value: 1)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      _ActionButton(
                        label: 'MARK DONE',
                        bg: AnchorColors.ok,
                        fg: Colors.white,
                        busy: _busy,
                        onTap: () => _do(() => _api.checkin(c.id, kind: 'done')),
                      ),
                      const SizedBox(height: 10),
                    ],
                    _ActionButton(
                      label: _confirmDrop ? 'CONFIRM DROP' : 'DROP THIS',
                      bg: _confirmDrop ? AnchorColors.alert : AnchorColors.scr,
                      fg: _confirmDrop ? Colors.white : AnchorColors.dim,
                      shadow: _confirmDrop ? 4 : 0,
                      busy: _busy,
                      onTap: () {
                        if (_confirmDrop) {
                          _drop();
                        } else {
                          setState(() => _confirmDrop = true);
                        }
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});
  final double value;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: AnchorColors.card,
        border: Border.all(color: AnchorColors.ink, width: 2.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value,
        child: Container(
          decoration: BoxDecoration(color: AnchorColors.energy, borderRadius: BorderRadius.circular(3)),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.busy = false,
    this.shadow = 5,
  });
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  final bool busy;
  final double shadow;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: AnchorBox.surface(bg: bg, shadow: shadow),
        child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }
}
