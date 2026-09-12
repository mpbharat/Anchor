import 'package:flutter/material.dart';
import '../theme/anchor_theme.dart';
import '../api/anchor_api.dart';
import '../widgets/anchor_chrome.dart';
import 'commitment_detail_screen.dart';
import 'commit_sheet.dart';

/// Focus — the few things you're holding this week. Tap one for its detail,
/// progress, and to check in or drop it. (Renamed from "Load".)
class LoadScreen extends StatefulWidget {
  const LoadScreen({super.key});
  @override
  State<LoadScreen> createState() => _LoadScreenState();
}

class _LoadScreenState extends State<LoadScreen> {
  final _api = AnchorApi();
  late Future<List<Commitment>> _commitments;
  late Future<Load> _load;
  String? _expanded;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _load = _api.currentLoad();
      _commitments = _api.currentCommitments();
    });
  }

  Future<void> _openCommit() async {
    await showCommitSheet(context);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnchorHeader(
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AnchorBadge('WK37 / FRI'),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _openCommit,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: AnchorBox.surface(bg: AnchorColors.accent, radius: 20, shadow: 3),
                    child: const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FutureBuilder<Load>(
            future: _load,
            builder: (context, snap) {
              final l = snap.data;
              return _FocusGauge(kept: l?.loaded ?? 0, cap: l?.cap ?? 4);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Commitment>>(
              future: _commitments,
              builder: (context, snap) {
                final items = snap.data ?? const [];
                if (snap.connectionState == ConnectionState.done && items.isEmpty) {
                  return const Center(
                    child: Text('Nothing on record yet.\nTalk to Anchor to commit.',
                        textAlign: TextAlign.center, style: TextStyle(color: AnchorColors.dim)),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 9),
                  itemBuilder: (_, i) {
                    final c = items[i];
                    return _PlateTile(
                      c,
                      expanded: _expanded == c.id,
                      onTap: () => setState(() => _expanded = _expanded == c.id ? null : c.id),
                      onProgress: (delta) async {
                        await _api.checkin(c.id, kind: 'progress', value: delta.toDouble());
                        _refresh();
                      },
                      onDone: () async {
                        await _api.checkin(c.id, kind: 'done');
                        _refresh();
                      },
                      onOpen: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CommitmentDetailScreen(id: c.id)),
                        );
                        _refresh();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusGauge extends StatelessWidget {
  const _FocusGauge({required this.kept, required this.cap});
  final int kept;
  final int cap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AnchorBox.surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('FOCUS · ${kept.toString().padLeft(2, '0')} OF ${cap.toString().padLeft(2, '0')}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 9),
          Row(
            children: List.generate(cap, (i) {
              final on = i < kept;
              return Expanded(
                child: Container(
                  height: 18,
                  margin: EdgeInsets.only(right: i < cap - 1 ? 5 : 0),
                  decoration: BoxDecoration(
                    color: on ? AnchorColors.energy : AnchorColors.card,
                    border: Border.all(color: AnchorColors.ink, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PlateTile extends StatelessWidget {
  const _PlateTile(this.c, {
    required this.expanded,
    required this.onTap,
    required this.onOpen,
    required this.onProgress,
    required this.onDone,
  });
  final Commitment c;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onOpen;
  final void Function(int delta) onProgress;
  final VoidCallback onDone;

  String get _statusLabel {
    if (c.isDone) return 'DONE';
    if (c.status == 'due') return 'DUE';
    if (c.status == 'carried') return 'CARRIED';
    return 'ON RECORD';
  }

  String get _cadence {
    if (c.period == 'week') return 'this week';
    if (c.period == 'month') return 'this month';
    if (c.kind == 'oneoff') return 'one-off';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AnchorBox.surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    color: c.isDone ? AnchorColors.ok : AnchorColors.ink,
                    child: Text(
                      c.isDone ? '✓' : c.position.toString().padLeft(2, '0'),
                      style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        if (c.progress != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(c.progress!.toUpperCase(),
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: AnchorColors.dim)),
                          ),
                      ],
                    ),
                  ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more, color: AnchorColors.dim),
                ],
              ),
            ),
          ),
          if (expanded)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AnchorColors.ink, width: 2)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: AnchorBox.surface(
                            bg: c.isDone ? AnchorColors.ok : (c.status == 'due' ? AnchorColors.energy : AnchorColors.accent),
                            radius: 6,
                            shadow: 0),
                        child: Text(_statusLabel,
                            style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: c.isDone || c.status == 'due' ? AnchorColors.ink : Colors.white)),
                      ),
                      if (_cadence.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(_cadence.toUpperCase(),
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.w700, color: AnchorColors.dim)),
                      ],
                    ],
                  ),
                  if (c.metric == 'count' && c.targetValue > 0) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(border: Border.all(color: AnchorColors.ink, width: 2), borderRadius: BorderRadius.circular(4)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (c.currentValue / c.targetValue).clamp(0, 1),
                          child: Container(color: AnchorColors.energy),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${c.currentValue.toInt()} of ${c.targetValue.toInt()} · ${((c.currentValue / c.targetValue) * 100).round()}%',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: AnchorColors.dim)),
                  ],
                  const SizedBox(height: 12),
                  if (!c.isDone)
                    Row(
                      children: [
                        if (c.metric == 'count') ...[
                          Expanded(child: _MiniBtn('– 1', bg: AnchorColors.card, fg: AnchorColors.ink, onTap: c.currentValue <= 0 ? null : () => onProgress(-1))),
                          const SizedBox(width: 8),
                          Expanded(child: _MiniBtn('+ 1', bg: AnchorColors.energy, fg: AnchorColors.ink, onTap: () => onProgress(1))),
                          const SizedBox(width: 8),
                        ],
                        Expanded(child: _MiniBtn('✓ DONE', bg: AnchorColors.ok, fg: Colors.white, onTap: onDone)),
                      ],
                    ),
                  const SizedBox(height: 10),
                  Center(
                    child: GestureDetector(
                      onTap: onOpen,
                      child: const Text('View details and log',
                          style: TextStyle(color: AnchorColors.accent, fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn(this.label, {required this.bg, required this.fg, required this.onTap});
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: AnchorBox.surface(bg: bg, shadow: 3),
          child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 13)),
        ),
      ),
    );
  }
}
