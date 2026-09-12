import 'package:flutter/material.dart';
import '../theme/anchor_theme.dart';

/// Settings — where you set Anchor up to know you: import your history and
/// connect Google. The import + Google screens are owned by the integrations
/// build (Mary/Merlin); this screen is the flow home. When their screens land,
/// wire each row's onTap to push them (see TODO below).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _explain(BuildContext context, String title, String what) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: AnchorBox.surface(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 8),
              Text(what, style: const TextStyle(fontSize: 14, height: 1.4, color: AnchorColors.ink)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: AnchorBox.surface(bg: AnchorColors.ink),
                  // TODO(integrations): replace this with a push to the import /
                  // Google connect screen once Mary/Merlin's screens are merged.
                  child: const Text('CONNECT · COMING FROM THE INTEGRATIONS BUILD',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                  const Text('SETTINGS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3)),
                  GestureDetector(onTap: () => Navigator.of(context).maybePop(), child: const Icon(Icons.close, color: AnchorColors.ink)),
                ],
              ),
              const SizedBox(height: 22),
              const Text('SET ANCHOR UP',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800, color: AnchorColors.dim, letterSpacing: 1)),
              const SizedBox(height: 12),
              _SetupRow(
                title: 'Import your history',
                subtitle: 'Bring a ChatGPT or Claude export so Anchor knows your patterns from day one.',
                onTap: () => _explain(context, 'Import your history',
                    'Anchor reads a ChatGPT or Claude export and learns how you overcommit, what you prioritise, and your habits, so it can hold you from the first week.'),
              ),
              const SizedBox(height: 12),
              _SetupRow(
                title: 'Connect Google',
                subtitle: 'Calendar + Gmail, read-only. Powers your real load and the nudges.',
                onTap: () => _explain(context, 'Connect Google',
                    'Anchor reads your calendar and inbox (read-only, it never sends or deletes) to see your real load and fire the right nudges: a purchase over budget, a meeting on your deep-work morning.'),
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
