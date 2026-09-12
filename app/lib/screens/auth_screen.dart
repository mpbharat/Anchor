import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api/anchor_api.dart';
import '../theme/anchor_theme.dart';

/// Shared throwaway account so anyone picking Anchor up can get straight in.
/// Deliberately shown on the sign-in screen: it holds seeded demo data only,
/// and nothing real is behind it. Drop this block for a production build.
const String kDemoEmail = 'demo@anchor.app';
const String kDemoPassword = 'anchor-demo-2026';

/// Sign in / create account. The front door before anything else loads.
///
/// Everything Anchor holds is per-person: the week's commitments, the patterns
/// it learned, the Google grant. So identity is established here first, and no
/// screen behind it has to wonder who it is talking to.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _creating = false;
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validate() {
    final email = _email.text.trim();
    if (!email.contains('@') || email.length < 4) return 'Enter a valid email.';
    // Supabase's own default minimum, checked here so the round trip is not
    // needed to say something this obvious.
    if (_password.text.length < 6) return 'Password needs at least 6 characters.';
    return null;
  }

  void _useDemoAccount() {
    setState(() {
      _email.text = kDemoEmail;
      _password.text = kDemoPassword;
      _error = null;
      _notice = null;
    });
    _submit();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final invalid = _validate();
    if (invalid != null) {
      setState(() {
        _error = invalid;
        _notice = null;
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      final api = AnchorApi.instance;
      if (_creating) {
        final res = await api.signUp(email: _email.text, password: _password.text);
        // With email confirmation switched on, sign-up returns a user but no
        // session. Say so rather than leaving them on a screen that looks stuck.
        if (res.session == null && mounted) {
          setState(() {
            _creating = false;
            _notice = 'Account created. Check your email to confirm, then sign in.';
          });
        }
      } else {
        await api.signIn(email: _email.text, password: _password.text);
      }
      // On success the auth gate in main.dart swaps this screen out; there is
      // nothing to navigate to from here.
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't reach Anchor. Check your connection.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('ANCHOR',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 30, letterSpacing: 5)),
                const SizedBox(height: 10),
                const Text(
                  'THE COMMITMENT AGENT THAT SAYS NO',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AnchorColors.dim,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 34),
                _Field(
                  controller: _email,
                  hint: 'you@example.com',
                  label: 'EMAIL',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _password,
                  hint: '••••••••',
                  label: 'PASSWORD',
                  obscure: true,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  _Banner(text: _error!, color: AnchorColors.alert),
                ],
                if (_notice != null) ...[
                  const SizedBox(height: 14),
                  _Banner(text: _notice!, color: AnchorColors.ok),
                ],
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: _busy ? null : _submit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    decoration: AnchorBox.surface(
                      bg: _busy ? AnchorColors.dim : AnchorColors.accent,
                      radius: 12,
                    ),
                    alignment: Alignment.center,
                    child: _busy
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_creating ? 'CREATE ACCOUNT' : 'SIGN IN',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: _busy
                      ? null
                      : () => setState(() {
                            _creating = !_creating;
                            _error = null;
                            _notice = null;
                          }),
                  child: Text(
                    _creating ? 'Have an account? Sign in' : 'New here? Create an account',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AnchorColors.accent),
                  ),
                ),
                // Only on the sign-in side: offering a canned account while
                // someone is deliberately creating their own would be noise.
                if (!_creating) ...[
                  const SizedBox(height: 28),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _busy ? null : _useDemoAccount,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: AnchorBox.surface(bg: AnchorColors.scr, radius: 10, shadow: 3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('DEMO ACCOUNT',
                                  style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AnchorColors.dim,
                                      letterSpacing: 1)),
                              Text('TAP TO SIGN IN',
                                  style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: _busy ? AnchorColors.dim : AnchorColors.accent,
                                      letterSpacing: 0.5)),
                            ],
                          ),
                          const SizedBox(height: 9),
                          const Text(kDemoEmail,
                              style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          const Text(kDemoPassword,
                              style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          const Text(
                            'Seeded data, shared by everyone trying Anchor.',
                            style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: AnchorColors.dim),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AnchorColors.dim,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Container(
          decoration: AnchorBox.surface(radius: 10, shadow: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            autofillHints: autofillHints,
            onSubmitted: onSubmitted,
            textInputAction: obscure ? TextInputAction.done : TextInputAction.next,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(color: AnchorColors.dim, fontWeight: FontWeight.w500),
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AnchorBox.surface(bg: color, radius: 10, shadow: 3),
      child: Text(
        text,
        style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            height: 1.5,
            fontWeight: FontWeight.w700,
            color: Colors.white),
      ),
    );
  }
}
