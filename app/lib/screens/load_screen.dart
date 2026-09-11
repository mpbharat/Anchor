import 'package:flutter/material.dart';
import '../theme/anchor_theme.dart';
import '../api/anchor_api.dart';
import '../widgets/anchor_chrome.dart';

/// The Load (home) — what you're carrying this week against your rated capacity.
/// Static scaffolding today; wired to real data on event day.
class LoadScreen extends StatelessWidget {
  const LoadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = AnchorApi();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AnchorHeader(trailing: AnchorBadge('WK37 / MON')),
          const SizedBox(height: 14),
          const _CapacityGauge(loaded: 3, rated: 4),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Commitment>>(
              future: api.currentCommitments(),
              builder: (context, snap) {
                final items = snap.data ?? const [];
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 9),
                  itemBuilder: (_, i) => _PlateTile(items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CapacityGauge extends StatelessWidget {
  const _CapacityGauge({required this.loaded, required this.rated});
  final int loaded;
  final int rated;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AnchorBox.surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('RATED CAPACITY · LOADED ${loaded.toString().padLeft(2, '0')} / ${rated.toString().padLeft(2, '0')}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 9),
          Row(
            children: List.generate(rated, (i) {
              final on = i < loaded;
              return Expanded(
                child: Container(
                  height: 18,
                  margin: EdgeInsets.only(right: i < rated - 1 ? 5 : 0),
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
  const _PlateTile(this.c);
  final Commitment c;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: AnchorBox.surface(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            color: AnchorColors.ink,
            child: Text(c.position.toString().padLeft(2, '0'),
                style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10)),
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
        ],
      ),
    );
  }
}
