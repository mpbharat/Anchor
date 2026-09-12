import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

class _ConnectScreenState extends State<ConnectScreen> with WidgetsBindingObserver {
  /// Providers whose "connect" is a real Google OAuth grant rather than a
  /// stored flag. Both live on one consent screen, so either card starts it.
  static const _googleProviders = {'google_calendar', 'gmail'};

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
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Consent happens in the browser, so the grant lands while this screen is
  /// backgrounded. Re-read on the way back rather than leaving a stale card.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingGoogle) {
      _awaitingGoogle = false;
      _load();
    }
  }

  bool _awaitingGoogle = false;

  Future<void> _load() async {
    final s = await AnchorApi.instance.integrations();
    if (mounted) setState(() => _status = s);
  }

  bool _isConnected(String id) => _status[id] == 'connected';

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggle(String id) async {
    if (_pending.contains(id)) return;
    final next = !_isConnected(id);
    setState(() => _pending.add(id));
    try {
      // Connecting Google means a real read-only grant, so hand off to the
      // consent screen. Disconnecting is just a status flip.
      if (next && _googleProviders.contains(id)) {
        await _startGoogleOAuth();
        return;
      }
      final ok = await AnchorApi.instance.setIntegration(id, connected: next);
      if (!mounted) return;
      if (ok) {
        setState(() => _status[id] = next ? 'connected' : 'revoked');
      } else {
        _say("Couldn't reach Anchor. Try again.");
      }
    } catch (_) {
      // Without this the provider stays stuck in _pending and every later tap
      // returns early, so the button would look dead with nothing explaining it.
      _say("Couldn't reach Anchor. Try again.");
    } finally {
      if (mounted) setState(() => _pending.remove(id));
    }
  }

  Future<void> _startGoogleOAuth() async {
    final url = await AnchorApi.instance.googleAuthUrl();
    if (!mounted) return;
    if (url == null) {
      _say('Google sign-in is not configured yet.');
      return;
    }
    // Google refuses OAuth inside an embedded webview, so this must open the
    // real browser.
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    if (launched) {
      _awaitingGoogle = true;
    } else {
      _say("Couldn't open the browser.");
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
              AnchorHeader(
                leading: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Icon(Icons.arrow_back, color: AnchorColors.ink),
                ),
                trailing: const AnchorBadge('OPTIONAL'),
              ),
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
