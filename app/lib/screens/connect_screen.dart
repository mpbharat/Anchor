import 'package:flutter/material.dart';
import '../api/anchor_api.dart';
import '../theme/anchor_theme.dart';
import '../widgets/anchor_chrome.dart';

/// Screen 08 — Connect (optional): Gmail + Calendar, read-only, skippable.
///
/// The calendar makes the load real — Anchor weighs a new ask against what's
/// already booked. Read-only keeps trust intact, so that promise is stated
/// plainly on the screen and never quietly broken.
class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  static const _providers = [
    (
      id: 'google_calendar',
      icon: Icons.auto_awesome,
      title: 'Google Calendar',
      blurb: 'SEES YOUR REAL LOAD BEFORE IT SAYS YES',
    ),
    (
      id: 'gmail',
      icon: Icons.mail_outline_rounded,
      title: 'Gmail',
      blurb: 'SPOTS INCOMING ASKS YOU CAN DECLINE',
    ),
    (
      id: 'notifications',
      icon: Icons.contrast_rounded,
      title: 'Notifications',
      blurb: "KNOWS WHAT'S PULLING AT YOU",
    ),
  ];

  Map<String, String> _status = {};
  final Set<String> _pending = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await AnchorApi.instance.integrations();
    if (mounted) setState(() => _status = s);
  }

  bool _isConnected(String id) => _status[id] == 'connected';

  Future<void> _toggle(String id) async {
    if (_pending.contains(id)) return;
    final next = !_isConnected(id);
    setState(() => _pending.add(id));
    final ok = await AnchorApi.instance.setIntegration(id, connected: next);
    if (!mounted) return;
    setState(() {
      _pending.remove(id);
      if (ok) _status[id] = next ? 'connected' : 'revoked';
    });
    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Couldn't reach Anchor. Try again.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AnchorHeader(trailing: AnchorBadge('OPTIONAL')),
              const SizedBox(height: 18),
              const Text('CONNECT YOUR WORLD — OPTIONAL',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AnchorColors.dim,
                      letterSpacing: 0.5)),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final p in _providers) ...[
                      _ProviderCard(
                        icon: p.icon,
                        title: p.title,
                        blurb: p.blurb,
                        connected: _isConnected(p.id),
                        busy: _pending.contains(p.id),
                        onTap: () => _toggle(p.id),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 6),
                    const Text(
                      'Read-only. Anchor reads to understand your load — it never '
                      'sends, deletes, or posts anything.',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: AnchorColors.dim),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: AnchorBox.surface(bg: AnchorColors.accent, radius: 12),
                  alignment: Alignment.center,
                  child: const Text('DONE',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
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

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.icon,
    required this.title,
    required this.blurb,
    required this.connected,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String blurb;
  final bool connected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AnchorBox.surface(radius: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: AnchorBox.surface(radius: 10, shadow: 0),
            child: Icon(icon, size: 22, color: AnchorColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text(blurb,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                        color: AnchorColors.dim)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StateButton(connected: connected, busy: busy, onTap: onTap),
        ],
      ),
    );
  }
}

class _StateButton extends StatelessWidget {
  const _StateButton({required this.connected, required this.busy, required this.onTap});
  final bool connected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = connected ? AnchorColors.ok : AnchorColors.accent;
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: AnchorBox.surface(bg: busy ? AnchorColors.dim : bg, radius: 8, shadow: 3),
        child: busy
            ? const SizedBox(
                height: 12,
                width: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(connected ? 'CONNECTED' : 'CONNECT',
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5)),
      ),
    );
  }
}
