import 'package:flutter/material.dart';
import '../theme/anchor_theme.dart';
import 'connect_screen.dart';
import 'import_screen.dart';

/// Settings — where you set Anchor up to know you: import your history and
/// connect Google. This screen is the flow home; each row pushes the real
/// screen (07 Import, 08 Connect).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  const Text('PROFILE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3)),
                  GestureDetector(onTap: () => Navigator.of(context).maybePop(), child: const Icon(Icons.close, color: AnchorColors.ink)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AnchorBox.surface(),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: AnchorBox.surface(bg: AnchorColors.energy, radius: 26, shadow: 2),
                      child: const Text('B', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bharat', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                        SizedBox(height: 3),
                        Text('Holding four this week', style: TextStyle(fontSize: 13, color: AnchorColors.dim)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('SET ANCHOR UP',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800, color: AnchorColors.dim, letterSpacing: 1)),
              const SizedBox(height: 12),
              _SetupRow(
                title: 'Import your history',
                subtitle: 'Bring a ChatGPT or Claude export so Anchor knows your patterns from day one.',
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const ImportScreen())),
              ),
              const SizedBox(height: 12),
              _SetupRow(
                title: 'Connect Google',
                subtitle: 'Calendar + Gmail, read-only. Powers your real load and the nudges.',
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const ConnectScreen())),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: AnchorBox.surface(bg: AnchorColors.scr, shadow: 0),
                child: const Text(
                  'Read-only and private. Anchor never sends, posts, or deletes anything on your behalf.',
                  style: TextStyle(fontSize: 12, color: AnchorColors.dim, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupRow extends StatelessWidget {
  const _SetupRow({required this.title, required this.subtitle, required this.onTap});
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AnchorBox.surface(),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: AnchorBox.surface(bg: AnchorColors.scr, radius: 5, shadow: 0),
                        child: const Text('NOT CONNECTED',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 8, fontWeight: FontWeight.w800, color: AnchorColors.dim)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AnchorColors.dim, height: 1.3)),
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
