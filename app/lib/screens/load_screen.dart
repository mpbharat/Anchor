import 'package:flutter/material.dart';
import '../theme/anchor_theme.dart';
import '../api/anchor_api.dart';
import '../widgets/anchor_chrome.dart';
import 'commitment_detail_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AnchorHeader(trailing: AnchorBadge('WK37 / FRI')),
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
                  itemBuilder: (_, i) => _PlateTile(
                    items[i],
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CommitmentDetailScreen(id: items[i].id)),
                      );
                      _refresh();
                    },
                  ),
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
  const _PlateTile(this.c, {required this.onTap});
  final Commitment c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: AnchorBox.surface(),
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
            const Icon(Icons.chevron_right, color: AnchorColors.dim),
          ],
        ),
      ),
    );
  }
}
