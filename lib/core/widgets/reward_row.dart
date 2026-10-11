import 'package:flutter/material.dart';

/// A single reward line on result screens: a [leading] widget (icon/emoji), a
/// [label], a flexible gap, and a bold [value] on the right.
class RewardRow extends StatelessWidget {
  const RewardRow({
    super.key,
    required this.leading,
    required this.label,
    required this.value,
  });

  final Widget leading;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        leading,
        const SizedBox(width: 10),
        Text(label,
            style:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const Spacer(),
        Text(value,
            style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
