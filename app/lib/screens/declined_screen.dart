import 'package:flutter/material.dart';
import '../theme/anchor_theme.dart';
import '../api/anchor_api.dart';
import '../widgets/anchor_chrome.dart';

/// Declined — the hero shot. Anchor says no, reflects your request back,
/// and shows what it weighed against. Coral is used here and nowhere else.
/// The user can always override ("your call").
class DeclinedScreen extends StatelessWidget {
  const DeclinedScreen({super.key, required this.judgment});
  final Judgment judgment;

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: AnchorBox.surface(bg: AnchorColors.alert, radius: 6, shadow: 3),
                child: const Text('NOT THIS WEEK',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(height: 18),
              Text(
                judgment.spoken,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.35, color: AnchorColors.ink),
              ),
              const SizedBox(height: 22),
              const Text('WEIGHED AGAINST',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w700, color: AnchorColors.dim)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final w in judgment.weighedAgainst)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: AnchorBox.surface(bg: AnchorColors.card, radius: 6, shadow: 2),
                      child: Text(w, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  decoration: AnchorBox.surface(bg: AnchorColors.ink),
                  child: const Text('OKAY, NOT NOW',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  height: 46,
                  alignment: Alignment.center,
                  decoration: AnchorBox.surface(bg: AnchorColors.scr, shadow: 0),
                  child: const Text('Your call — add it anyway',
                      style: TextStyle(color: AnchorColors.dim, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
