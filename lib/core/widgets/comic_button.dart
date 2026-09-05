import 'package:flutter/material.dart';

import '../services/sound_bridge.dart';
import '../theme/app_theme.dart';

/// A chunky comic-style button that "presses" down when tapped.
class ComicButton extends StatefulWidget {
  const ComicButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppTheme.primary,
    this.textColor = Colors.white,
    this.icon,
    this.fontSize = 22,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final double fontSize;
  final bool expand;

  @override
  State<ComicButton> createState() => _ComicButtonState();
}

class _ComicButtonState extends State<ComicButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_enabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final offset = _pressed ? 1.0 : 5.0;
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _enabled
          ? () {
              SoundBridge.click();
              widget.onPressed!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        transform: Matrix4.translationValues(
          _pressed ? 4 : 0,
          _pressed ? 4 : 0,
          0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        width: widget.expand ? double.infinity : null,
        decoration: BoxDecoration(
          color: _enabled ? widget.color : Colors.grey.shade400,
          border: AppTheme.comicBorder,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.comicShadow(offset: offset),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: widget.textColor, size: widget.fontSize + 4),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
