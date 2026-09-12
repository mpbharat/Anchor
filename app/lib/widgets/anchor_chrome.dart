import 'package:flutter/material.dart';
import '../theme/anchor_theme.dart';

/// Top wordmark row shared by every screen. Optional [leading] (e.g. a settings
/// gear) sits before the wordmark; optional [trailing] slot (e.g. a status badge).
class AnchorHeader extends StatelessWidget {
  const AnchorHeader({super.key, this.trailing, this.leading});
  final Widget? trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            const Text('ANCHOR',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3)),
          ],
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// A small monospace status badge (e.g. WK37 / MON).
class AnchorBadge extends StatelessWidget {
  const AnchorBadge(this.label, {super.key, this.bg = AnchorColors.energy});
  final String label;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: AnchorBox.surface(bg: bg, radius: 6, shadow: 2),
      child: Text(label,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}
