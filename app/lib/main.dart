import 'package:flutter/material.dart';
import 'theme/anchor_theme.dart';
import 'api/anchor_api.dart';

void main() => runApp(const AnchorApp());

class AnchorApp extends StatelessWidget {
  const AnchorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anchor',
      debugShowCheckedModeBanner: false,
      theme: anchorTheme(),
      home: const LoadScreen(),
    );
  }
}

/// The Load (home) — static scaffolding today; wired to real data on event day.
class LoadScreen extends StatelessWidget {
  const LoadScreen({super.key});

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ANCHOR',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: AnchorBox.surface(bg: AnchorColors.energy, radius: 6, shadow: 2),
                    child: const Text('WK37 / MON',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // capacity gauge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: AnchorBox.surface(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('RATED CAPACITY · LOADED 03 / 04',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 9),
                    Row(
                      children: List.generate(4, (i) {
                        final on = i < 3;
                        return Expanded(
                          child: Container(
                            height: 18,
                            margin: EdgeInsets.only(right: i < 3 ? 5 : 0),
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
              ),
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
        ),
      ),
      // persistent "Talk to Anchor" — always one tap away
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AnchorColors.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AnchorColors.ink, width: 2.5),
        ),
        child: const Icon(Icons.mic, color: Colors.white),
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
