import 'package:flutter/material.dart';
import '../theme/anchor_theme.dart';
import '../api/anchor_api.dart';
import '../widgets/anchor_chrome.dart';

/// Standing — the end-of-week review. What you kept, what slipped, and a
/// message that forgives the miss instead of shaming it (spec §8, self-forgiveness).
class StandingScreen extends StatelessWidget {
  const StandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = AnchorApi();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: FutureBuilder<WeeklyStanding>(
        future: api.standing(),
        builder: (context, snap) {
          final s = snap.data;
          if (s == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AnchorHeader(trailing: AnchorBadge('WK37 / FRI')),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AnchorBox.surface(bg: AnchorColors.energy),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${s.keptCount}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 48, height: 0.9)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Text('of ${s.totalCount} kept',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              for (final item in s.items) ...[
                _StandingTile(item),
                const SizedBox(height: 9),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: AnchorBox.surface(bg: AnchorColors.card),
                child: Text(s.anchorMessage,
                    style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StandingTile extends StatelessWidget {
  const _StandingTile(this.item);
  final StandingItem item;

  Color get _mark {
    switch (item.outcome) {
      case 'kept':
        return AnchorColors.ok;
      case 'missed':
        return AnchorColors.alert;
      default:
        return AnchorColors.dim;
    }
  }

  IconData get _icon => item.outcome == 'kept' ? Icons.check : Icons.remove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: AnchorBox.surface(),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _mark,
              border: Border.all(color: AnchorColors.ink, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(_icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                if (item.note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(item.note!.toUpperCase(),
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
