import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'comic_button.dart';

/// The sound on/off toggle shared by the secondary game homes. Shows a
/// 'Sound: On'/'Sound: Off' [ComicButton] with the matching volume icon.
class SoundToggleButton extends StatelessWidget {
  const SoundToggleButton({
    super.key,
    required this.soundOn,
    required this.onToggle,
  });

  final bool soundOn;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return ComicButton(
      label: soundOn ? 'Sound: On' : 'Sound: Off',
      icon: soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
      color: Colors.white,
      textColor: AppTheme.ink,
      fontSize: 16,
      onPressed: onToggle,
    );
  }
}
