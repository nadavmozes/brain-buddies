import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Formats a duration as m:ss, or 0:ss when under a minute. Purely numeric so
/// it is language-neutral (no Latin "s" suffix to leak in Hebrew/RTL).
String formatSeconds(int seconds) {
  final m = seconds ~/ 60;
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// A small comic-style pill showing an elapsed timer with a stopwatch icon.
class TimerChip extends StatelessWidget {
  const TimerChip({super.key, required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.ink, width: 2.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: AppTheme.ink),
          const SizedBox(width: 4),
          Text(formatSeconds(seconds),
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
