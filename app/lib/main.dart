import 'package:flutter/material.dart';
import 'theme/anchor_theme.dart';
import 'widgets/anchor_chrome.dart';
import 'screens/load_screen.dart';
import 'screens/commit_screen.dart';
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

/// The three primary tabs — Load / Commit / Standing — with the persistent
/// Talk-to-Anchor mic floating over all of them. Declined and Talk are pushed
/// on top when they fire.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [LoadScreen(), CommitScreen(), StandingScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: _tabs)),
      floatingActionButton: const TalkFab(),
      bottomNavigationBar: _BottomNav(
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.dashboard, 'LOAD'),
    (Icons.add_task, 'COMMIT'),
    (Icons.flag, 'STANDING'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AnchorColors.card,
        border: Border(top: BorderSide(color: AnchorColors.ink, width: 2.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < _items.length; i++)
              _NavItem(
                icon: _items[i].$1,
                label: _items[i].$2,
                selected: i == index,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AnchorColors.accent : AnchorColors.dim;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
