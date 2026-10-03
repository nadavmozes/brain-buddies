import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/clock_time.dart';
import 'clock_face.dart';

/// An interactive clock the child adjusts with +/- steppers to match a target
/// time. Tap-based (not free-drag) so it's easy for small hands, and the live
/// clock face updates as they change the hour/minute.
class ClockSetter extends StatelessWidget {
  const ClockSetter({
    super.key,
    required this.value,
    required this.minuteStep,
    required this.enabled,
    required this.onChanged,
  });

  final ClockTime value;

  /// The minute increment, derived from the world (e.g. 30, 15, or 5).
  final int minuteStep;
  final bool enabled;
  final ValueChanged<ClockTime> onChanged;

  void _changeHour(int delta) {
    var h = value.hour + delta;
    if (h > 12) h = 1;
    if (h < 1) h = 12;
    onChanged(ClockTime(h, value.minute));
  }

  void _changeMinute(int delta) {
    final step = minuteStep <= 0 ? 5 : minuteStep;
    var m = value.minute + delta * step;
    m %= 60;
    if (m < 0) m += 60;
    onChanged(ClockTime(value.hour, m));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClockFace(time: value, size: 170),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepGroup(
              label: 'Hour',
              onMinus: enabled ? () => _changeHour(-1) : null,
              onPlus: enabled ? () => _changeHour(1) : null,
            ),
            const SizedBox(width: 20),
            _StepGroup(
              label: 'Minute',
              onMinus: enabled ? () => _changeMinute(-1) : null,
              onPlus: enabled ? () => _changeMinute(1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _StepGroup extends StatelessWidget {
  const _StepGroup({
    required this.label,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Row(
          children: [
            _StepButton(icon: Icons.remove_rounded, onTap: onMinus),
            const SizedBox(width: 8),
            _StepButton(icon: Icons.add_rounded, onTap: onPlus),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? AppTheme.primary : Colors.grey.shade400,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.ink, width: 3),
          boxShadow: AppTheme.comicShadow(offset: on ? 3 : 1),
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}
