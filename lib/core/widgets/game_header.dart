import 'package:flutter/material.dart';

import 'timer_chip.dart';

/// The shared game-screen header: a title, the live [TimerChip], a progress
/// count label, and a rounded [LinearProgressIndicator] below.
///
/// Callers pass their own [title] text, [countLabel] (e.g. '3 / 10' or a
/// matched-pairs label), the [seconds] elapsed, the [progress] fraction, and
/// the [progressColor] for the bar.
class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.title,
    required this.countLabel,
    required this.seconds,
    required this.progress,
    required this.progressColor,
  });

  final String title;
  final String countLabel;
  final int seconds;
  final double progress;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            const Spacer(),
            TimerChip(seconds: seconds),
            const SizedBox(width: 10),
            Text(countLabel,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.white,
            color: progressColor,
          ),
        ),
      ],
    );
  }
}
