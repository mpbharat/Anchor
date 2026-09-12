import 'package:flutter/material.dart';
import '../api/anchor_api.dart';
import '../theme/anchor_theme.dart';
import 'connect_screen.dart';
import 'import_screen.dart';

/// Settings — where you set Anchor up to know you: import your history and
/// connect Google. This screen is the flow home; each row pushes the real
/// screen (07 Import, 08 Connect).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// The signed-in account, shown so it is always obvious whose week this is
  /// and which account a Google grant would attach to.
  static String _name(String? email) {
    if (email == null || email.isEmpty) return 'Anchor';
    final local = email.split('@').first;
    if (local.isEmpty) return 'Anchor';
    return local[0].toUpperCase() + local.substring(1);
  }

  static String _initial(String? email) {
    final n = _name(email);
    return n.isEmpty ? 'A' : n[0].toUpperCase();
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AnchorColors.card,
        title: const Text('Sign out?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
          'Your commitments stay on your account. You can sign back in any time.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CANCEL', style: TextStyle(color: AnchorColors.dim)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('SIGN OUT', style: TextStyle(color: AnchorColors.alert)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AnchorApi.instance.signOut();
    // The auth gate in main.dart swaps in the sign-in screen, so this route
    // has to come off the stack or it would sit on top of it.
    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final email = AnchorApi.instance.currentEmail;
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
                      child: Text(_initial(email),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_name(email),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                          const SizedBox(height: 3),
                          Text(email ?? 'Not signed in',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: AnchorColors.dim)),
                        ],
                      ),
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
              const SizedBox(height: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _signOut(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: AnchorBox.surface(radius: 10, shadow: 3),
                  alignment: Alignment.center,
                  child: const Text('SIGN OUT',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AnchorColors.alert,
                          letterSpacing: 1)),
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
