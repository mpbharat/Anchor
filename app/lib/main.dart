import 'package:flutter/material.dart';
import 'theme/anchor_theme.dart';
import 'screens/talk_screen.dart';
import 'screens/load_screen.dart';
import 'screens/standing_screen.dart';

void main() => runApp(const AnchorApp());

class AnchorApp extends StatelessWidget {
  const AnchorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anchor',
      debugShowCheckedModeBanner: false,
      theme: anchorTheme(),
      home: const HomeShell(),
    );
  }
}

/// Talk is the front door. Load and Standing are supporting views.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  static const _tabs = [TalkScreen(), LoadScreen(), StandingScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: _tabs)),
      bottomNavigationBar: _BottomNav(index: _index, onTap: (i) => setState(() => _index = i)),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.forum_rounded, 'TALK'),
    (Icons.checklist_rounded, 'FOCUS'),
    (Icons.insights_rounded, 'RECAP'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AnchorColors.card,
        border: Border(top: BorderSide(color: AnchorColors.ink, width: 2.5)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _NavItem(icon: _items[i].$1, label: _items[i].$2, selected: i == index, onTap: () => onTap(i)),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AnchorColors.ink;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: selected
            ? BoxDecoration(
                color: AnchorColors.accent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AnchorColors.ink, width: 2.5),
                boxShadow: const [BoxShadow(color: AnchorColors.ink, offset: Offset(3, 3), blurRadius: 0)],
              )
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 20),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
            ],
          ],
        ),
      ),
    );
  }
}
